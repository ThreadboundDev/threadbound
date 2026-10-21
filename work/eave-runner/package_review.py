from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,hashlib,struct,shutil,zipfile,re
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/eave-runner';OUT=ROOT/'outputs/woven-blue-guardians-2026-10-20'
SOURCE=ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner';ASSET=ROOT/'Assets/BlueBiome/Enemies/EaveRunner'
OUT.mkdir(parents=True,exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',24)
large=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',32)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',19)
report=json.loads((SOURCE/'build_report.json').read_text())
board=Image.new('RGB',(1800,1150),(28,34,39));draw=ImageDraw.Draw(board)
draw.text((28,14),'EAVE RUNNER / ACTUAL RIGGED MODEL',font=large,fill=(233,225,204))
draw.text((28,61),f"{report['triangles']:,} triangles | 60 bones | 12 clips | two short animated cloth tails",font=small,fill=(162,183,194))
idle=Image.open(WORK/'renders/idle.png').convert('RGB').resize((850,935),Image.Resampling.LANCZOS)
board.paste(idle,(20,103));draw.text((38,1051),'Blender studio render',font=font,fill=(233,225,204))
for index,(key,label) in enumerate([('wall_perch','Wall brace'),('jump_slash','Jump slash'),('land_recover','Landing recovery'),('throw_release','Throw follow-through')]):
    render=Image.open(WORK/'renders'/f'{key}.png').convert('RGB').resize((410,451),Image.Resampling.LANCZOS)
    x=900+(index%2)*440;y=103+(index//2)*500;board.paste(render,(x,y));draw.text((x+10,y+454),label,font=small,fill=(233,225,204))
draw.text((28,1113),'Model and animation art pass. Live enemy AI and combat integration are still to be done.',font=small,fill=(162,183,194))
board.save(OUT/'EaveRunner_Model_Review.png')

frames=[]
capture_record=json.loads((WORK/'godot_verification_Windows.json').read_text())
paths=[ROOT/p.removeprefix('res://') for p in capture_record['captures'] if '/motion_' in p]
for path in paths:
    full=Image.open(path).convert('RGB')
    frame=full.crop((550,0,1370,1060)).resize((492,636),Image.Resampling.LANCZOS)
    canvas=Image.new('RGB',(492,690),(28,34,39));canvas.paste(frame,(0,54));draw=ImageDraw.Draw(canvas)
    draw.text((12,13),'Eave Runner / imported Godot clips',font=small,fill=(233,225,204))
    frames.append(canvas)
atlas=Image.new('RGB',(492*5,690))
for i in range(5):atlas.paste(frames[i*(len(frames)-1)//4],(i*492,0))
palette=atlas.quantize(colors=256)
frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
durations=[100]*len(frames);durations[0]=500;durations[-1]=650
frames[0].save(OUT/'EaveRunner_Animations_Godot.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=False,disposal=2)

shutil.copy2(SOURCE/'EaveRunner_Woven_v1.blend',OUT/'EaveRunner_Woven_v1.blend')
for file in ['generation_prompts.json','build_report.json','animation_events.json']:
    shutil.copy2(SOURCE/file,OUT/file)
shutil.copy2(ROOT/'ArtSource/BlueBiome/Villagers/CC0_Source/LICENSE.ASSETS.md',OUT/'LICENSE.MakeHuman.Assets.md')
source=ROOT/'docs/art/woven_blue_guardians_v1.md';text=source.read_text(encoding='utf-8')
def portable(match):
    p=(source.parent/match.group(2)).resolve().relative_to(ROOT).as_posix()
    return match.group(1)+' (`'+p+'`)'
(OUT/'README.md').write_text(re.sub(r'\[([^\]]+)\]\(([^)]+)\)',portable,text),encoding='utf-8')

verification={key:json.loads((WORK/file).read_text()) for key,file in [('source','source_verification.json'),('headless','godot_verification_headless.json'),('Forward+','godot_verification_Windows.json')]}
assert all(r['passed'] for r in verification.values())
raw=(ASSET/'Models/EaveRunner_v1.glb').read_bytes();n=struct.unpack_from('<I',raw,12)[0];gltf=json.loads(raw[20:20+n])
triangles=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])
assert triangles==report['triangles'],(triangles,report['triangles'])
(OUT/'verification.json').write_text(json.dumps(verification,indent=2))
provenance={'tool':'Built-in image_gen__imagegen for concept/cord/ceramic images; Blender 5.2.1 authoring and Godot 4.7.2 import/render',
 'base':'CC0 MakeHuman hm08 topology and matching weights, new reduced deform rig',
 'maker':'Unspecified; visual allegiance Hermit-aligned',
 'model':{'file':'Models/EaveRunner_v1.glb','triangles':triangles,'bones':60,'sha256':hashlib.sha256(raw).hexdigest()},
 'source_sha256':hashlib.sha256((SOURCE/'EaveRunner_Woven_v1.blend').read_bytes()).hexdigest(),
 'images':[{'file':p.name,'size':list(Image.open(p).size),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted((ASSET/'Textures').glob('*.png'))],
 'concepts':[{'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [OUT/'EaveRunner_Woven_Concept.png',OUT/'Woven_Flying_Concepts.png']],
 'prompts':'generation_prompts.json'}
(OUT/'provenance.json').write_text(json.dumps(provenance,indent=2));(ASSET/'provenance.json').write_text(json.dumps(provenance,indent=2))
with zipfile.ZipFile(OUT/'EaveRunner_Godot_Asset.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in ASSET.rglob('*'):
        if p.is_file() and p.suffix not in ['.import','.uid']:archive.write(p,p.relative_to(ASSET))
    for file in ['README.md','LICENSE.MakeHuman.Assets.md','animation_events.json','generation_prompts.json']:
        archive.write(OUT/file,file)
print('EAVE_RUNNER_REVIEW_PACKAGED',len(frames),'animation frames; source/GLB triangle counts match')
