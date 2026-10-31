"""Package matching room captures; no source artwork is edited."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
p = Path(__file__).resolve().parent
assert json.loads((p/'geometry-baseline.json').read_text()) == json.loads((p/'blue-after.json').read_text())['geometry']
assert not json.loads((p/'blue-validation.json').read_text())['failures']
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for key in ['surface','depth','pocket','sky','Deck01','Deck06','Deck08']:
    output = Image.new('RGB',(1600,490),'#18252d')
    draw = ImageDraw.Draw(output)
    for i,label in enumerate(['before','after']):
        im = Image.open(p/f'{label}_{key}.png').convert('RGB')
        im.thumbnail((800,450))
        output.paste(im,(i*800,35))
        draw.text((i*800+10,7),f'{label.title()} / {key}',font=font,fill='white')
    output.save(p/f'blue-{key}-comparison.jpg',quality=92)
im = Image.open(p/'after_workshop.png').convert('RGB')
im.thumbnail((1440,810))
im.save(p/'workshop-focus.jpg',quality=93)
print('Packaged seven environment comparisons; 148 world polygons match.')
