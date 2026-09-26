"""Check framing and create a comparison from actual Blender renders."""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageChops

ROOT = Path(__file__).resolve().parents[2]
base = ROOT / 'Assets/BlueBiome/StillVillage'
variant = 'MaterialV3' if '--house-study' in sys.argv else 'MaterialV2'
out = ROOT / 'ArtSource/BlueBiome/Blender/StillVillage' / variant
manifest = json.loads((base/'kit_manifest.json').read_text())
report = []
for item in manifest:
    a = Image.open(ROOT/item['texture']).convert('RGBA')
    b = Image.open(base/variant/item['kind']/(item['id']+'.png')).convert('RGBA')
    assert a.size == b.size == tuple(item['canvas']), item['id']
    assert ImageChops.difference(a.getchannel('A'), b.getchannel('A')).getbbox() is None, item['id']
    assert ImageChops.difference(a.convert('RGB'),b.convert('RGB')).getbbox(), item['id']
    report.append({'asset':item['id'],'identical_alpha_and_dimensions':True,'material_changed':True})
sheet = Image.new('RGB',(1400,1600),'#172b3b')
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',26)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
d.text((35,24),'STILL VILLAGE — MATERIAL STUDY',font=font,fill='white')
d.text((35,67),'Same 3D models / same lighting / same camera',font=small,fill='#a9bcc8')
d.text((270,110),'FIRST PASS',font=font,fill='white')
d.text((950,110),variant.upper(),font=font,fill='white')
for i,asset in enumerate(['timber_deck','support_post','stone_cap_long','stopped_waterwheel','cloth_awning']):
    entry = next(e for e in manifest if e['id']==asset)
    y = 170+i*282
    d.text((35,y),asset.replace('_',' ').upper(),font=small,fill='#a9bcc8')
    for col,path in enumerate([ROOT/entry['texture'],base/variant/entry['kind']/(asset+'.png')]):
        im = Image.open(path).convert('RGBA'); im=im.crop(im.getbbox())
        im.thumbnail((620,235))
        sheet.paste(im,(35+col*700+(620-im.width)//2,y+30+(235-im.height)//2),im)
sheet.save(out/'material_comparison.png')
(out/'verification.json').write_text(json.dumps(report,indent=2))
print('PASS: all 12 renders retain identical alpha and dimensions; material pixels changed.')
