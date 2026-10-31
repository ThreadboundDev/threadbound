import hashlib,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parent
old=p.parent/'gameplay-review-followup-2026-10-30'
before=json.loads((old/'geometry-baseline.json').read_text(encoding='utf-8'))
after=json.loads((p/'blue-after.json').read_text(encoding='utf-8'))['geometry']
assert before==after
digest=hashlib.sha256(json.dumps(after,sort_keys=True,separators=(',',':')).encode()).hexdigest()
(p/'bridge-geometry-audit.json').write_text(json.dumps({'world_polygons':len(after),'identical':True,'canonical_geometry_sha256':digest,'baseline':'work/gameplay-review-followup-2026-10-30/geometry-baseline.json'},indent=2)+'\n',encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for key in ['Deck01','Deck06','Deck08']:
    out=Image.new('RGB',(1600,490),'#17252f');d=ImageDraw.Draw(out)
    for i,(source,title) in enumerate([(old,'Previous simple rails'),(p,'Modular approved stamp parts')]):
        im=Image.open(source/f'after_{key}.png').convert('RGB');im.thumbnail((800,450))
        out.paste(im,(i*800,35));d.text((i*800+10,7),title,font=font,fill='white')
    out.save(p/f'modular-{key}-comparison.jpg',quality=93)
print('148 world collision polygons match; three modular bridge comparisons built.')
