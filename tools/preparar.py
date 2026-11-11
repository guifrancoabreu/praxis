"""Copia www/ para apps/<idioma>/www com o idioma fixo e só o catálogo daquele idioma.

Uso:  python tools/preparar.py pt en
Depois, em apps/<idioma>:  npx cap sync android
"""
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOMES = {"pt": "Leitor Marxista", "en": "Marxist Reader"}


def preparar(lang):
    origem = os.path.join(ROOT, "www")
    destino = os.path.join(ROOT, "apps", lang, "www")
    if os.path.isdir(destino):
        shutil.rmtree(destino)

    def ignorar(pasta, nomes):
        if os.path.basename(pasta) == "data":
            return [n for n in nomes if n.startswith("catalog-") and n != f"catalog-{lang}.json"]
        return []

    shutil.copytree(origem, destino, ignore=ignorar)
    with open(os.path.join(destino, "js", "config.js"), "w", encoding="utf-8") as f:
        f.write(f"window.APP_CONFIG = {{ lang: '{lang}' }};\n")
    man_path = os.path.join(destino, "manifest.webmanifest")
    with open(man_path, encoding="utf-8") as f:
        man = json.load(f)
    man["name"] = man["short_name"] = NOMES[lang]
    man["lang"] = "pt-BR" if lang == "pt" else "en"
    with open(man_path, "w", encoding="utf-8") as f:
        json.dump(man, f, ensure_ascii=False, indent=2)
    print(f"apps/{lang}/www pronto")


if __name__ == "__main__":
    for lang in sys.argv[1:] or ["pt", "en"]:
        preparar(lang)
