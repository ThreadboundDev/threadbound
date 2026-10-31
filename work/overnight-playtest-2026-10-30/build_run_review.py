"""Compare source poses and projected sword-arm presentation; enlarged review."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',23)
out=Image.new('RGB',(1400,800),'#18252d');d=ImageDraw.Draw(out)
for i in range(2):
    d.text((15,8+i*400),['Accepted upright run, previous arm','Same upright run, readable sword-arm motion'][i],font=font,fill='white')
    for j,frame in enumerate([0,5,10,15]):
        im=Image.open(p/f'run_{i}_{frame:02}.png').convert('RGBA').crop((200,230,700,730))
        im.thumbnail((340,340));out.paste(im,(j*350,45+i*400),im)
out.save(p/'run-arm-comparison.jpg',quality=94)
frames=[]
for sample in range(0,44,4):
    frame=Image.new('RGB',(1000,550),'#18252d');draw=ImageDraw.Draw(frame)
    for i in range(2):
        im=Image.open(p/f'run-motion_{i}_{sample:02}.png').convert('RGBA').crop((200,230,700,730))
        frame.paste(im,(i*500,45),im)
        draw.text((i*500+10,10),['Previous arm','Camera-plane arm motion'][i],font=font,fill='white')
    frames.append(frame)
frames[0].save(p/'run-arm-loop.gif',save_all=True,append_images=frames[1:],duration=50,loop=0)
