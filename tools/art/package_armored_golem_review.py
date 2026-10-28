"""Package only rendered linear review media, never the Fab model/texture sources."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/armored-golem-review-2026-10-28'
OUT=WORK/'renders'
font=lambda n,b=False:ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf' if b else 'C:/Windows/Fonts/segoeui.ttf',n)
canvas=Image.new('RGB',(1500,1040),'#101d28')
draw=ImageDraw.Draw(canvas)
draw.text((36,22),'ARMORED STONE GOLEM / SOURCE REVIEW',font=font(31,True),fill='#eee7da')
draw.text((37,69),'Downloaded skin 1 · Separate armor, body, hammer and shield · No game installation',font=font(20),fill='#acbdc7')
for x,name,file in [(24,'THREE-QUARTER VIEW','golem_three_quarter.png'),(770,'SIDE-VIEW CHECK','golem_gameplay_side.png')]:
    draw.text((x+16,120),name,font=font(20,True),fill='#deb780')
    image=Image.open(OUT/file).convert('RGB');image.thumbnail((706,750),Image.Resampling.LANCZOS)
    canvas.paste(image,(x+(706-image.width)//2,157))
draw.text((37,932),'45,704 triangles with equipment   |   90 bones   |   25 source animation FBXs',font=font(23,True),fill='#e8dfd1')
draw.text((37,979),'Fab Standard License: commercial-use candidate, not CC0. Art direction, boss role and runtime validation remain open.',font=font(18),fill='#acbdc7')
canvas.save(OUT/'golem_review.png')
frames=[Image.open(WORK/'temp'/f'attack_{index:03}.png').convert('RGB') for index in range(36)]
palette=frames[0].quantize(colors=248)
indexed=[image.quantize(palette=palette,dither=Image.Dither.NONE) for image in frames]
indexed[0].save(OUT/'golem_attack1.gif',save_all=True,append_images=indexed[1:],duration=[80,80,90]*12,loop=0,optimize=True)
qa=Image.new('RGB',(1120,1190))
for index,sample in enumerate((0,12,24,35)):qa.paste(frames[sample],((index%2)*560,(index//2)*595))
qa.save(WORK/'temp/attack_review.png')
manifest=[]
for path in sorted(OUT.iterdir()):
    manifest.append(dict(file=path.relative_to(WORK).as_posix(),bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
(WORK/'preview_manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Packaged still board and 36-frame / 3-second attack preview.')
