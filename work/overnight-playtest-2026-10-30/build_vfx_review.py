from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parent
keys=['up_1','down_1','spin_land','neutral_land','spin_water','neutral_water','up_-1','down_-1','grapple']
out=Image.new('RGB',(1440,1470),'#17252f');d=ImageDraw.Draw(out)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for i,key in enumerate(keys):
    im=Image.open(p/('vfx_'+key+'.png')).convert('RGB').crop((650,250,1270,900))
    im.thumbnail((470,450));x=(i%3)*480;y=(i//3)*490
    out.paste(im,(x+5,y+33));d.text((x+10,y+6),key,font=font,fill='white')
out.save(p/'vfx-family-review.jpg',quality=94)
