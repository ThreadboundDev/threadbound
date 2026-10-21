"""Package the saved bird and unretouched native model previews for review."""
from pathlib import Path
import shutil,json,hashlib
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/loom-heron-v3'
OUT=ROOT/'outputs/loom-heron-quality-v3-2026-10-21';OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').write_text('')
fontpath=Path('C:/Windows/Fonts/segoeui.ttf')
font=ImageFont.truetype(str(fontpath),24);small=ImageFont.truetype(str(fontpath),18)
source=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v3.blend'
shutil.copy2(source,OUT/source.name)
for file in (WORK/'renders').glob('Heron_v3_*.png'):
    if 'First' not in file.name:shutil.copy2(file,OUT/file.name)

frames=[];durations=[]
def stage(i):
    return ('Flight',100) if i<12 else ('Ranged aim / charge',85) if i<22 else ('Needle release',70) if i<27 else ('Low recovery',92)
files=sorted((WORK/'motion').glob('*.png'))
assert len(files)==39,'Complete native motion sequence required'
for i,path in enumerate(files):
    im=Image.open(path).convert('RGB');draw=ImageDraw.Draw(im);label,duration=stage(i)
    draw.rectangle((0,0,im.width,46),fill=(29,36,43));draw.text((18,8),'LOOM HERON V3  |  '+label,font=font,fill=(222,230,233))
    frames.append(im);durations.append(duration)
palette_board=Image.new('RGB',(500,390*5))
for j,i in enumerate([0,8,18,24,35]):palette_board.paste(frames[i].resize((500,390)),(0,j*390))
palette=palette_board.quantize(colors=256)
gif=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
gif[0].save(OUT/'Heron_v3_Motion.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0,optimize=False,disposal=2)

# Labeled inspection sheet: all panels are native model renders.
sheet=Image.new('RGB',(1920,1680),(29,36,43));d=ImageDraw.Draw(sheet)
d.text((28,16),'LOOM HERON V3 — SAVED MODEL / SOURCE ANIMATION POSES',font=font,fill=(226,234,237))
for k,i in enumerate([0,3,8,12,18,21,24,30,38]):
    im=frames[i].resize((640,500),Image.Resampling.LANCZOS);x=(k%3)*640;y=60+(k//3)*540
    sheet.paste(im,(x,y));d.text((x+18,y+504),stage(i)[0],font=small,fill=(205,219,225))
sheet.save(OUT/'Heron_v3_Pose_Review.png')

readme='''# Loom Heron V3 — bird-only craft rebuild

Open **LoomHeron_Woven_v3.blend**. Textures are packed. The saved studio camera
and lighting are included, along with 153 named editable model components.
The scene uses the existing 18-bone rig and all 11 original animation clips.
Choose a clip in the Action Editor; ranged clips are needle_aim, needle_fire,
and low_recover. Idle, flight and perch loop.

The actual Godot prefab in the Threadbound project now uses LoomHeron_v3.glb.
Its ranged behavior, 2D collision, placement and render scale are retained.

## Review files

- Heron_v3_Beauty.png: whole model.
- Heron_v3_Head_and_Craft.png: ceramic face, textile layers and braided joins.
- Heron_v3_Rear.png: wing backs and tail construction.
- Heron_v3_Perched.png and Heron_v3_Aim.png: existing rig pose checks.
- Heron_v3_Game_Camera.png: source model with the prefab's camera geometry.
- Heron_v3_Motion.gif: flight, charge, release and recovery source animation.
- Heron_v3_Pose_Review.png: selected motion frames together.

All previews are actual Blender renders of this saved model. They use Blender
lighting and are not Godot screenshots. No concept-image paintover is used.

## Verification

835 source checks, 167 actual-prefab art checks, 134 existing guardian combat
checks and 19 real-room checks passed. This verifies model data and behavior;
GPU appearance, frame time and final art acceptance still need playing.

573,520 triangles, 15 materials, 18 bones. The approved shared 4K maps are reused
with more carefully authored geometry, independent component UVs and material
variation. Older bird sources remain in the project.
'''
(OUT/'README.md').write_text(readme,encoding='utf-8')
for name in ['manifest.json','source_verification.json','godot_art_verification.json','runtime_manifest.json']:
    shutil.copy2(WORK/name,OUT/name)
hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.iterdir() if p.is_file() and p.name!='SHA256.json'}
(OUT/'SHA256.json').write_text(json.dumps(hashes,indent=2))
print('HERON_V3_PACKAGED',str(OUT),flush=True)
