from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
WORK=Path(__file__).resolve().parent
source=Image.open(WORK/'rock_mask.png').getchannel('A')
report=json.loads((WORK/'rock_contours.json').read_text())
raster=Image.new('L',source.size)
draw=ImageDraw.Draw(raster)
preview=Image.open(WORK/'art_preview.png').convert('RGBA')
outline=ImageDraw.Draw(preview)
sx=preview.width/source.width;sy=preview.height/source.height
for section in report['sections']:
    points=[tuple(p) for p in section['points']]
    draw.polygon(points,fill=255)
    scaled=[(round(x*sx),round(y*sy)) for x,y in points]
    outline.line(scaled+[scaled[0]],fill=(88,255,161,220),width=1)
actual=np.asarray(raster)>0
outside=np.asarray(source.filter(ImageFilter.MaxFilter(9)))==0
inside=np.asarray(source.filter(ImageFilter.MinFilter(9)))>0
wrong_solid=np.logical_and(actual,outside)
wrong_empty=np.logical_and(~actual,inside)
stats={'polygons':len(report['sections']),'vertices':sum(len(s['points']) for s in report['sections']),'false_solid_pixels_beyond_4px':int(wrong_solid.sum()),'missed_solid_pixels_beyond_4px':int(wrong_empty.sum()),'false_solid_fraction':float(wrong_solid.mean()),'missed_solid_fraction':float(wrong_empty.mean())}
print(stats)
if wrong_solid.sum()>2000:
    ys,xs=np.where(wrong_solid); print('FALSE_SOLID_BOUNDS',int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max()))
preview.save(WORK/'rock_collision_overlay.png')
(WORK/'rock_accuracy.json').write_text(json.dumps(stats,indent=2))
assert wrong_solid.sum()<2000 and wrong_empty.sum()<2000, 'Contour holes or gaps need repair'
