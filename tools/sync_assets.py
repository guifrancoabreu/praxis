#!/usr/bin/env python3
"""Keep the binary assets shared by both apps in sync with `shared/assets/`.

`shared/assets/` is the source of truth: the brand master and the fonts. Each build system still
needs its own copy at a fixed path, so this script writes those copies and verifies them. The
Android launcher icons are not copies — they are derived rasters, regenerated from the same
master with the same resampling so the iOS and Android icons cannot drift apart.

Usage:
  python3 tools/sync_assets.py --check   # verify every generated copy (CI)
  python3 tools/sync_assets.py --write   # regenerate every generated copy
"""

from __future__ import annotations

import hashlib
import io
import pathlib
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover - environment problem, not a content problem
    raise SystemExit("sync_assets.py needs Pillow: python3 -m pip install pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "shared" / "assets"
BRAND = ASSETS / "brand" / "praxis-logo.png"
FONTS = ASSETS / "fonts"

IOS_ICON = ROOT / "ios" / "Praxis" / "Assets.xcassets" / "AppIcon.appiconset" / "Praxis-logo.png"
IOS_FONTS = ROOT / "ios" / "Praxis" / "Fonts"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
ANDROID_FONTS = ANDROID_RES / "font"
ANDROID_RAW = ANDROID_RES / "raw"

DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND_SIZE = 432
ADAPTIVE_XML = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background" />\n'
    '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
    "</adaptive-icon>\n"
)

# Byte-for-byte copies: (master, generated copy).
COPIES = [
    (BRAND, IOS_ICON),
    (FONTS / "inter.ttf", IOS_FONTS / "inter.ttf"),
    (FONTS / "literata.ttf", IOS_FONTS / "literata.ttf"),
    (FONTS / "inter_license.txt", IOS_FONTS / "inter_license.txt"),
    (FONTS / "literata_license.txt", IOS_FONTS / "literata_license.txt"),
    (FONTS / "inter.ttf", ANDROID_FONTS / "inter.ttf"),
    (FONTS / "literata.ttf", ANDROID_FONTS / "literata.ttf"),
    (FONTS / "inter_license.txt", ANDROID_RAW / "inter_license.txt"),
    (FONTS / "literata_license.txt", ANDROID_RAW / "literata_license.txt"),
]


def logo() -> Image.Image:
    return Image.open(BRAND).convert("RGBA")


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


def png(image: Image.Image) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def colors_xml() -> bytes:
    """`values/colors.xml` is shared with hand-written colors, so only the launcher entry is ours."""
    path = ANDROID_RES / "values" / "colors.xml"
    text = (
        path.read_text(encoding="utf-8")
        if path.exists()
        else '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n'
    )
    color = background_color()
    entry = f'    <color name="ic_launcher_background">{color}</color>\n'
    if "ic_launcher_background" not in text:
        text = text.replace("</resources>", f"{entry}</resources>")
    else:
        start = text.index('    <color name="ic_launcher_background">')
        end = text.index("\n", start) + 1
        text = text[:start] + entry + text[end:]
    return text.encode("utf-8")


def derived() -> dict[pathlib.Path, bytes]:
    """The Android launcher assets, rebuilt in memory so `--check` can compare bytes."""
    files: dict[pathlib.Path, bytes] = {}
    for density, size in DENSITIES.items():
        directory = ANDROID_RES / f"mipmap-{density}"
        files[directory / "ic_launcher.png"] = png(square(size))
        files[directory / "ic_launcher_round.png"] = png(round_icon(size))
    files[ANDROID_RES / "drawable-nodpi" / "ic_launcher_foreground.png"] = png(adaptive_foreground(FOREGROUND_SIZE))
    for name in ["ic_launcher", "ic_launcher_round"]:
        files[ANDROID_RES / "mipmap-anydpi-v26" / f"{name}.xml"] = ADAPTIVE_XML.encode("utf-8")
    files[ANDROID_RES / "values" / "colors.xml"] = colors_xml()
    return files


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def check() -> list[str]:
    stale: list[str] = []
    for master, copy in COPIES:
        if not master.is_file():
            stale.append(f"{master.relative_to(ROOT)} is missing")
            continue
        expected = digest(master.read_bytes())
        actual = digest(copy.read_bytes()) if copy.is_file() else None
        if actual != expected:
            stale.append(f"{copy.relative_to(ROOT)} does not match {master.relative_to(ROOT)}")
    for path, expected in derived().items():
        if not path.is_file():
            stale.append(f"{path.relative_to(ROOT)} is missing")
        elif path.read_bytes() != expected:
            stale.append(f"{path.relative_to(ROOT)} is stale")
    return stale


def write() -> None:
    for master, copy in COPIES:
        copy.parent.mkdir(parents=True, exist_ok=True)
        copy.write_bytes(master.read_bytes())
    for path, data in derived().items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    print(f"wrote {len(COPIES) + len(derived())} copies from shared/assets")


def main(argv: list[str]) -> int:
    if "--write" in argv:
        write()
    stale = check()
    if stale:
        print("asset check failed:", file=sys.stderr)
        for item in stale:
            print(f"  - {item}", file=sys.stderr)
        print("run python3 tools/sync_assets.py --write", file=sys.stderr)
        return 1
    print(f"assets OK: {len(COPIES) + len(derived())} generated copies match shared/assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
