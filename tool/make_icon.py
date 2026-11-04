#!/usr/bin/env python3
"""Draws the launcher icon in code (flat shapes, no AI): deep blue square with "TOEFL" in white over an
amber sound wave (listening and speaking), and a ticked answer bubble in its lower right. Writes Android mipmaps, the Play icon and site images.

  python3 tool/make_icon.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
NAVY = (26, 76, 139)  # deep blue, the app's seed colour
AMBER = (227, 154, 28)
WHITE = (255, 255, 255)


def draw(size, rounded):
    s = 4 * size  # supersample for smooth edges
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=NAVY)
    else:
        d.rectangle([0, 0, s, s], fill=NAVY)
    from PIL import ImageFont
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(s * 0.235))
    box = d.textbbox((0, 0), "TOEFL", font=font)
    tx = (s - (box[2] - box[0])) / 2 - box[0]
    d.text((tx, s * 0.22 - box[1]), "TOEFL", font=font, fill=WHITE)
    # Sound wave: five amber bars of different heights.
    bar = s * 0.05
    for i, h in enumerate([0.07, 0.14, 0.2, 0.11, 0.06]):
        x = s * 0.15 + i * bar * 1.7
        d.rounded_rectangle([x, s * 0.66 - s * h / 2, x + bar, s * 0.66 + s * h / 2], radius=int(bar / 2), fill=AMBER)
    r = s * 0.16
    bx, by = s * 0.74, s * 0.74
    d.ellipse([bx - r - s * 0.025, by - r - s * 0.025, bx + r + s * 0.025, by + r + s * 0.025], fill=NAVY)
    d.ellipse([bx - r, by - r, bx + r, by + r], fill=AMBER)
    w = int(s * 0.04)
    d.line([(bx - r * 0.5, by + r * 0.02), (bx - r * 0.12, by + r * 0.42), (bx + r * 0.55, by - r * 0.4)], fill=WHITE, width=w, joint="curve")
    return img.resize((size, size), Image.LANCZOS)


def main():
    res = ROOT / "android/app/src/main/res"
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        draw(px, rounded=True).save(res / f"mipmap-{folder}" / "ic_launcher.png")
    draw(512, rounded=False).convert("RGB").save(ROOT / "store-assets/icon-512.png")
    img = ROOT / "website/img"
    img.mkdir(exist_ok=True)
    draw(192, rounded=True).save(img / "icon.png")
    draw(48, rounded=True).save(img / "favicon.png")
    # Feature graphic: icon plus title.
    from PIL import ImageFont
    fg = Image.new("RGB", (1024, 500), NAVY)
    icon = draw(240, rounded=True)
    fg.paste(icon, (70, 130), icon)
    d = ImageDraw.Draw(fg)
    bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 54)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 30)
    d.text((350, 160), "Prep Simulator", font=bold, fill=WHITE)
    d.text((350, 224), "for TOEFL", font=bold, fill=WHITE)
    d.text((350, 305), "20 adaptive iBT mock tests · lessons · practice", font=small, fill=(240, 220, 170))
    fg.save(ROOT / "store-assets/feature-graphic.png")
    print("icons written")


main()
