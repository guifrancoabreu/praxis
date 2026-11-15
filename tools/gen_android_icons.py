#!/usr/bin/env python3
"""Generate the Android launcher icons from the shared app icon.

The iOS icon is a single 1024 px square with the artwork on a red field. Android needs density
variants, a round variant, and an adaptive icon whose foreground must stay inside the 72 dp safe
zone. The artwork's own red is used as the adaptive background so the seam is invisible.

Usage: python3 tools/gen_android_icons.py
"""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "ios/Praxis/Assets.xcassets/AppIcon.appiconset/Praxis-logo.png"
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def logo() -> Image.Image:
    return Image.open(SOURCE).convert("RGBA")


def square(size: int) -> Image.Image:
    return logo().resize((size, size), Image.LANCZOS)


def round_icon(size: int) -> Image.Image:
    image = square(size)
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4, size * 4), fill=255)
    image.putalpha(mask.resize((size, size), Image.LANCZOS))
    return image


def adaptive_foreground(size: int) -> Image.Image:
    # 108 dp canvas with a 72 dp safe zone: scale the artwork to 72/108 of the canvas.
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    art = logo().resize((round(size * 0.72),) * 2, Image.LANCZOS)
    offset = ((size - art.width) // 2, (size - art.height) // 2)
    canvas.paste(art, offset, art)
    return canvas


def background_color() -> str:
    red, green, blue, _ = logo().getpixel((4, 4))
    return f"#{red:02X}{green:02X}{blue:02X}"


def main() -> None:
    for density, size in DENSITIES.items():
        directory = RES / f"mipmap-{density}"
        directory.mkdir(parents=True, exist_ok=True)
        square(size).save(directory / "ic_launcher.png")
        round_icon(size).save(directory / "ic_launcher_round.png")

    drawable = RES / "drawable-nodpi"
    drawable.mkdir(parents=True, exist_ok=True)
    adaptive_foreground(432).save(drawable / "ic_launcher_foreground.png")

    adaptive = RES / "mipmap-anydpi-v26"
    adaptive.mkdir(parents=True, exist_ok=True)
    for name in ["ic_launcher", "ic_launcher_round"]:
        (adaptive / f"{name}.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background" />\n'
            '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
            "</adaptive-icon>\n",
            encoding="utf-8",
        )

    colors = RES / "values/colors.xml"
    colors.parent.mkdir(parents=True, exist_ok=True)
    text = colors.read_text(encoding="utf-8") if colors.exists() else '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n'
    if "ic_launcher_background" not in text:
        text = text.replace("</resources>", f'    <color name="ic_launcher_background">{background_color()}</color>\n</resources>')
        colors.write_text(text, encoding="utf-8")
    print(f"icons written to {RES.relative_to(ROOT)} (background {background_color()})")


if __name__ == "__main__":
    main()
