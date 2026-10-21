"""Package actual Blender renders and Godot captures for user review."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/lakeside-villagers'
OUT=ROOT/'outputs/lakeside-villagers-v1'
SOURCE=ROOT/'ArtSource/BlueBiome/Villagers'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').write_text('')
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',28)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',21)
board=Image.new('RGB',(1600,940),(28,34,39))
draw=ImageDraw.Draw(board)
draw.text((34,18),'LAKESIDE VILLAGERS  /  FIRST MODEL PASS',font=font,fill=(228,224,208))
for index,(key,label) in enumerate([('NetMender','Net mender + net frame'),('Boatwright','Boatwright + planing bench')]):
    render=Image.open(WORK/'renders'/f'{key}_work.png').convert('RGB').resize((760,760),Image.Resampling.LANCZOS)
    x=20+index*800
    board.paste(render,(x,68))
    draw.text((x+14,843),label,font=font,fill=(233,225,204))
draw.text((34,902),'Actual Blender geometry and materials. Work and greeting clips are included.',font=small,fill=(160,181,190))
board.save(OUT/'Villagers_Review.png')
for key in ['NetMender','Boatwright']:
    for pose in ['work','talk']:
        shutil.copy2(WORK/'renders'/f'{key}_{pose}.png',OUT/f'{key}_{pose}.png')

frames=[]
for path in sorted((WORK/'renders').glob('greeting_*.png')):
    # A fixed crop of actual rendered frames, excluding unrelated HUD controls.
    frame=Image.open(path).convert('RGB').crop((790,425,1410,950)).resize((744,630),Image.Resampling.LANCZOS)
    canvas=Image.new('RGB',(744,684),(28,34,39));canvas.paste(frame,(0,54))
    draw=ImageDraw.Draw(canvas);draw.text((18,11),'Godot: work > greet > return to work',font=small,fill=(233,225,204))
    frames.append(canvas)
if frames:
    # One global palette avoids flickering colors between frames.
    atlas=Image.new('RGB',(744*3,684))
    for index in range(3):atlas.paste(frames[index*(len(frames)-1)//2],(index*744,0))
    palette=atlas.quantize(colors=256)
    converted=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    durations=[140]*len(converted);durations[0]=500;durations[-1]=650
    converted[0].save(OUT/'Greeting_In_Game.gif',save_all=True,append_images=converted[1:],duration=durations,loop=0,optimize=False,disposal=2)

shutil.copy2(SOURCE/'LakesideVillagers_v1.blend',OUT/'LakesideVillagers_v1.blend')
shutil.copy2(ROOT/'docs/art/lakeside_villagers_v1.md',OUT/'README.md')
provenance=json.loads((ROOT/'Assets/BlueBiome/Villagers/provenance.json').read_text())
provenance['models']=[{'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted((ROOT/'Assets/BlueBiome/Villagers/Models').glob('*.glb'))]
provenance['blender_source_sha256']=hashlib.sha256((SOURCE/'LakesideVillagers_v1.blend').read_bytes()).hexdigest()
(ROOT/'Assets/BlueBiome/Villagers/provenance.json').write_text(json.dumps(provenance,indent=2))
shutil.copy2(ROOT/'Assets/BlueBiome/Villagers/provenance.json',OUT/'provenance.json')
shutil.copy2(SOURCE/'fabric_generation_prompts.json',OUT/'fabric_generation_prompts.json')
shutil.copy2(SOURCE/'CC0_Source/LICENSE.ASSETS.md',OUT/'LICENSE.MakeHuman.Assets.md')
report={}
for key,file in [('gameplay','verification_headless.json'),('rendered','verification_Windows.json'),('source','source-verification.json')]:
    report[key]=json.loads((WORK/file).read_text())
(OUT/'verification.json').write_text(json.dumps(report,indent=2))
print('VILLAGER_REVIEW_PACKAGED',OUT)
