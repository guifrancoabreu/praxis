#!/usr/bin/env python3
"""Generate the Google Play listing artwork from the shared app icon.

Play wants a 512x512 app icon and a 1024x500 feature graphic. Both are built from the same
1024 px source used by iOS, so the store icon cannot drift from the launcher icon. The feature
graphic keeps the artwork uncropped, centred on the artwork's own red, with the "Praxis" wordmark
below it in a serif face so the banner matches the wordmark on the support site.

Screenshots are captured from an emulator by another engineer; this script does not fake them.

Usage: python3 tools/gen_play_assets.py
"""

from __future__ import annotations

import pathlib
from collections import Counter

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "ios/Praxis/Assets.xcassets/AppIcon.appiconset/Praxis-logo.png"
OUT = ROOT / "output/play"

ICON_SIZE = 512
FEATURE_SIZE = (1024, 500)
ART_SIZE = 340  # leaves ~40 px above and below the lockup inside 500 px
WORDMARK_SIZE = 88
WORDMARK_GAP = 12
WORDMARK = "Praxis"

# Georgia matches the site's wordmark; the rest are fallbacks for machines without it.
SERIF_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
    "/Library/Fonts/Georgia Bold.ttf",
    "/System/Library/Fonts/NewYork.ttf",
    "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf",
    "/usr/share/fonts/truetype/noto/NotoSerif-Bold.ttf",
]


def logo() -> Image.Image:
    return Image.open(SOURCE).convert("RGB")


def field_color() -> tuple[int, int, int]:
    """The artwork's own red, so the banner background is indistinguishable from the icon."""
    image = logo()
    width, height = image.size
    corners = [
        image.getpixel((2, 2)),
        image.getpixel((width - 3, 2)),
        image.getpixel((2, height - 3)),
        image.getpixel((width - 3, height - 3)),
    ]
    return tuple(sorted(channel)[1] for channel in zip(*corners))  # type: ignore[return-value]


def ink_color() -> tuple[int, int, int]:
    """The cream used by the artwork's highlights, sampled from its brightest pixels."""
    image = logo()
    width, height = image.size
    counts: Counter[tuple[int, int, int]] = Counter()
    for y in range(0, height, 4):
        for x in range(0, width, 4):
            pixel = image.getpixel((x, y))
            if sum(pixel) / 3 > 200:
                counts[tuple(channel - channel % 4 for channel in pixel)] += 1
    return counts.most_common(1)[0][0]  # type: ignore[return-value]


def serif_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in SERIF_CANDIDATES:
        if pathlib.Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    print("warning: no system serif found, the wordmark falls back to the bitmap font")
    return ImageFont.load_default()


def icon(size: int) -> Image.Image:
    return logo().resize((size, size), Image.LANCZOS)


def feature_graphic() -> Image.Image:
    width, height = FEATURE_SIZE
    canvas = Image.new("RGB", FEATURE_SIZE, field_color())
    draw = ImageDraw.Draw(canvas)
    font = serif_font(WORDMARK_SIZE)

    left, top, right, bottom = draw.textbbox((0, 0), WORDMARK, font=font)
    ink_height = bottom - top
    block_height = ART_SIZE + WORDMARK_GAP + ink_height
    block_top = (height - block_height) // 2

    art = logo().resize((ART_SIZE, ART_SIZE), Image.LANCZOS)
    canvas.paste(art, ((width - ART_SIZE) // 2, block_top))
    draw.text(
        ((width - (right - left)) // 2, block_top + ART_SIZE + WORDMARK_GAP - top),
        WORDMARK,
        font=font,
        fill=ink_color(),
    )
    return canvas


def verify(path: pathlib.Path, expected: tuple[int, int]) -> None:
    with Image.open(path) as image:
        if image.size != expected:
            found = f"{image.size[0]}x{image.size[1]}"
            raise SystemExit(f"{path.relative_to(ROOT)} is {found}, expected {expected[0]}x{expected[1]}")
        size = f"{image.size[0]}x{image.size[1]}"
        print(f"{path.relative_to(ROOT)}: {size} {image.mode} {path.stat().st_size // 1024} KB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    icon_path = OUT / "icon-512.png"
    icon(ICON_SIZE).save(icon_path, optimize=True)

    feature_path = OUT / "feature-graphic-1024x500.png"
    feature_graphic().save(feature_path, optimize=True)

    verify(icon_path, (ICON_SIZE, ICON_SIZE))
    verify(feature_path, FEATURE_SIZE)


if __name__ == "__main__":
    main()
