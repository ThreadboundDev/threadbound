"""Package before/after GPU captures; requires Pillow."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
for shot,title,note in [
    ('floating','Waterline landings','Four reusable pontoon bridges; existing collision surfaces retained.'),
    ('high','Higher landings','Five braced assets; endpoints lie inside actual rock or tower collision.'),
    ('underwater_1','Independent underwater rock','Rock scrolls at 65% horizontally / 85% vertically; timber remains world-locked.')]:
    out=Image.new('RGB',(1200,455),'#17242d')
    draw=ImageDraw.Draw(out)
    for i,mode in enumerate(['before','after']):
        im=Image.open(p/f'{mode}_{shot}.png').convert('RGB').resize((600,338),Image.Resampling.LANCZOS)
        out.paste(im,(i*600,36))
        draw.text((i*600+12,7),'BEFORE' if i==0 else 'AFTER',font=font,fill='#f2ecdf')
    draw.text((12,383),title,font=font,fill='#f2ecdf')
    draw.text((12,416),note,font=small,fill='#dfc58c')
    out.save(p/f'{shot}-comparison.jpg',quality=94)
im=Image.open(p/'asset-review.png').convert('RGB')
im.resize((1200,675),Image.Resampling.LANCZOS).save(p/'reusable-assets.jpg',quality=94)
before=json.loads((p/'before.json').read_text())
after=json.loads((p/'after.json').read_text())
assert before['collision']==after['collision'],'Existing collision changed'
v=json.loads((p/'validation.json').read_text())
assert not v['failures'] and v['checks']==70
print('Packaged three GPU comparisons; nine collision polygons unchanged; 70 checks pass.')
