"""Monta o catálogo iOS em português a partir da seção portuguesa do MIA.

Uso:  python tools/build_catalog.py
As páginas baixadas ficam em tools/.cache, então rodar de novo é rápido.
Para buscar tudo de novo, apague tools/.cache.
"""
import hashlib
import html
import json
import os
import re
import sys
import time
import urllib.request
from html.parser import HTMLParser
from urllib.parse import urljoin

BASE = "https://www.marxists.org/portugues/"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".cache")
OUT = os.path.join(ROOT, "ios", "MarxistReader", "Resources", "catalog-pt.json")
DELAY = 0.35  # pausa entre downloads, para não sobrecarregar o site
UA = "LeitorMarxista-catalogo/1.0 (app de leitura; uso pessoal)"


# ---------------------------------------------------------------- download

def fetch(path):
    """Baixa BASE+path (com cache em disco) e devolve o texto decodificado."""
    fn = os.path.join(CACHE, path.replace("/", "__"))
    if len(fn) > 240:  # limite de caminho do Windows
        fn = os.path.join(CACHE, hashlib.md5(path.encode()).hexdigest() + ".htm")
    if os.path.exists(fn):
        with open(fn, "rb") as f:
            raw = f.read()
    else:
        time.sleep(DELAY)
        req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
        try:
            raw = urllib.request.urlopen(req, timeout=40).read()
        except Exception as e:  # página quebrada: registra e segue
            print("  ! falhou", path, e, file=sys.stderr)
            return ""
        os.makedirs(CACHE, exist_ok=True)
        with open(fn, "wb") as f:
            f.write(raw)
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace")


def clean(s):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s))).strip()


def norm(base_dir, href):
    """Converte um link relativo em caminho relativo a /portugues/."""
    full = urljoin(BASE + base_dir, href.strip())
    if not full.startswith(BASE):
        return None
    return full[len(BASE):]


def is_work_link(path):
    if not path:
        return False
    p = path.split("#")[0].lower()
    return p.endswith((".htm", ".html", ".pdf")) and not p.startswith(
        ("admin/", "dicionario/", "tematica/", "css/", "img/")
    )


# ---------------------------------------------------- parser genérico de obras

class WorkParser(HTMLParser):
    """Percorre uma página e coleta links de obras, com data e seção."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.works = []          # (titulo, href, data, secao)
        self.section = ""
        self.cap = None          # captura de texto de título de seção
        self.cap_text = []
        self.in_tr = False
        self.cells = []          # [{text, links}]
        self.cell = None
        self.link = None         # [href, [texto]]

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in ("h2", "h3", "h4", "th"):
            self.cap, self.cap_text = tag, []
        elif tag == "tr":
            self.in_tr, self.cells = True, []
        elif tag == "td" and self.in_tr:
            self.cell = {"text": [], "links": []}
        elif tag == "a" and a.get("href"):
            self.link = [a["href"], []]
        elif tag == "area" and a.get("href") and a.get("alt"):
            self.works.append((a["alt"].strip().capitalize(), a["href"], "", self.section))

    def handle_endtag(self, tag):
        if tag == self.cap:
            t = clean(" ".join(self.cap_text))
            if t and len(t) < 120:
                self.section = t
            self.cap = None
        elif tag == "a" and self.link:
            href, txt = self.link[0], clean(" ".join(self.link[1]))
            self.link = None
            if self.cell is not None:
                self.cell["links"].append((txt, href))
            else:
                self.works.append((txt, href, "", self.section))
        elif tag == "td" and self.cell is not None:
            self.cells.append(self.cell)
            self.cell = None
        elif tag == "tr" and self.in_tr:
            self.in_tr = False
            date = ""
            if self.cells and not self.cells[0]["links"]:
                date = clean(" ".join(self.cells[0]["text"]))[:30]
            for c in self.cells:
                for txt, href in c["links"]:
                    self.works.append((txt, href, date, self.section))

    def handle_data(self, data):
        if self.cap:
            self.cap_text.append(data)
        if self.link:
            self.link[1].append(data)
        if self.cell is not None:
            self.cell["text"].append(data)


def parse_works(page_html, base_dir, skip_other_dirs):
    start = page_html.find("<h1")
    p = WorkParser()
    p.feed(page_html[start if start > 0 else 0:])
    out, seen = [], set()
    for title, href, date, sec in p.works:
        if href.startswith(("#", "mailto:", "javascript:")):
            continue
        if skip_other_dirs and href.startswith(("../", "/", "http")):
            continue
        path = norm(base_dir, href)
        if not is_work_link(path) or not title or len(title) < 2:
            continue
        key = path.split("#")[0] if not path.lower().split("#")[0].endswith(".pdf") else path
        if key in seen or title.lower() in ("biografia", "início da página", "topo"):
            continue
        seen.add(key)
        out.append((title, path, date, sec))
    return out


def author_portrait(page_html, base_dir, author_name):
    """Return a clearly author-specific portrait image from an author page."""
    name_parts = [part.lower() for part in re.findall(r"[\w-]+", author_name) if len(part) > 3]
    candidates = []
    for tag in re.findall(r"<img\b[^>]*>", page_html, re.I):
        if re.search(r"\busemap\s*=", tag, re.I):
            continue
        src = re.search(r"\bsrc\s*=\s*['\"]([^'\"]+)['\"]", tag, re.I)
        if not src:
            continue
        path = src.group(1).strip()
        basename = path.rsplit("/", 1)[-1].lower()
        if not basename.split("?")[0].endswith((".jpg", ".jpeg", ".png", ".webp")):
            continue
        if any(term in basename for term in ("logo", "banner", "header", "index", "button", "espan")):
            continue
        alt = re.search(r"\balt\s*=\s*['\"]([^'\"]*)['\"]", tag, re.I)
        description = (basename + " " + (alt.group(1).lower() if alt else ""))
        score = sum(part in description for part in name_parts)
        if score:
            normalized = norm(base_dir, path)
            if normalized:
                candidates.append((score, normalized))
    return max(candidates, default=(0, None), key=lambda item: item[0])[1]


# ------------------------------------------------------------------ países

COUNTRIES = [
    # (nome exibido, gentílicos/termos fortes, nomes do país)
    ("Brasil", r"brasileir[oa]s?|baian[oa]|paulista|carioca|ga[uú]ch[oa]|mineir[oa]|pernambucan[oa]|cearense", r"brasil|s[aã]o paulo|rio de janeiro|bahia|recife"),
    ("Portugal", r"portugu[eê]s|portuguesa|lisboeta", r"portugal|lisboa|coimbra"),
    ("Rússia / URSS", r"russ[oa]|sovi[eé]tic[oa]", r"r[uú]ssia|uni[aã]o sovi[eé]tica|urss"),
    ("Alemanha", r"alem[aã]o?|alem[aã]", r"alemanha|pr[uú]ssia"),
    ("França", r"franc[eê]s|francesa", r"fran[cç]a"),
    ("Itália", r"italian[oa]", r"it[aá]lia"),
    ("Espanha", r"espanhol[a]?|catal[aã]o", r"espanha"),
    ("Reino Unido", r"ingl[eê]s|inglesa|brit[aâ]nic[oa]|escoc[eê]s|gal[eê]s", r"inglaterra|esc[oó]cia|reino unido|gr[aã]-bretanha"),
    ("Irlanda", r"irland[eê]s|irlandesa", r"irlanda"),
    ("Estados Unidos", r"norte-american[oa]|estadunidense|estado-unidense|(?<!latino-)(?<!sul-)(?<!centro-)american[oa]", r"estados unidos|eua"),
    ("Canadá", r"canadense", r"canad[aá]"),
    ("Cuba", r"cuban[oa]", r"cuba"),
    ("México", r"mexican[oa]", r"m[eé]xico"),
    ("Argentina", r"argentin[oa]", r"argentina"),
    ("Chile", r"chilen[oa]", r"chile"),
    ("Peru", r"peruan[oa]", r"peru"),
    ("Equador", r"equatorian[oa]", r"equador"),
    ("Bolívia", r"bolivian[oa]", r"bol[ií]via"),
    ("Colômbia", r"colombian[oa]", r"col[oô]mbia"),
    ("Venezuela", r"venezuelan[oa]", r"venezuela"),
    ("Uruguai", r"uruguai[oa]", r"uruguai"),
    ("Paraguai", r"paraguai[oa]", r"paraguai"),
    ("Nicarágua", r"nicaraguense", r"nicar[aá]gua"),
    ("El Salvador", r"salvadorenh[oa]", r"el salvador"),
    ("Guatemala", r"guatemalte[cq][oa]", r"guatemala"),
    ("Haiti", r"haitian[oa]", r"haiti"),
    ("China", r"chin[eê]s|chinesa", r"china"),
    ("Vietnã", r"vietnamit[ao]", r"vietn[aã]m?"),
    ("Coreia", r"corean[oa]", r"coreia"),
    ("Japão", r"japon[eê]s|japonesa", r"jap[aã]o"),
    ("Índia", r"indian[oa]", r"[ií]ndia"),
    ("Filipinas", r"filipin[oa]", r"filipinas"),
    ("Indonésia", r"indon[eé]si[oa]", r"indon[eé]sia"),
    ("Polônia", r"polon[eê]s|polonesa|polac[oa]", r"pol[oô]nia"),
    ("Hungria", r"h[uú]ngar[oa]", r"hungria"),
    ("Tchecoslováquia", r"tchec[oa]|chec[oa]|eslovac[oa]", r"tchecoslov[aá]quia|checoslov[aá]quia"),
    ("Bulgária", r"b[uú]lgar[oa]", r"bulg[aá]ria"),
    ("Romênia", r"romen[oa]", r"rom[eê]nia"),
    ("Iugoslávia", r"iugoslav[oa]|s[eé]rvi[oa]|croat[ao]|eslovenia?[oa]?", r"iugosl[aá]via|s[eé]rvia|cro[aá]cia"),
    ("Albânia", r"alban[eê]s|albanesa", r"alb[aâ]nia"),
    ("Grécia", r"greg[oa]", r"gr[eé]cia"),
    ("Áustria", r"austr[ií]ac[oa]", r"[aá]ustria"),
    ("Suíça", r"su[ií][cç][oa]", r"su[ií][cç]a"),
    ("Bélgica", r"belga", r"b[eé]lgica"),
    ("Holanda", r"holand[eê]s|holandesa|neerland[eê]s", r"holanda|pa[ií]ses baixos"),
    ("Suécia", r"suec[oa]", r"su[eé]cia"),
    ("Noruega", r"noruegu[eê]s|norueguesa", r"noruega"),
    ("Dinamarca", r"dinamarqu[eê]s|dinamarquesa", r"dinamarca"),
    ("Finlândia", r"finland[eê]s|finlandesa", r"finl[aâ]ndia"),
    ("Ucrânia", r"ucranian[oa]", r"ucr[aâ]nia"),
    ("Geórgia", r"georgian[oa]", r"ge[oó]rgia"),
    ("Países Bálticos", r"let[aã]o|let[aã]|lituan[oa]|estonian[oa]", r"let[oô]nia|litu[aâ]nia|est[oô]nia"),
    ("Angola", r"angolan[oa]", r"angola"),
    ("Moçambique", r"mo[cç]ambican[oa]", r"mo[cç]ambique"),
    ("Guiné-Bissau / Cabo Verde", r"guineense|cabo-verdian[oa]|caboverdian[oa]", r"guin[eé]-bissau|guin[eé] bissau|cabo verde"),
    ("África do Sul", r"sul-african[oa]", r"[aá]frica do sul"),
    ("Burkina Faso", r"burquin[eê]s|burkinab[eé]", r"burkina faso|alto volta"),
    ("Gana", r"ganense", r"gana"),
    ("Congo", r"congol[eê]s|congolesa", r"congo"),
    ("Egito", r"eg[ií]pci[oa]", r"egito"),
    ("Argélia", r"argelin[oa]", r"arg[eé]lia"),
    ("Palestina", r"palestin[oa]", r"palestina"),
    ("Irã", r"iranian[oa]", r"ir[aã]"),
    ("Iraque", r"iraquian[oa]", r"iraque"),
    ("Turquia", r"turc[oa]", r"turquia"),
    ("Camboja", r"cambojan[oa]|khmer", r"camboja|kampuchea"),
    ("Martinica / Caribe", r"martinicano|jamaicano|trinitino", r"martinica|jamaica|trinidad"),
]
_C = [(n, re.compile(r"\b(?:%s)\b" % d, re.I), re.compile(r"\b(?:%s)\b" % c, re.I)) for n, d, c in COUNTRIES]


def guess_country(bio):
    """Escolhe o país pelo gentílico citado primeiro; senão, pelo país citado primeiro."""
    text = bio[:700]
    best = None
    for name, demo, _ in _C:
        m = demo.search(text)
        if m and (best is None or m.start() < best[0]):
            best = (m.start(), name)
    if best:
        return best[1]
    for name, _, country in _C:
        m = country.search(text)
        if m and (best is None or m.start() < best[0]):
            best = (m.start(), name)
    if best:
        return best[1]
    # cidade brasileira seguida da sigla do estado: "Porto Alegre, RS"
    if re.search(r",\s*(?:AC|AL|AM|AP|BA|CE|DF|ES|GO|MA|MG|MS|MT|PA|PB|PE|PI|PR|RJ|RN|RO|RR|RS|SC|SE|SP|TO)\b", text):
        return "Brasil"
    return "Outros"


# Correções manuais para autores cuja biografia não deixa o país claro.
OVERRIDES = {
    "marx": "Alemanha", "jenny": "Alemanha", "kautsky": "Alemanha", "mao": "China",
    "stalin": "Rússia / URSS", "kollontai": "Rússia / URSS", "plekhanov": "Rússia / URSS",
    "makarenko": "Rússia / URSS", "zhdanov": "Rússia / URSS", "yaroslavsky": "Rússia / URSS",
    "preobrazhensky": "Rússia / URSS", "leontiev": "Rússia / URSS", "furtseva": "Rússia / URSS",
    "sapronov": "Rússia / URSS", "dune": "Rússia / URSS", "serge": "Rússia / URSS",
    "prestes": "Brasil", "marighella": "Brasil", "pomar": "Brasil", "cunhal": "Portugal",
    "saramago": "Portugal", "london": "Estados Unidos", "deleon": "Estados Unidos",
    "babeuf": "França", "barbusse": "França", "wallon": "França", "kardelj": "Iugoslávia",
    "mella": "Cuba", "harman": "Reino Unido", "pol-pot": "Camboja", "ieng-sary": "Camboja",
    "nuon": "Camboja",
}


# ------------------------------------------------------------------ autores

def build_authors():
    page = fetch("biblioteca.htm")
    authors = []
    seen = set()
    table = page[page.find('id="autores"'):]
    for row in re.findall(r"<tr>(.*?)</tr>", table, re.S):
        m = re.search(r'<a[^>]+href="([^"#/]+)/index\.htm"[^>]*>(.*?)</a>', row, re.S)
        if not m or m.group(1) in seen:
            continue
        slug = m.group(1)
        cells = [clean(c) for c in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)]
        bio = re.search(r'href="(dicionario/[^"]+)"', row)
        av = re.search(r'src="(img/avatares/[^"]+)"', row)
        seen.add(slug)
        authors.append({
            "id": slug,
            "name": clean(m.group(2)),
            "years": cells[2] if len(cells) > 2 else "",
            "avatar": av.group(1) if av else "",
            "bioPath": bio.group(1) if bio else "",
        })

    if len(sys.argv) > 1:  # teste rápido: python build_catalog.py 5
        authors = authors[: int(sys.argv[1])]
    print(f"{len(authors)} autores; baixando páginas dos autores…")
    for i, a in enumerate(authors, 1):
        if i % 25 == 0:
            print(f"  {i}/{len(authors)}")
        h = fetch(a["id"] + "/index.htm")
        h1 = re.search(r"<h1[^>]*>(.*?)</h1>", h, re.S)
        a["full"] = clean(h1.group(1)) if h1 else a["name"]
        d = re.search(r'<div class="data">(.*?)</div>', h, re.S)
        a["dates"] = clean(d.group(1)) if d else ""
        ph = re.search(r'<img[^>]+src="(img/[^"]+)"', h)
        a["photo"] = a["id"] + "/" + ph.group(1) if ph else ""
        head = h[: h.find("<table")] if "<table" in h else h[:20000]
        paras = [clean(p) for p in re.findall(r"<p(?![^>]*(?:toplink|lapide))[^>]*>(.*?)</p>", head, re.S)]
        if not a["dates"]:
            d = re.search(r'<div class="link">\s*(\d{3,4}\s*-\s*\d{0,4})\s*</div>', h)
            a["dates"] = d.group(1) if d else ""
        bio = " ".join(p for p in paras if len(p) > 40)
        a["country"] = guess_country(bio)
        if (a["country"] == "Outros" or len(bio) < 80) and a["bioPath"]:
            # segunda fonte: o verbete do dicionário político
            dh = fetch(a["bioPath"])
            dh = re.sub(r"(?is)<(script|style|nav|header)\b.*?</\1>", "", dh)
            dparas = [clean(p) for p in re.findall(r"<p[^>]*>(.*?)</p>", dh, re.S)]
            dbio = " ".join(p for p in dparas if len(p) > 40 and "Leia as obras" not in p)
            if len(bio) < 80:
                bio = dbio or bio
            if a["country"] == "Outros":
                a["country"] = guess_country(dbio)
        a["country"] = OVERRIDES.get(a["id"], a["country"])
        a["bio"] = bio[:900]
        works = parse_works(h, a["id"] + "/", skip_other_dirs=True)
        sections = []
        rows = []
        for title, path, date, sec in works:
            if sec not in sections:
                sections.append(sec)
            rows.append([title, path, date, sections.index(sec)])
        a["sections"] = sections
        a["works"] = rows
    return authors


# ------------------------------------------------------------------ temas

SKIP_THEMES = {"album_fotos/index.htm", "filmes/index.htm", "musica/index.htm", "audiolivros.htm", "../ebooks/index.htm"}


def build_themes():
    idx = fetch("tematica/index.htm")
    themes = []
    for href, title in re.findall(r'<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', idx, re.S):
        title = clean(title)
        if href in SKIP_THEMES or href.startswith(("..", "#", "http")) or not title:
            continue
        if any(t["src"] == href for t in themes):
            continue
        h = fetch("tematica/" + href)
        works = parse_works(h, "tematica/", skip_other_dirs=False)
        groups = []
        for wt, path, _date, sec in works:
            if not groups or groups[-1]["name"] != sec:
                groups.append({"name": sec, "works": []})
            groups[-1]["works"].append([wt, path])
        themes.append({"id": href.rsplit(".", 1)[0], "src": href, "title": title, "groups": groups})
        print(f"  tema: {title} ({len(works)} obras)")
    return themes


# ------------------------------------------------------- figuras históricas

def build_figures(authors):
    by_bio = {a["bioPath"]: a["id"] for a in authors if a["bioPath"]}
    figs = []
    for letter in "abcdefghijklmnopqrstuvwxyz":
        h = fetch(f"dicionario/verbetes/{letter}/index.htm")
        main = h[h.find("<main"):] if "<main" in h else h
        for href, name in re.findall(r'<li>\s*<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', main, re.S):
            path = norm(f"dicionario/verbetes/{letter}/", href)
            name = clean(name)
            if not path or not name:
                continue
            f = {"name": name, "path": path, "person": "," in name}
            if path in by_bio:
                f["author"] = by_bio[path]
            figs.append(f)
    print(f"{len(figs)} verbetes no dicionário")
    return figs


def main():
    authors = build_authors()
    themes = build_themes()
    figures = build_figures(authors)
    for t in themes:
        t.pop("src", None)
    data = {
        "generated": time.strftime("%Y-%m-%d"),
        "source": BASE,
        "authors": authors,
        "themes": themes,
        "figures": figures,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    n = sum(len(a["works"]) for a in authors)
    print(f"OK: {len(authors)} autores, {n} obras, {len(themes)} temas, {len(figures)} verbetes -> {OUT}")


if __name__ == "__main__":
    main()
