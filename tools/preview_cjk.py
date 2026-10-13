"""Visual check for the bundled Chinese glyph subset at AMOLED and MIP scales."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = str(ROOT / 'assets/fonts/NotoSansSC.ttf')
MONO = str(ROOT / 'assets/fonts/RobotoMono.ttf')
canvas = Image.new('RGB', (820, 530), '#101719')
labels = ['跑步', '爬升', '体能', '压力']
for n, (size, name) in enumerate([(454, 'A / AMOLED'), (280, 'M / MIP')]):
    scale = size / 280
    dial = Image.new('RGB', (size, size), '#a63e32')
    d = ImageDraw.Draw(dial)
    def font(path, base):
        f = ImageFont.truetype(path, round(base * scale))
        if path == FONT: f.set_variation_by_axes([500])
        return f
    def put(x, y, text, path, base, color):
        d.text((round(x*scale), round(y*scale)), text, font=font(path, base), fill=color)
    put(34, 43, '9月6日 周日', FONT, 16, '#c7cbcb')
    put(27, 69, '09:18', MONO, 54, '#f5e6d3')
    for row, (label, value) in enumerate(zip(labels, ['0.0MI','0FT','15','22'])):
        put(28, 128+row*18, label, FONT, 16, '#c7cbcb')
        put(184, 128+row*18, value, MONO, 16, '#f5e6d3')
    mask = Image.new('L', dial.size)
    ImageDraw.Draw(mask).ellipse((0, 0, size-1, size-1), fill=255)
    x = n*410 + (410-size)//2
    canvas.paste(dial, (x, 55+(454-size)//2), mask)
    ImageDraw.Draw(canvas).text((n*410+28, 20), name, font=ImageFont.truetype(MONO, 18), fill='#e4e6df')
canvas.save(ROOT / 'previews/chinese-font-preview.png')
