"""Work credits from MIA source pages and author archive listings.

A work hosted in an author's archive is not necessarily by that author. This
module reads only visible, page-level bylines (and a corroborated author meta
tag as a fallback). When the source does not present an explicit credit, the
result is None so the catalog stays honestly uncredited.

The extraction is deliberately structural. Portuguese work pages normally use
``<h1>title</h1><h2>author</h2>`` (or ``<h3>title</h3><h4>author</h4>`` for
chapters); English pages often place the byline before the title. Archive
navigation, a matching surname in a title, and the hosting archive are never
treated as authorship evidence.
"""
import json
import os
import re
import sys
import unicodedata
from html.parser import HTMLParser

# Bump whenever extraction rules change. Scans record this so results produced
# by an older extractor are never mistaken for current evidence.
EXTRACTOR_VERSION = 2

HEADING_TAGS = {"h1", "h2", "h3", "h4", "h5"}
AUTHOR_CLASSES = {"author", "byline", "writer", "autor", "autoria"}
TITLE_CLASSES = {"title", "titulo", "título"}
PART_CLASSES = {"titulo-capitulo", "title-chapter"}
BLOCK_TAGS = {"p", "div", "span", "strong", "b"}

ARTICLES = {"a", "an", "the", "o", "os", "as", "um", "uma", "uns", "umas"}
PART_WORDS = {
    "prefacio", "introducao", "apresentacao", "prologo", "advertencia",
    "posfacio", "epilogo", "apendice", "nota", "notas", "comentario",
    "carta", "resposta", "discurso", "entrevista", "testemunho",
}
PARTICLES = {
    "de", "da", "do", "das", "dos", "e", "y", "and", "&",
    "van", "von", "der", "den", "la", "le", "les", "del", "di", "du",
    "ten", "ter", "bin", "ibn", "al", "el", "of", "dos", "das",
}
BYLINE_PREFIX = re.compile(
    r"^(?:by|por|written by|texto de|text by|traduzido por|tradução de|traducao de)\s+",
    re.I,
)
# A byline can name a document type before the person ("Dissertação de ...").
# Strip only that explicit lead-in; the remaining text still has to look like
# a name. Generic placeholders are not credits.
CREDIT_DESCRIPTOR = re.compile(
    r"^(?:disserta(?:ção|cao)|tese|introdu(?:ção|cao)|pref(?:á|a)cio|"
    r"tradu(?:ção|cao)|organiza(?:ção|cao)|sele(?:ção|cao)|"
    r"apresenta(?:ção|cao)|posf(?:á|a)cio|advert(?:ê|e)ncia|nota|"
    r"coment(?:á|a)rio|entrevista|discurso|artigo|texto)\s+de\s+",
    re.I,
)
GENERIC_CREDITS = {
    "autor", "autora", "autores", "anonimo", "anonima", "desconhecido",
    "desconhecida", "redacao", "editor", "editora", "tradutor", "tradutora",
    "equipa", "equipe",
}
MONTHS = {
    "janeiro", "fevereiro", "marco", "abril", "maio", "junho", "julho",
    "agosto", "setembro", "outubro", "novembro", "dezembro",
    "january", "february", "march", "april", "may", "june", "july",
    "august", "september", "october", "november", "december",
    "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "sept",
    "oct", "nov", "dec",
}
NON_NAME_WORDS = {
    "indice", "sumario", "contents", "prefacio", "introducao", "apresentacao",
    "notas", "nota", "bibliografia", "cronologia", "posfacio", "index",
    "cover", "capa", "editorial", "introduction", "preface", "notes",
    "bibliography", "chronology", "afterword", "document", "documento",
    "testimony", "testemunho", "archive", "arquivo", "articles", "artigos",
    "works", "obras", "writings", "escritos", "textos", "collected",
    "selected", "selecao", "seleção", "antologia", "reader", "leituras",
}
# Words that identify a page title or section label. A byline is a person's
# name, so a heading containing one of these is not used as a credit.
TITLE_WORDS = {
    "biografia", "biography", "historia", "history", "revolucao", "revolution",
    "revolta", "revolt", "guerra", "war", "manifesto", "manifest", "ensaio",
    "essay", "artigo", "article", "livro", "book", "obra", "work", "texto",
    "text", "documento", "document", "resenha", "review", "revista", "journal",
    "jornal", "newspaper", "secao", "section", "parte", "part", "capitulo",
    "chapter", "library", "biblioteca", "browse", "search", "busca", "home",
    "inicio", "menu", "site", "website",
}


def folded(value):
    """Case- and accent-insensitive comparison key."""
    normalized = unicodedata.normalize("NFKD", value.casefold())
    return "".join(c for c in normalized if c.isalnum())


def clean_text(value):
    return re.sub(r"\s+", " ", value.replace("\xa0", " ")).strip()


class _CreditParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.order = 0
        self.headings = []       # (order, tag, text)
        self.blocks = []         # (order, kind, text)
        self.part_titles = []    # (order, text)
        self.meta = []           # (order, text)
        self.document_title = ""
        self._capture = None     # (kind, tag, order)
        self._buffer = []

    def _start(self, kind, tag):
        if self._capture is not None:
            return
        self._capture = (kind, tag, self.order)
        self.order += 1
        self._buffer = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        classes = set(attrs.get("class", "").lower().split())
        if tag in HEADING_TAGS:
            if classes & PART_CLASSES:
                self._start("part_title", tag)
            else:
                self._start("heading", tag)
        elif tag == "title" and not self.document_title:
            self._start("document_title", tag)
        elif tag == "meta" and attrs.get("name", "").lower() in (
            "author", "dc.creator", "dc.author", "dcterms.creator"
        ):
            value = clean_text(attrs.get("content", ""))
            if value:
                self.meta.append((self.order, value))
                self.order += 1
        elif self._capture is None and tag in BLOCK_TAGS and classes:
            if classes & PART_CLASSES:
                self._start("part_title", tag)
            elif classes & AUTHOR_CLASSES:
                self._start("author_block", tag)
            elif classes & TITLE_CLASSES:
                self._start("title_block", tag)
        elif tag == "br" and self._capture is not None:
            self._buffer.append(" ")

    def handle_endtag(self, tag):
        if not self._capture or tag != self._capture[1]:
            return
        kind, captured_tag, order = self._capture
        text = clean_text("".join(self._buffer))
        self._capture = None
        self._buffer = []
        if not text:
            return
        if kind == "heading":
            if len(self.headings) < 16:
                self.headings.append((order, captured_tag, text))
        elif kind in ("author_block", "title_block"):
            if len(self.blocks) < 12:
                self.blocks.append((order, kind, text))
        elif kind == "part_title":
            if len(self.part_titles) < 6:
                self.part_titles.append((order, text))
        elif kind == "document_title":
            self.document_title = text[:300]

    def handle_data(self, data):
        if self._capture is not None and sum(map(len, self._buffer)) < 500:
            self._buffer.append(data)


def _name_variants(text):
    """Candidate readings of a byline, longest first.

    Some MIA headings append a year or a publication label to the name. Taking
    the prefix before a year is evidence-preserving, not a guess: the full
    heading remains in the scan report.
    """
    text = clean_text(text)
    if not text:
        return []
    text = clean_text(BYLINE_PREFIX.sub("", text))
    if not text:
        return []
    variants = [text]
    year = re.search(r"\b(?:1[0-9]{3}|20[0-9]{2})\b", text)
    if year and year.start() > 0:
        variants.append(clean_text(text[:year.start()]).strip(" ,;:–—-"))
    parenthesis = re.search(r"\s*\(", text)
    if parenthesis and parenthesis.start() > 0:
        variants.append(clean_text(text[:parenthesis.start()]).strip(" ,;:–—-"))
    return [v for v in variants if v]


def _repair_broken_initial(text):
    # MIA occasionally renders "V. I. L énine" because of inline markup.
    match = re.match(
        r"^((?:[A-ZÁÀÂÃÉÊÍÓÔÕÚÇ]\.\s+)+)([A-ZÁÀÂÃÉÊÍÓÔÕÚÇ])\s+([a-záàâãéêíóôõúç]{2,})$",
        text,
    )
    if not match:
        return text
    return (match.group(1) + match.group(2) + match.group(3)).strip()


def _looks_like_name(text):
    text = clean_text(text)
    if not (2 <= len(text) <= 90):
        return False
    if re.search(r"\d", text):
        return False
    if text[-1] in "?!:;":
        return False
    tokens = text.split()
    if not tokens or len(tokens) > 8:
        return False
    if folded(tokens[0]) in ARTICLES:
        return False

    substantive = 0
    for token in tokens:
        core = token.strip(".,;:()[]{}'\"“”‘’*")
        if not core:
            continue
        key = folded(core)
        if key in MONTHS or key in NON_NAME_WORDS:
            return False
        if key in PART_WORDS or key in TITLE_WORDS:
            return False
        if core.lower() in PARTICLES:
            continue
        if len(core) == 1:
            if token.endswith(".") or core.isupper():
                continue
            return False
        if core.isupper() or core[0].isupper():
            substantive += 1
            continue
        return False
    return substantive >= 1 and any(len(folded(t.strip(".,;:"))) >= 3 for t in tokens)


def normalize_credit(value):
    """Return a usable name credit, or None for placeholders/descriptors."""
    text = clean_text(value)
    if not text or folded(text) in GENERIC_CREDITS:
        return None
    descriptor = CREDIT_DESCRIPTOR.match(text)
    if descriptor:
        candidate = clean_text(text[descriptor.end():])
        if _looks_like_name(candidate):
            return candidate
    return text if _looks_like_name(text) else None


def _name_candidate(text):
    for variant in _name_variants(text):
        repaired = _repair_broken_initial(variant)
        if _looks_like_name(repaired):
            return repaired
    return None


def _meta_is_corroborated(name, parser):
    """Require a meta author to appear as a complete visible byline.

    A stale or site-wide meta tag must not override the page's visible byline
    (or invent one). Matching a surname inside a title or an archive header
    ("Vygotsky and education", "Nestor Makhno Archive") is not corroboration;
    require the whole name on an author block, or on a heading after the page
    title, so the meta value cannot manufacture a credit by itself.
    """
    target = folded(name)
    if len(target) < 4:
        return False
    visible = [value for _, kind, value in parser.blocks if kind == "author_block"]
    visible.extend(value for _, _, value in parser.headings[1:])
    return any(folded(value) == target for value in visible)


def _header_author_is_container(parser):
    """True when the title/author heading pair heads a book, not this page.

    MIA pages for a preface or other part often print the book's title and
    author as ``h3``/``h4`` and then the actual part title, while the part's
    own byline is absent. Crediting the book's author there would be a guess,
    so the header pair is ignored when the next element is a prefatory part.
    A real chapter's part title (e.g. "II - ...") does not match PART_WORDS.
    Pages do not always mark the part title with a class, so the next heading
    is checked too.
    """
    if len(parser.headings) < 2:
        return False
    second_order = parser.headings[1][0]
    header_title = folded(parser.headings[0][2])
    for order, text in parser.part_titles:
        if order <= second_order:
            continue
        if any(second_order < heading[0] < order for heading in parser.headings):
            continue
        words = text.split()
        if not words:
            continue
        first = folded(words[0])
        return first in PART_WORDS and first not in header_title

    if len(parser.headings) >= 3:
        words = parser.headings[2][2].split()
        if words:
            first = folded(words[0])
            return first in PART_WORDS and first not in header_title
    return False


def extract_credit(page_html):
    """Return {credit, evidence} for an explicit source byline, else None."""
    parser = _CreditParser()
    parser.feed(page_html)
    headings = parser.headings[:8]
    blocks = parser.blocks[:8]
    header_is_container = _header_author_is_container(parser)

    # Portuguese standard: title h1 -> byline h2; chapters: title h3 -> h4.
    if not header_is_container and len(headings) >= 2:
        first, second = headings[0], headings[1]
        if (first[1], second[1]) in {("h1", "h2"), ("h3", "h4")}:
            credit = _name_candidate(second[2])
            if credit:
                return {"credit": credit, "evidence": "%s after %s" % (second[1], first[1])}

    # English style: a byline heading precedes the h1 title. Ignore section
    # labels (e.g. "Books in Review") because they are not name-like.
    if headings:
        h1_index = next((i for i, heading in enumerate(headings) if heading[1] == "h1"), None)
        if h1_index is not None:
            for _order, tag, text in reversed(headings[:h1_index]):
                credit = _name_candidate(text)
                if credit:
                    return {"credit": credit, "evidence": "%s before h1" % tag}

    # A "title"/archive header block can itself be the byline (common in older
    # English pages, e.g. "D.B. El'konin" or "Dora B. Montefiore 1909").
    if headings:
        first_order = headings[0][0]
        for order, _kind, text in blocks:
            if order >= first_order:
                continue
            credit = _name_candidate(text)
            if credit:
                return {"credit": credit, "evidence": "header block before title"}

    # An explicit author-class block after the title is still source evidence.
    if headings:
        first_order = headings[0][0]
        for order, kind, text in blocks:
            if order > first_order and kind == "author_block":
                credit = _name_candidate(text)
                if credit:
                    return {"credit": credit, "evidence": "author block"}

    # Meta author is accepted only when visible header text corroborates it.
    for _order, text in parser.meta:
        credit = _name_candidate(text)
        if credit and _meta_is_corroborated(credit, parser):
            return {"credit": credit, "evidence": "corroborated meta author"}

    return None


def load_credit_map(path, expected_language=None, expected_extractor=EXTRACTOR_VERSION):
    """Load reviewed, current-version credits into {archive path: credit}.

    Missing, unreadable, malformed, or stale files return {} instead of
    feeding old extractor output into the catalog. A file without an extractor
    stamp is treated as stale; this is what protects builders from a scan that
    was launched before the extraction rules changed.
    """
    if not os.path.exists(path):
        return {}
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError) as error:
        print("! ignoring unreadable credit file %s: %s" % (path, error), file=sys.stderr)
        return {}
    if not isinstance(data, dict):
        print("! ignoring credit file %s: not a JSON object" % path, file=sys.stderr)
        return {}
    extractor = data.get("extractor")
    if expected_extractor is not None and extractor != expected_extractor:
        print(
            "! ignoring stale credit file %s (extractor %r, expected %r)"
            % (path, extractor, expected_extractor),
            file=sys.stderr,
        )
        return {}
    if expected_language is not None and data.get("language") != expected_language:
        print(
            "! ignoring credit file %s (language %r, expected %r)"
            % (path, data.get("language"), expected_language),
            file=sys.stderr,
        )
        return {}
    entries = data.get("credits")
    if not isinstance(entries, dict):
        return {}
    result = {}
    for key, value in entries.items():
        if not isinstance(key, str) or not key:
            continue
        candidate = value.get("credit") if isinstance(value, dict) else value
        if not isinstance(candidate, str):
            continue
        candidate = normalize_credit(candidate)
        if candidate and len(candidate) <= 120:
            result[key] = candidate
    return result


def apply_credit_map(rows, credits):
    """Fill empty credit slots without overwriting explicit index credits."""
    for row in rows:
        if len(row) < 2 or not isinstance(row[1], str):
            continue
        credit = credits.get(row[1].split("#", 1)[0])
        if not isinstance(credit, str):
            continue
        credit = normalize_credit(credit)
        if not credit:
            continue
        if len(row) >= 5:
            if not row[4] or (len(row) >= 6 and row[5] == "archive-author"):
                row[4] = credit
                if len(row) >= 6 and row[5] == "archive-author":
                    row[5] = "source-page"
        elif len(row) == 4:
            row.append(credit)
        # Shorter rows do not have a credit slot; leave them untouched instead
        # of writing the credit into the date or section field.
    return rows


def apply_archive_author_fallback(rows, author):
    """Use the owning author archive as a fallback for its listed works.

    Explicit work-page and index credits are applied first and remain intact.
    The fallback is limited to rows already collected from an author's own
    works index; it is not suitable for thematic or general bibliography rows.
    """
    if not isinstance(author, str):
        return rows
    author = clean_text(author)
    if not author:
        return rows
    for row in rows:
        if len(row) < 4:
            continue
        if len(row) == 4:
            row.append(author)
            row.append("archive-author")
        elif not row[4]:
            row[4] = author
            if len(row) == 5:
                row.append("archive-author")
    return rows
