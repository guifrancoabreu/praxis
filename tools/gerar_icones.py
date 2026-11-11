"""Gera os PNGs do ícone (foice e martelo) usados no Android e no app.

Uso:  python tools/gerar_icones.py      (precisa do Pillow: pip install pillow)
Saída: assets/  (para o @capacitor/assets)  e  www/img/icone-192.png, icone-512.png
A geometria é a mesma de www/img/emblema.svg (sistema de 512x512).
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OURO = (255, 204, 0, 255)
VERMELHO_CLARO = (211, 47, 47)
VERMELHO_ESCURO = (154, 0, 7)


def centro_arco(p1, p2, r, grande, horario):
    """Centro de um arco SVG (regra F.6.5 da especificação)."""
    (x1, y1), (x2, y2) = p1, p2
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    lam = (dx * dx + dy * dy) / (r * r)
    if lam > 1:
        r *= math.sqrt(lam)
    k = math.sqrt(max(0.0, (r * r - dx * dx - dy * dy) / (dx * dx + dy * dy)))
    if grande == horario:
        k = -k
    cx, cy = k * dy + (x1 + x2) / 2, -k * dx + (y1 + y2) / 2
    return cx, cy, r


def pontos_arco(p1, p2, r, grande, horario, n=180):
    cx, cy, r = centro_arco(p1, p2, r, grande, horario)
    a1 = math.atan2(p1[1] - cy, p1[0] - cx)
    a2 = math.atan2(p2[1] - cy, p2[0] - cx)
    d = a2 - a1
    if horario and d < 0:
        d += 2 * math.pi
    if not horario and d > 0:
        d -= 2 * math.pi
    return [(cx + r * math.cos(a1 + d * i / n), cy + r * math.sin(a1 + d * i / n)) for i in range(n + 1)]


def emblema(tam):
    """Desenha o emblema dourado num quadrado transparente de lado `tam`."""
    S = 4  # supersampling para bordas suaves
    W = tam * S
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    esc = W / 512
    ox, oy = 10, 14  # translate do SVG

    def P(x, y):
        return ((x + ox) * esc, (y + oy) * esc)

    def linha(x1, y1, x2, y2, larg):
        a, b = P(x1, y1), P(x2, y2)
        w = larg * esc
        d.line([a, b], fill=OURO, width=round(w))
        for c in (a, b):
            d.ellipse([c[0] - w / 2, c[1] - w / 2, c[0] + w / 2, c[1] + w / 2], fill=OURO)

    # foice: lâmina (arco externo + arco interno)
    T, B1, B2 = (245.7, 92.1), (148.8, 300.0), (186.0, 270.0)
    contorno = pontos_arco(T, B1, 140, True, True) + pontos_arco(B2, T, 98, True, False)
    d.polygon([P(x, y) for x, y in contorno], fill=OURO)
    # foice: cabo e junção
    linha(166, 287, 116, 374, 36)
    c = P(170, 282)
    d.ellipse([c[0] - 22 * esc, c[1] - 22 * esc, c[0] + 22 * esc, c[1] + 22 * esc], fill=OURO)
    # martelo: cabo
    linha(388, 398, 214, 182, 32)
    # martelo: cabeça (retângulo 164x64 girado -39° em torno de (200,165))
    ang = math.radians(-39)
    cos, sin = math.cos(ang), math.sin(ang)
    cantos = [(-82, -32), (82, -32), (82, 32), (-82, 32)]
    d.polygon([P(200 + x * cos - y * sin, 165 + x * sin + y * cos) for x, y in cantos], fill=OURO)
    return img.resize((tam, tam), Image.LANCZOS)


def fundo(tam):
    """Fundo vermelho com degradê radial."""
    img = Image.new("RGB", (tam, tam))
    px = img.load()
    cx, cy, rmax = tam * 0.5, tam * 0.4, tam * 0.75
    for y in range(tam):
        for x in range(tam):
            t = min(1.0, math.hypot(x - cx, y - cy) / rmax)
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(VERMELHO_CLARO, VERMELHO_ESCURO))
    return img.convert("RGBA")


def compor(tam, proporcao):
    base = fundo(tam)
    e = round(tam * proporcao)
    base.alpha_composite(emblema(e), ((tam - e) // 2, (tam - e) // 2))
    return base


def main():
    assets = os.path.join(ROOT, "assets")
    os.makedirs(assets, exist_ok=True)
    compor(1024, 0.72).save(os.path.join(assets, "icon-only.png"))
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    e = emblema(560)  # dentro da área segura do ícone adaptativo
    fg.alpha_composite(e, ((1024 - 560) // 2, (1024 - 560) // 2))
    fg.save(os.path.join(assets, "icon-foreground.png"))
    fundo(1024).save(os.path.join(assets, "icon-background.png"))
    splash = fundo(1366).resize((2732, 2732), Image.BICUBIC)
    e = emblema(800)
    splash.alpha_composite(e, ((2732 - 800) // 2, (2732 - 800) // 2))
    splash.save(os.path.join(assets, "splash.png"))
    splash.save(os.path.join(assets, "splash-dark.png"))
    for t in (192, 512):
        compor(t, 0.72).save(os.path.join(ROOT, "www", "img", f"icone-{t}.png"))
    print("Ícones gerados em assets/ e www/img/")


if __name__ == "__main__":
    main()
