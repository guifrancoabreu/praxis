"""Monta o catálogo iOS em inglês a partir da seção inglesa do MIA,
seguindo a organização do próprio site:

- Writers:  archive/index.htm  (escritores agrupados por movimento)
- Subjects: subject/index.htm  (assuntos, escolas de pensamento, regiões)
- History:  history/index.htm  (países e organizações internacionais)
- Glossary: glossary/a.htm ... z.htm  (glossário de pessoas)

Uso:  python tools/build_catalog_en.py      (cache em tools/.cache-en)
"""
import json
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_catalog as b  # noqa: E402  (reaproveita download, cache e parser)

b.BASE = "https://www.marxists.org/"
b.CACHE = os.path.join(b.ROOT, "tools", ".cache-en")
OUT = os.path.join(b.ROOT, "ios", "Praxis", "Resources", "catalog-en.json")

SKIP = ("admin/", "css/", "ebooks/", "audiobooks/", "xlang/", "img/", "images/", "search")


def author_id(path):
    p = path.split("#")[0]
    return re.sub(r"/index\.html?$", "", p) if re.search(r"/index\.html?$", p) else p


# ------------------------------------------------------------------ writers

def build_writers():
    h = b.fetch("archive/index.htm")
    pat = re.compile(
        r'<h4[^>]*>(?P<h>.*?)</h4>'
        r'|<span class="author">\s*(?P<a>.*?)</span>(?P<rest>.*?)(?=<span class="author"|<h4|</table|$)',
        re.S,
    )
    group = ""
    writers, by_id = [], {}
    for m in pat.finditer(h):
        if m.group("h") is not None:
            g = b.clean(m.group("h")).strip("—– ").strip()
            if g:
                group = g
            continue
        link = re.search(r'href="([^"]+)"[^>]*>(.*?)</a>', m.group("a"), re.S)
        if not link:
            continue
        path = b.norm("archive/", link.group(1))
        if not path or not path.split("#")[0].lower().endswith((".htm", ".html")):
            continue
        name = b.clean(link.group(2))
        aid = author_id(path)
        rest = m.group("rest")
        if aid in by_id:
            if group and group not in by_id[aid]["groups"]:
                by_id[aid]["groups"].append(group)
            continue
        years = re.search(r"\(\s*([^()]*\d{3,4}[^()]*)\)", b.clean(rest)[:80])
        count = re.search(r"\b(\d[\d,]*\+)", b.clean(rest)[:120])
        bio = re.search(r'<a[^>]+class="biog"[^>]+href="([^"]+)"', rest) or re.search(r'href="([^"]*glossary/people/[^"]+)"', rest)
        text = b.clean(re.sub(r"\[\s*<a[^>]*>.*?</a>\s*\]", "", rest, flags=re.S))
        text = re.sub(r"^(?:[\s/&]*\([^()]*\d{3,4}[^()]*\)|\s*<\s*\d+|\s*[\d,]+\+|\s*\*|\s*[/&])+", "", text).strip()
        w = {
            "id": aid,
            "name": name,
            "years": years.group(1).strip() if years else "",
            "count": count.group(1) if count else "",
            "bio": text[:700],
            "bioPath": b.norm("archive/", bio.group(1)) if bio else "",
            "groups": [group] if group else [],
            "entry": path,
        }
        by_id[aid] = w
        writers.append(w)

    if len(sys.argv) > 1:  # teste rápido: python build_catalog_en.py 5
        writers = writers[: int(sys.argv[1])]
    print(f"{len(writers)} writers; fetching their pages…")
    for i, w in enumerate(writers, 1):
        if i % 50 == 0:
            print(f"  {i}/{len(writers)}", flush=True)
        page = b.fetch(w["entry"].split("#")[0])
        base_dir = w["entry"].rsplit("/", 1)[0] + "/"
        works = [x for x in b.parse_works(page, base_dir, skip_other_dirs=True) if not x[1].startswith(SKIP)]
        sections, rows = [], []
        for title, path, date, sec in works:
            if sec not in sections:
                sections.append(sec)
            rows.append([title, path, date, sections.index(sec)])
        w["sections"], w["works"] = sections, rows
        ph = re.search(r'<img[^>]+src="([^"]+\.(?:jpe?g|png|gif))"', page, re.I)
        if ph:
            src = b.norm(base_dir, ph.group(1))
            w["photo"] = src or ""
    return writers


# ------------------------------------------------- subjects / history

def build_sections(index_path, skip_dirs=()):
    idx = b.fetch(index_path)
    base_dir = index_path.rsplit("/", 1)[0] + "/"
    items = b.parse_works(idx, base_dir, skip_other_dirs=False)
    out, seen = [], set()
    for title, path, _date, heading in items:
        key = path.split("#")[0]
        if key in seen or key == "index.htm" or key.startswith(SKIP + tuple(skip_dirs)) or key.lower().endswith(".pdf"):
            continue
        seen.add(key)
        if title in ("First", "Second", "Third", "Fourth"):
            title += " International"
        title = title.strip("“”\" ")
        page = b.fetch(key)
        if not page:
            continue
        pdir = key.rsplit("/", 1)[0] + "/"
        groups = []
        for wt, wp, _d, sec in b.parse_works(page, pdir, skip_other_dirs=False):
            if wp.startswith(SKIP) or wp.split("#")[0] == key:
                continue
            if not groups or groups[-1]["name"] != sec:
                groups.append({"name": sec, "works": []})
            groups[-1]["works"].append([wt, wp])
        n = sum(len(g["works"]) for g in groups)
        out.append({"id": key, "title": title, "group": heading, "groups": groups})
        print(f"  {index_path.split('/')[0]}: {title} ({n})", flush=True)
    return out


# ------------------------------------------------------------- glossary

def build_people(writers):
    by_bio = {}
    for w in writers:
        if w["bioPath"]:
            by_bio[w["bioPath"]] = w["id"]
    people, seen = [], set()
    for letter in "abcdefghijklmnopqrstuvwxyz":
        h = b.fetch(f"glossary/{letter}.htm")
        for href, txt in re.findall(r'<a[^>]+href="([^"]*people/[^"]+)"[^>]*>(.*?)</a>', h, re.S):
            path = b.norm("glossary/", href)
            name = b.clean(txt)
            if not path or not name or path in seen:
                continue
            seen.add(path)
            f = {"name": name, "path": path, "person": bool(re.search(r"\d{3,4}|,", name))}
            if path in by_bio:
                f["author"] = by_bio[path]
            people.append(f)
    people.sort(key=lambda f: f["name"].lower())
    print(f"{len(people)} glossary entries")
    return people


def main():
    writers = build_writers()
    subjects = build_sections("subject/index.htm")
    history = build_sections("history/index.htm", skip_dirs=("subject/",))
    people = build_people(writers)
    for w in writers:
        w.pop("entry", None)
    data = {
        "lang": "en",
        "generated": time.strftime("%Y-%m-%d"),
        "source": b.BASE,
        "authors": writers,
        "themes": subjects,
        "history": history,
        "figures": people,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    n = sum(len(w["works"]) for w in writers)
    print(f"OK: {len(writers)} writers, {n} links, {len(subjects)} subjects, {len(history)} history pages, {len(people)} people -> {OUT}")


if __name__ == "__main__":
    main()
