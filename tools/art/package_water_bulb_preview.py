"""Package Blender-rendered bulb frames into review GIFs and a contact sheet."""
import json
import struct
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'ArtSource/BlueBiome/Blender/WaterBulb'
BG=(13,28,43)
INK=(222,237,241)
MUTED=(142,183,195)
FONT=Path('C:/Windows/Fonts/segoeui.ttf')
BOLD=Path('C:/Windows/Fonts/seguisb.ttf')

def font(size,bold=False):
    return ImageFont.truetype(str(BOLD if bold else FONT),size)

def composite(im):
    bg=Image.new('RGBA',im.size,(*BG,255))
    return Image.alpha_composite(bg,im.convert('RGBA')).convert('RGB')

frames=[]
for n in range(1,73):
    path=OUT/'frames'/f'{n:03d}.png'
    with Image.open(path) as im:
        assert im.size==(360,480), (path, im.size)
        frames.append(composite(im))

palette_board=Image.new('RGB',(1080,480),BG)
for i,idx in enumerate([0,30,57]):
    palette_board.paste(frames[idx],(i*360,0))
palette=palette_board.quantize(colors=256)
indexed=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]

def save_gif(name,indices):
    values=[indexed[i] for i in indices]
    durations=[round((i+1)*100/24)*10-round(i*100/24)*10 for i in range(len(values))]
    values[0].save(OUT/name,save_all=True,append_images=values[1:],duration=durations,loop=0,disposal=2,optimize=False)

save_gif('water_bulb_rushing_loop.gif',list(range(24)))
save_gif('water_bulb_pop_refill.gif',list(range(24))*2+list(range(24,72)))

board=Image.new('RGB',(1600,1000),BG)
draw=ImageDraw.Draw(board)
draw.text((60,34),'HANGING BELL  /  TRAPPED FLOWING WATER',font=font(34,True),fill=INK)
draw.text((60,83),'3D asset study  •  Still flower. Restless water.',font=font(22),fill=MUTED)
with Image.open(OUT/'water_bulb_hero.png') as hero:
    hero=composite(hero).resize((570,760),Image.Resampling.LANCZOS)
board.paste(hero,(22,137))
draw.text((70,908),'EDITABLE BLENDER SOURCE + ANIMATED GLB',font=font(17,True),fill=MUTED)

for i,(idx,title,detail) in enumerate([
    (8,'01  RUSH','Fast circulating ribbons and carried bubbles'),
    (31,'02  RELEASE','Pressure burst, droplets, empty flower'),
    (56,'03  REFILL','Water grows back while already moving')]):
    x=600+i*325
    panel=frames[idx].resize((300,400),Image.Resampling.LANCZOS)
    board.paste(panel,(x,210))
    draw.text((x+10,164),title,font=font(23,True),fill=INK)
    # Two short lines keep the concept readable without tiny annotations.
    words=detail.split(); line=''; y=629
    for word in words:
        test=(line+' '+word).strip()
        if draw.textlength(test,font=font(18))>295:
            draw.text((x+10,y),line,font=font(18),fill=MUTED); y+=27; line=word
        else: line=test
    draw.text((x+10,y),line,font=font(18),fill=MUTED)

draw.line((610,732,1540,732),fill=(41,72,88),width=2)
draw.text((620,768),'READY FOR LOOK + MOTION REVIEW',font=font(23,True),fill=INK)
draw.text((620,811),'Separate stem, petals, membrane, current and splash parts.',font=font(20),fill=MUTED)
draw.text((620,844),'24 fps • seamless rush loop • pop / spent / refill timeline',font=font(20),fill=MUTED)
draw.text((620,877),'Model prototype; game material / performance pass still needed.',font=font(19),fill=MUTED)
board.save(OUT/'water_bulb_review.png')

# Verify the portable export contains geometry and animated node channels.
data=(OUT/'WaterBulb_HangingBell_v1.glb').read_bytes()
assert data[:4]==b'glTF'
size,kind=struct.unpack_from('<II',data,12)
assert kind==0x4e4f534a
gltf=json.loads(data[20:20+size])
triangles=sum(gltf['accessors'][p['indices']]['count']//3 for mesh in gltf['meshes'] for p in mesh['primitives'] if 'indices' in p)
report={'rendered_frames':len(frames),'glb_meshes':len(gltf['meshes']),
        'glb_triangles':triangles,'glb_animations':len(gltf.get('animations',[])),
        'animation_channels':sum(len(a['channels']) for a in gltf.get('animations',[]))}
assert report['glb_animations']==1
assert report['animation_channels']>10
(OUT/'verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
