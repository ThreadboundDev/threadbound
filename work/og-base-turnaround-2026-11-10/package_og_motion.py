from pathlib import Path
from collections import Counter
import json
import math
from PIL import Image, ImageChops

out = Path('LocalOnly/OG_Material_Review')
records = json.loads((out/'motion_manifest.json').read_text())
radius = 8
canvas = (900,1200)
boxes = []
for row in records:
    with Image.open(out/'motion_frames'/row['file']) as im:
        assert im.size == canvas and im.mode == 'RGBA'
        bounds = im.getchannel('A').getbbox()
        assert bounds is not None
        assert min(bounds[0],bounds[1],canvas[0]-bounds[2],canvas[1]-bounds[3]) > radius
        boxes.append(bounds)
padding = radius+2
crop = (min(b[0] for b in boxes)-padding, min(b[1] for b in boxes)-padding,
        max(b[2] for b in boxes)+padding, max(b[3] for b in boxes)+padding)
width,height = crop[2]-crop[0],crop[3]-crop[1]
columns = 4
for clip,count in Counter(r['clip'] for r in records).items():
    atlas = Image.new('RGBA',(width*columns,height*math.ceil(count/columns)))
    for index,row in enumerate(r for r in records if r['clip']==clip):
        with Image.open(out/'motion_frames'/row['file']) as source:
            sprite = source.crop(crop)
        alpha = sprite.getchannel('A')
        grown = alpha.copy()
        for dy in range(-radius,radius+1):
            for dx in range(-radius,radius+1):
                if dx*dx+dy*dy <= radius*radius:
                    grown = ImageChops.lighter(grown,ImageChops.offset(alpha,dx,dy))
        ink = Image.new('RGBA',sprite.size,(5,5,7,0))
        ink.putalpha(grown)
        sprite = Image.alpha_composite(ink,sprite)
        x,y = index%columns*width,index//columns*height
        atlas.paste(sprite,(x,y))
        row['region'] = [x,y,width,height]
    atlas.save(out/f'OG_{clip}_atlas.png')
    with Image.open(out/f'OG_{clip}_atlas.png') as image:
        image.verify()
offset = [(crop[0]+width/2)-canvas[0]/2,(crop[1]+height/2)-(canvas[1]/2+1.07*canvas[1]/2.8)]
report = {'frames':records,'source_canvas':canvas,'shared_crop':crop,'offset':offset,
          'outline_source_px':radius,'game_scale':.25,'clipped_frames':0}
(out/'og_baked_manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Native-resolution frames packed:',Counter(r['clip'] for r in records), 'crop',crop)
