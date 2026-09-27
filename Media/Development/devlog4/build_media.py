from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json

ROOT = Path(__file__).resolve().parent
SOURCE = Path.home() / 'Pictures/Screenshots/Threadbound Screenshots'
files = sorted(p for p in SOURCE.glob('*.png') if p.name >= 'Screenshot 2026-07-23')
(ROOT / 'review').mkdir(parents=True, exist_ok=True)
inventory = []
for i, p in enumerate(files):
    inventory.append({'index': i, 'source': str(p)})
for start in range(0, len(files), 30):
    page = Image.new('RGB', (1500, 1080), '#20242c')
    draw = ImageDraw.Draw(page)
    for j, p in enumerate(files[start:start+30]):
        with Image.open(p) as im:
            thumb = ImageOps.contain(im.convert('RGB'), (294, 150))
        x, y = (j % 5)*300, (j//5)*180
        page.paste(thumb, (x, y))
        draw.text((x+3,y+151), f'{start+j}: {p.stem[11:]}', fill='white')
    page.save(ROOT / 'review' / f'screenshots_{start//30:02}.jpg', quality=88)
(ROOT / 'review' / 'inventory.json').write_text(json.dumps(inventory, indent=2))
print(f'{len(files)} screenshots indexed; {(len(files)+29)//30} review sheets')
