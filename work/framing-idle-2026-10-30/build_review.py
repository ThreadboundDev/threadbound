"""Compare grounded poses at identical pixel scale; Pillow is required."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parent
report=json.loads((p/'render.json').read_text())
canvas=Image.new('RGB',(1000,580),'#18252d')
draw=ImageDraw.Draw(canvas)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',23)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
for i,(file,title) in enumerate([('baseline.png','Previous idle'),('upright.png','Upright idle trial')]):
    image=Image.open(p/file).convert('RGBA').crop((160,250,640,730))
    canvas.paste(image,(i*500+10,45),image)
    draw.text((i*500+15,10),title,font=font,fill='#f5efdf')
    m=report['measurements'][i]
    draw.text((i*500+15,510),f"{m['body_height_world']:.1f} world units / {m['screen_percent']:.1f}% at zoom 0.83",font=small,fill='#f5efdf')
draw.text((15,552),'Same source-pixel scale; boots aligned to the actual collision floor.',font=small,fill='#e1c793')
canvas.save(p/'upright-comparison.jpg',quality=95)
