"""Deliver packed sources, authentic background previews and validation records."""
from pathlib import Path
import json,shutil,hashlib
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/character-quality-v2';OUT=ROOT/'outputs/character-quality-v2-2026-10-20';OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').write_text('')
sources={
 'LakesideVillagers_v2.blend':'ArtSource/BlueBiome/Villagers/LakesideVillagers_v2.blend',
 'EaveRunner_Woven_v2.blend':'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v2.blend',
 'LoomHeron_Woven_v2.blend':'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v2.blend',
}
for name,path in sources.items():shutil.copy2(ROOT/path,OUT/name)
for image in (WORK/'renders').glob('*_v2_Source.png'):shutil.copy2(image,OUT/image.name)
for image in (WORK/'renders').glob('*_v2_Detail.png'):shutil.copy2(image,OUT/image.name)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',27);small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',19)
board=Image.new('RGB',(1600,1540),(29,36,43));draw=ImageDraw.Draw(board);draw.text((30,17),'THREADBOUND • CHARACTER QUALITY V2',font=font,fill=(230,235,232));draw.text((30,55),'Actual saved model previews • Blender background renders',font=small,fill=(175,191,199))
for i,(name,label) in enumerate([('NetMender','Net Mender • 153,580 triangles'),('Boatwright','Boatwright • 156,420 triangles'),('EaveRunner','Eave Runner • 264,312 triangles'),('LoomHeron','Ranged Loom Heron • 107,096 triangles')]):
    file=WORK/'renders'/(name+('_v2_Detail.png' if name!='LoomHeron' else '_v2_Source.png'))
    with Image.open(file) as original:
        pic=original.convert('RGB');pic.thumbnail((760,650),Image.Resampling.LANCZOS)
    x=20+(i%2)*800;y=100+(i//2)*710;board.paste(pic,(x+(760-pic.width)//2,y+(650-pic.height)//2));draw.text((x+12,y+660),label,font=small,fill=(229,233,226))
board.save(OUT/'Character_Quality_v2_Preview.png')
poses=[]
for p in sorted((WORK/'heron-motion').glob('*.png')):
    with Image.open(p) as source:poses.append(source.convert('RGB').quantize(colors=192))
poses[0].save(OUT/'Heron_Ranged_Pose_Preview.gif',save_all=True,append_images=poses[1:],duration=100,loop=0,disposal=2)
shutil.copy2(ROOT/'docs/art/character_quality_v2_and_ranged_heron.md',OUT/'Implementation_and_Review.md')
for file in ['final_export_report.json','runtime_manifest.json','source_verification.json','godot_art_verification.json','combat-check.log','lakeside-check.log','villager-check.log','eave-art-check.log']:
    shutil.copy2(WORK/file,OUT/file)
stats=json.loads((WORK/'final_export_report.json').read_text())
for family,kinds in [('Villagers',['NetMender','Boatwright']),('Enemies/EaveRunner',['EaveRunner']),('Enemies/LoomHeron',['LoomHeron'])]:
    report={k:stats[k] for k in kinds};(ROOT/'ArtSource/BlueBiome'/family/'quality_v2_report.json').write_text(json.dumps(report,indent=2))
shutil.copy2(WORK/'material_bake_report.json',ROOT/'ArtSource/BlueBiome/Characters/material_bake_report_v2.json')
readme='''THREADBOUND — CHARACTER QUALITY V2 / October 20, 2026

Installed in the existing Godot project. Run the lakeside Krita playtest with F6.
Use Eave Runner / Loom Heron / Net mender / Boatwright landmark buttons.
F2 restores all five enemies.

Heron now aims and fires one ceramic needle, then descends to a low vulnerable
hover. It no longer deals damage by diving or body contact. Aim locks before
release; normal shield rules, terrain blocking and hurt interruption apply.

Both villagers and both enemies have about four times their old geometry,
refined cloth/face/cord surfaces and real 4K PBR/skin maps. Source proportions,
existing rigs, NPC interactions and 2D collision remain intact. Native v1 files
remain available in the project for comparison.

The packed Blender files can be opened directly. GLBs in the project reference
shared texture folders; keep those dependencies if copying them elsewhere.

The PNG contact sheet and GIF are renders of the actual saved Blender models,
not concept art and not new in-game screenshots. Godot checks were headless;
no graphical game/editor window was launched. Test visual feel and frame rate
in your next hands-on session: higher geometry, texture and supersampling
settings increase rendering cost. Quality controls remain in the inspectors.

Implementation_and_Review.md describes source files, tuning and reproduction.
Verification reports/logs accompany this delivery. Existing engine shutdown
cleanup warnings are distinct from check failures and script errors.
'''
(OUT/'README.txt').write_text(readme)
manifest={p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in OUT.iterdir() if p.is_file() and p.name not in ['.gdignore','manifest.json']};(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('CHARACTER_V2_DELIVERED',len(manifest),'files',sum(v['bytes'] for v in manifest.values()),'bytes')
