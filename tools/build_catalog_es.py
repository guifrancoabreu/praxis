"""Build a starter Spanish catalog from MIA's selected Marxist writers index.

Run: python3 tools/build_catalog_es.py
Uses the same cached downloader and link parser as the Portuguese catalog builder.
"""
import json
import os
import re
import time
import build_catalog as b

b.BASE = "https://www.marxists.org/espanol/"
b.CACHE = os.path.join(b.ROOT, "tools", ".cache-es")
OUT = os.path.join(b.ROOT, "www", "data", "catalog-es.json")

def main():
    index = b.fetch("marxistas.htm")
    if not index:
        raise RuntimeError("Could not load Spanish writers index")
    authors = []
    for href, title in re.findall(r'<span class="author">\s*<a\s+href="([^"]+)"[^>]*>(.*?)</a>', index, re.S | re.I):
        name = b.clean(title)
        path = b.norm("", href)
        if not name or not path:
            continue
        page = b.fetch(path)
        if not page:
            continue
        base_dir = path.rsplit("/", 1)[0] + "/" if "/" in path else ""
        sections, works = [], []
        for title, work_path, date, section in b.parse_works(page, base_dir, skip_other_dirs=True):
            if section not in sections:
                sections.append(section)
            works.append([title, work_path, date, sections.index(section)])
        authors.append({"id": path, "name": name, "sections": sections, "works": works})
    if not authors or not any(a["works"] for a in authors):
        raise RuntimeError("Spanish index produced no works; check source format")
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"generated": time.strftime("%Y-%m-%d"), "source": b.BASE, "authors": authors}, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(authors)} writers, {sum(len(a['works']) for a in authors)} links -> {OUT}")

if __name__ == "__main__":
    main()
