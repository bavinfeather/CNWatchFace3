"""Render the actual Monkey C path coordinates; this is not a simulator capture."""
import json
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'source/SolView.mc').read_text(encoding='utf-8')
paths = {name: json.loads(re.search(r'const '+name+r' = (\[.*?\]);', source, re.S).group(1))
         for name in ['LANDSCAPE_FAR', 'LANDSCAPE_NEAR', 'LANDSCAPE_FACE', 'LANDSCAPE_TREES']}
font_path = str(ROOT / 'assets/fonts/RobotoMono.ttf')
canvas = Image.new('RGB', (1020, 590), '#11191c')
draw = ImageDraw.Draw(canvas)
title = ImageFont.truetype(font_path, 20)
for column, (size, amoled, name) in enumerate([(454, True, 'A / AMOLED - 454 px'), (280, False, 'M / MIP - 280 px')]):
    scale = size / 280
    face = Image.new('RGB', (size, size), '#a63e32')
    d = ImageDraw.Draw(face)
    def text(x, y, value, px, color):
        font = ImageFont.truetype(font_path, round(px*scale))
        box = font.getbbox(value)
        d.text((int(x*scale), int(y*scale)-box[1]), value, font=font, fill=color)
    text(118, 23, '50%', 12, '#c7cbcb')
    text(34, 46, 'SUN.06.09', 12, '#c7cbcb')
    text(27, 69, '08:55', 54, '#f5e6d3')
    text(30, 111, 'AM', 12, '#c7cbcb')
    for row, (label, value) in enumerate([('WEEKLY RUN','0.0MI'),('ELEV. GAIN','0FT'),('BODY BATT','60'),('STRESS','30')]):
        text(28, 131+row*18, label, 16, '#c7cbcb')
        text(184, 131+row*18, value, 16, '#f5e6d3')
    for key, color in [('LANDSCAPE_FAR','#c7cbcb'), ('LANDSCAPE_NEAR','#4a6a7a'), ('LANDSCAPE_FACE','#243747'), ('LANDSCAPE_TREES','#243747')]:
        points = [(int(x*scale), int(y*scale)) for x,y in paths[key]]
        d.polygon(points, fill=color)
    mask = Image.new('L', face.size)
    ImageDraw.Draw(mask).ellipse((0,0,size-1,size-1),fill=255)
    x=column*510+(510-size)//2
    canvas.paste(face, (x,65+(454-size)//2),mask)
    draw.text((column*510+35,25),name,font=title,fill='#e4e6df')
draw.text((35,550),'SOURCE GEOMETRY PREVIEW / DEFAULT COLORS',font=title,fill='#a3afb4')
(ROOT/'previews').mkdir(exist_ok=True)
canvas.save(ROOT/'previews/geometric-landscape-preview.png')
print('Mountain source geometry rendered for AMOLED and MIP.')
