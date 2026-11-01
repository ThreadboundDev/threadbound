"""Package genuine Blender renders at labelled scales, without image retouching."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/pale-doll-study-2026-11-01'
FONT = Path('C:/Windows/Fonts/segoeui.ttf')


def sheet(filename, rows, columns, title):
    width, height = 420, 460
    canvas = Image.new('RGB', (width*columns, 75 + height*((len(rows)+columns-1)//columns)), '#202832')
    draw = ImageDraw.Draw(canvas)
    heading = ImageFont.truetype(str(FONT), 27)
    label = ImageFont.truetype(str(FONT), 19)
    draw.text((18,20),title,font=heading,fill='#f1e8d6')
    for i,(source,text) in enumerate(rows):
        im=Image.open(WORK/source).convert('RGB')
        im.thumbnail((width,height-40))
        x=(i%columns)*width+(width-im.width)//2
        y=75+(i//columns)*height
        canvas.paste(im,(x,y))
        draw.text(((i%columns)*width+15,y+height-31),text,font=label,fill='#eee7da')
    canvas.save(WORK/filename,quality=94)


sheet('body_rest_review.jpg',[
    ('body_rest_front.png','Front | source rig rest pose'),
    ('body_rest_side.png','Side | same geometry'),
    ('body_rest_back.png','Back | same geometry'),
],3,'Pale doll | actual 3D body blockout')
sheet('pose_review.jpg',[
    ('pose_idle_4.png','Source idle_4'),
    ('pose_run_1.png','Source run_1'),
    ('pose_attack_1.png','Source attack_1'),
    ('pose_crouch_1.png','Source crouch_1'),
    ('pose_jump_1.png','Source jump_1'),
    ('pose_grapple_swinging_1.png','Source grapple_swinging_1'),
],3,'Existing animation samples | body only; no gameplay acceptance')
frames=[]
for file in sorted((WORK/'temp').glob('run_*.png')):
    frame=Image.open(file).convert('RGB')
    frames.append(frame)
report=json.loads((WORK/'source_inspection.json').read_text())
start,end=report['actions']['run_1']['frames']
duration=round(1000*(end-start)/24/len(frames))
frames[0].save(WORK/'run_body_review.gif',save_all=True,append_images=frames[1:],duration=duration,loop=0)
print('PACKAGED',len(frames),'run frames;',duration,'ms/frame; three-view and six-pose sheets')
