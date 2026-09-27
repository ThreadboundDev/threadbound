from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, shutil

root = Path(__file__).resolve().parent
out = root / 'images'
out.mkdir(exist_ok=True)
inventory = json.loads((root/'review/inventory.json').read_text())
choices = [
 (103, '01-chamber-context', 'Chamber presentation, August 16. Context image; not proof of the exact public demo build.'),
 (57, '02-flow-july', 'Earlier sprite-era Flow treatment, July 31. Historical image, not the current 3D-player effect.'),
 (88, '03-inventory-august', 'Inventory interface, August 15. Release-window UX context.'),
 (126, '04-blue-rooftops', 'Blue-region house and rooftop art study, August 27.'),
 (128, '05-environment-study', 'Environment art study, August 28. Do not label as a finished playable region.'),
 (163, '06-hybrid-village', 'Painted houses, platforms and water bulbs in the village composition test, September 22.'),
 (154, '07-equipped-model', 'Equipped 3D character close-up, September 5. Work in progress.'),
 (168, '08-manual-animation', 'Manual aerial-animation workspace in Blender, September 25.'),
]
manifest=[]
for idx,name,caption in choices:
    source=Path(inventory[idx]['source'])
    dest=out/(name+'.png')
    shutil.copy2(source,dest)
    manifest.append({'file':dest.name,'source':str(source),'caption':caption,'processing':'Unaltered copy'})
for source,name,caption in [
 (root/'review/video_sep26/review_02.png','09-current-lake-gameplay','Current lake prototype, sampled around 9.97 seconds from the September 26 09:10:50 recording. Greybox geometry is intentional.'),
 (root/'review/video_sep14/review_06.png','10-earlier-combat-prototype','Earlier live-3D combat test, around 44.55 seconds from the September 14 11:20:11 recording. This predates the latest aerial-attack fixes.'),
]:
    dest=out/(name+'.png'); shutil.copy2(source,dest)
    manifest.append({'file':dest.name,'source':str(source),'caption':caption,'processing':'Video frame extracted at half resolution (1280 x 720); full desktop frame retained'})
(root/'media_manifest.json').write_text(json.dumps(manifest,indent=2))
sheet=Image.new('RGB',(1200,1250),'#20242c'); d=ImageDraw.Draw(sheet)
for i,item in enumerate(manifest):
    im=Image.open(out/item['file']).convert('RGB'); thumb=ImageOps.contain(im,(590,215))
    x,y=(i%2)*600,(i//2)*250
    sheet.paste(thumb,(x,y)); d.text((x+5,y+220),item['file'],fill='white')
sheet.save(root/'selected-images.jpg',quality=90)
print(f'{len(manifest)} selected images copied; originals untouched')
