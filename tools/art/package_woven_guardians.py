"""Package actual model sources and already-captured engine frames for review."""
from pathlib import Path
import json, hashlib, shutil, zipfile
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'outputs/woven-guardians-playable-2026-10-20';OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').write_text('')
frames=ROOT/'work/woven-guardians/renders'
for actor,crop in [('Eave',(740,280,1400,790)),('Heron',(820,260,1550,750))]:
    images=[]
    for file in sorted(frames.glob(actor+'_*.png')):
        with Image.open(file) as im:
            images.append(im.crop(crop).convert('RGB').quantize(colors=192))
    if images:images[0].save(OUT/(actor+'_In_Game.gif'),save_all=True,append_images=images[1:],duration=100,loop=0,disposal=2)
shutil.copy2(frames/'Eave_014.png',OUT/'EaveRunner_In_Game.png')
shutil.copy2(frames/'Heron_019.png',OUT/'LoomHeron_In_Game.png')
shutil.copy2(ROOT/'work/loom-heron/renders/LoomHeron_Model.png',OUT/'LoomHeron_Model.png')
for name in ['EaveRunner','LoomHeron']:
    shutil.copy2(ROOT/f'ArtSource/BlueBiome/Enemies/{name}/{name}_Woven_v1.blend',OUT/f'{name}_Woven_v1.blend')
concept=ROOT/'outputs/woven-blue-guardians-2026-10-20/Woven_Flying_Concepts.png'
source=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron'
provenance={
    'model':'Original script-authored cloth/reed/cord bird based on approved Loom Heron concept A',
    'builder':'tools/art/build_loom_heron.py',
    'concept_reference':str(concept.relative_to(ROOT)),
    'concept_sha256':hashlib.sha256(concept.read_bytes()).hexdigest(),
    'textures':'Reused village PBR maps and Eave Runner cord/ceramic color maps. Original generation prompts/provenance are recorded beside EaveRunner source.',
    'rig':'17 deform bones; in-place clips; forward -Y Blender / +Z Godot',
    'new_image_generation':False,
}
(source/'asset_provenance.json').write_text(json.dumps(provenance,indent=2))
readme='''WOVEN GUARDIANS — PLAYABLE REVIEW / October 20, 2026

Both enemies are installed in the existing Threadbound project.
Run this scene with F6:
C:/Users/chase/Documents/threadbound/Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn

Use the bottom Eave Runner / Loom Heron buttons to visit each encounter.
F2 respawns all five enemies. Normal attack, dodge and shield controls apply.

Eave Runner: tower guardian; real wall brace/climb, locked leap/blade sweep,
landing recovery, and a straight throwing pin when walls are unavailable.
Loom Heron: cloth-wing flyer by the boat slip; tell, committed diagonal dive,
low vulnerable brake recovery, reposition. Perch animation is included in the
model; the placed instance patrols in flight rather than landing on perches.

Both Blender files include packed textures, deform bones and named animation
Actions. Eave Runner has 60 bones and 12 clips. Heron has 17 bones and 8 clips.
The GLBs use external texture folders; keep Models and Textures together.

Woven_Guardians_Runtime.zip contains project-relative new enemy assets/scripts
and prefab scenes, plus the small EnemyBase death/reset timer fix. It is a
backup/import package for the existing project, not a standalone Godot game.
The existing project components remain required.
The current map already contains the placed enemies; the zip need not be imported.

The PNGs and GIFs marked In_Game are actual Forward+ Godot captures, cropped
for the GIFs. They show the real map, player, materials and skeletal animations.
The still marked Model is a Blender studio render of the saved heron mesh.
No screenshot is a substitute for the in-game models.

Validation: 106 saved-heron-source checks; 80 isolated combat checks; 19
headless checks on the real map/player; 97 rendered checks / 80 captured frames.
Rendered captures precede the final wall-search range improvement; the final
headless run also verifies returning to another wall and repeated leaps.
Existing engine shutdown resource/texture diagnostics appear in the rendering
log; no gameplay/source check failures or script errors remain.

This is the first playable tuning pass; Chase's hands-on feel/art review remains.
Full implementation notes are included as Gameplay_Notes.md.
'''
(OUT/'README.txt').write_text(readme)
shutil.copy2(ROOT/'docs/art/woven_guardians_gameplay_v1.md',OUT/'Gameplay_Notes.md')
shutil.copy2(ROOT/'work/loom-heron/source_verification.json',OUT/'Heron_Source_Verification.json')
for filename in ['verify-woven.log','verify-woven-lakeside.log','verify-woven-lakeside-render.log']:
    shutil.copy2(ROOT/'work'/filename,OUT/filename)
folders=['Assets/BlueBiome/Enemies/EaveRunner','Assets/BlueBiome/Enemies/LoomHeron','Src/Enemies/EaveRunner','Src/Enemies/LoomHeron','Src/Enemies/WovenGuardians','Src/Enemies/EnemyBase']
with zipfile.ZipFile(OUT/'Woven_Guardians_Runtime.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for folder in folders:
        for file in sorted((ROOT/folder).rglob('*')):
            if file.is_file():archive.write(file,file.relative_to(ROOT))
    archive.writestr('WOVEN_GUARDIANS_README.txt',readme)
manifest={file.name:{'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()} for file in OUT.iterdir() if file.is_file() and file.name not in ['.gdignore','manifest.json']}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps({k:v['bytes'] for k,v in manifest.items()},indent=2))
