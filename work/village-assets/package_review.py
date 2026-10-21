"""Package model documentation and an unretouched render contact sheet."""
import json, shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT=ROOT/'outputs/lakeside-buildings-v1'
manifest=json.loads((OUT/'asset_manifest.json').read_text())
for filename in ['build_lakeside.py','render_lakeside.py','verify_blend.py','verify_glbs.py','mesh_helpers.py','package_review.py']:
    shutil.copy2(Path(__file__).parent/filename,OUT/'source'/filename)

rows=[]
for key,label in [('CoveredBoatSlip','Covered boat slip'),('NetWorkshop','Net workshop'),('FishersHouse','Fisher house')]:
    st=manifest['assets'][key]['exterior'];d=st['dimensions_gameplay_px']
    rows.append(f"| {label} | {d[0]:.0f} × {d[2]:.0f} × {d[1]:.0f} px | {st['triangles']:,} |")
readme='''# Lakeside buildings · first model pass

Three newly authored models based on the approved B houses and C covered boat
slip. All seven materials are appended directly from the approved tower's v3
Blender file: walnut, plaster, blue_tiles, slate, rope, iron and recess. Their
shader graphs and packed image bytes match the tower exactly.

## Open for review

Open **LakesideBuildings_Editable.blend** in Blender 5.2 or newer.
The scene dropdown has:

- **00 · All three assets** — an overview with collection instances.
- **01 · Covered boat slip** — the open shelter, editable at the origin.
- **02 · Net workshop** — the wide, low house from concept B.
- **03 · Fisher house** — the compact, taller house from concept B.

For a house cutaway, hide the collection whose name ends in
**02_Facade_Removable**, including its children. The front wall, attached wall
net, and central roof hide together. The curved left/right roof corners stay
with the side walls. Fixed roof pieces stop inside the wall thickness and
remain outside the room opening. Both house variants include a basic interior;
the taller house has a small rear loft and ladder.

The shelter has four timber posts, stone feet, narrow side deck fingers, and a
high hanging net. Its lower center is open, with no slab across the passage.

## Scale

**128 gameplay pixels per Blender unit**, matching the existing tower.
Each root is at horizontal center and the lowest solid foot is at Z=0.
The front faces -Y; Z is up; X runs across the gameplay view. GLB exports use
the standard Y-up coordinate conversion.

These are proposed small-building proportions for review, since their own
pixel dimensions were not specified. Bounds include eaves, steps and props.

| Asset | Width × height × depth | Exterior triangles |
|---|---:|---:|
'''+ '\n'.join(rows)+'''

The overview displays all three at the same scale. The separate detail cards
are fitted to their panels. Exact bounds and cutaway counts are recorded in
asset_manifest.json.

## Files for the engine

- models/CoveredBoatSlip.glb
- models/NetWorkshop_Exterior.glb
- models/NetWorkshop_Cutaway.glb
- models/FishersHouse_Exterior.glb
- models/FishersHouse_Cutaway.glb

Use one version of each house per instance. Every GLB embeds its maps, UVs,
normals and tangents. The Blender file packs the original tower's 4096 PNG
color, normal and roughness maps. GLBs use that tower's existing runtime set:
4096 JPEG color plus 2048 PNG normal and roughness maps. All models share the
same material identities and texture artwork; the texture enlargement and
surface detail are inherited from the tower set.

Scene placement, collision, runtime facade switching, terrain connections and
water are engine-side work. This review package creates new files only; the
existing tower, level scenes and production assets are untouched. The
.gdignore keeps this review folder from being imported into Godot as a level
dependency. Copy a chosen GLB to the project's asset location when integrating.

## Previews and checks

previews/review-sheet.png combines actual Blender renders. Individual
exterior, cutaway and straight-front views are in previews/. No painted detail
has been added to the renders. The approved concept images and blockout are
included in references/.

- blend_verification.json: reloaded packed textures, exact source shader and
  image match, and clear lower passage probes in the slip.
- glb_verification.json: all five payloads parsed independently; embedded
  texture dimensions, source-matched bounds/counts, UVs, normals, tangents,
  absent cutaway facades and fixed-side roof clearance checked.
- asset_manifest.json: scale, material hashes, model bounds, triangle counts
  and roof split area/clearance checks.

Build and verification scripts are in source/. Run the build script from its
repository copy with Blender in background mode. It locates project.godot in
its parents and reads the tower v3 material library plus v1 runtime maps.
The delivered .blend and GLBs are portable and need no build scripts to open.
'''
(OUT/'README.md').write_text(readme,encoding='utf-8')

def font(size,bold=False):
    path=Path('C:/Windows/Fonts')/('segoeuib.ttf' if bold else 'segoeui.ttf')
    return ImageFont.truetype(str(path),size)
def fit_image(canvas,path,rect):
    pic=Image.open(path).convert('RGBA');box=pic.getchannel('A').getbbox()
    if box:pic=pic.crop(box)
    x,y,w,h=rect;pic.thumbnail((int(w),int(h)),Image.Resampling.LANCZOS)
    canvas.alpha_composite(pic,(int(x+(w-pic.width)/2),int(y+(h-pic.height)/2)))

canvas=Image.new('RGBA',(2400,1940),'#e4e8e8');draw=ImageDraw.Draw(canvas)
draw.text((74,48),'LAKESIDE BUILDINGS',fill='#26343b',font=font(55,True))
draw.text((78,118),'Tower materials · boat slip + two houses · model review',fill='#56676e',font=font(29))
draw.rounded_rectangle((50,186,2350,1030),radius=22,fill='#f2f3f1')
draw.text((82,208),'EXTERIORS  /  SAME SCALE',fill='#435a65',font=font(27,True))
fit_image(canvas,OUT/'previews/overview.png',(80,260,2240,685))
for label,x in [('COVERED BOAT SLIP',725),('NET WORKSHOP',1260),('FISHER HOUSE',1750)]:
    draw.text((x,970),label,fill='#344a55',font=font(26,True),anchor='mt')

cards=[('OPEN BOAT PASSAGE','boat_slip_front.png'),('WORKSHOP CUTAWAY','net_workshop_cutaway.png'),('HOUSE CUTAWAY','fishers_house_cutaway.png')]
for i,(label,filename) in enumerate(cards):
    x=50+i*780
    draw.rounded_rectangle((x,1070,x+740,1850),radius=20,fill='#f2f3f1')
    draw.text((x+28,1095),label,fill='#435a65',font=font(26,True))
    fit_image(canvas,OUT/'previews'/filename,(x+28,1160,684,650))
draw.text((76,1885),'128 px per unit · small-building sizes proposed for review · detail views fitted to panels',fill='#58686e',font=font(25))
canvas.convert('RGB').save(OUT/'previews/review-sheet.png',optimize=True)
print('REVIEW_PACKAGE_READY')
