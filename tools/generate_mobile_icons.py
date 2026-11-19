#!/usr/bin/env python3
"""Generate offline Android/iOS icons from the existing Ministry seal."""
from pathlib import Path
from io import BytesIO
import cairosvg
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets' / 'seal.svg'
DEST = ROOT / 'assets' / 'mobile'
DEST.mkdir(parents=True, exist_ok=True)
def icon(size: int) -> Image.Image:
    canvas = Image.new('RGB', (size, size), '#17373d')
    inset = int(size * 0.13)
    seal_size = size - 2 * inset
    data = cairosvg.svg2png(url=str(SOURCE), output_width=seal_size, output_height=seal_size)
    seal = Image.open(BytesIO(data)).convert('RGBA')
    canvas.paste(seal, (inset, inset), seal)
    return canvas
icon(1024).save(DEST / 'icon_1024.png', optimize=True)
icon(192).save(DEST / 'android_icon_192.png', optimize=True)
icon(180).save(DEST / 'ios_icon_180.png', optimize=True)
icon(432).save(DEST / 'android_foreground_432.png', optimize=True)
Image.new('RGB', (432, 432), '#17373d').save(DEST / 'android_background_432.png', optimize=True)
print('Generated five platform icons')
