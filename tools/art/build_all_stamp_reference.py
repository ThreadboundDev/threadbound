"""Assemble the three current painted stamp bundles as an editable local atlas."""
import hashlib
import io
import json
import math
import struct
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT/'ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack'
OUT = LOCAL/'all_current_stamps_2026_11_02'
BUNDLES = [
    ('Village library', LOCAL/'slate_village_library/Blue_Village_Slate_Library.bundle'),
    ('Modular buildings', ROOT/'ArtSource/BlueBiome/Placeables/BuildingStampsV1/Threadbound_Modular_Buildings_v1.bundle'),
    ('Carved cavern', ROOT/'ArtSource/Deliveries/CarvedCavernStampsV1/Threadbound_Carved_Cavern_v1.bundle'),
]

def png(im):
    buf = io.BytesIO(); im.save(buf,'PNG'); return buf.getvalue()

def build():
    OUT.mkdir(exist_ok=True)
    records, seen = [], set()
    for family, path in BUNDLES:
        with zipfile.ZipFile(path) as z:
            for name in sorted(n for n in z.namelist() if n.endswith('.gbr')):
                data = z.read(name)
                header, version, w, h, channels, magic, spacing = struct.unpack('>7I',data[:28])
                assert version == 2 and channels == 4 and magic == 0x47494D50
                pixels = data[header:]
                assert len(pixels) == w*h*4
                digest = hashlib.sha256(struct.pack('>II',w,h)+pixels).hexdigest()
                if digest in seen: continue
                seen.add(digest)
                records.append((family,Path(name).stem,Image.frombytes('RGBA',(w,h),pixels),path,name,digest))
    width, cellw, cellh = 3000, 600, 400
    height = 100+math.ceil(len(records)/5)*cellh
    bg = Image.new('RGBA',(width,height),'#29434f')
    labels = Image.new('RGBA',(width,height))
    draw = ImageDraw.Draw(labels)
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
    draw.text((25,20),f'THREADBOUND — ALL CURRENT STAMPS — {len(records)} unique pieces',font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',34),fill='white')
    draw.text((25,63),'Each stamp is a separate layer. Brushes retain original resolution; this sheet fits art into cells.',font=font,fill='#bdd5dd')
    layers=[('00 Background - hide for transparency',bg,0,0)]
    manifest=[]
    for i,(family,name,im,bundle,resource,digest) in enumerate(records):
        x,y=(i%5)*cellw,100+(i//5)*cellh
        box=im.getchannel('A').point(lambda a:255 if a>64 else 0).getbbox()
        pic=im.crop(box); pic.thumbnail((560,315),Image.Resampling.LANCZOS)
        px,py=x+(600-pic.width)//2,y+12+(315-pic.height)//2
        layers.append((family+' / '+name,pic,px,py))
        draw.rectangle((x+8,y+4,x+592,y+392),outline='#56727e',width=2)
        draw.text((x+20,y+338),name.replace('Village_MB_','MB ').replace('Village_','').replace('Cavern_','')[:48],font=font,fill='white')
        draw.text((x+20,y+367),family,font=font,fill='#bdd5dd')
        manifest.append({'name':name,'family':family,'bundle':str(bundle.relative_to(ROOT)),'resource':resource,'rgba_sha256':digest,'original_size':list(im.size)})
    layers.append(('99 Labels and cell borders - hide for transparency',labels,0,0))
    merged=Image.new('RGBA',(width,height))
    for _,im,x,y in layers: merged.alpha_composite(im,(x,y))
    merged.convert('RGB').save(OUT/'All_Current_Stamps.jpg',quality=93)
    root=ET.Element('image',{'w':str(width),'h':str(height),'name':'Threadbound All Current Stamps','version':'0.0.3','xres':'72','yres':'72'})
    stack=ET.SubElement(root,'stack')
    with zipfile.ZipFile(OUT/'All_Current_Stamps.ora','w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,(name,im,x,y) in reversed(list(enumerate(layers))):
            src=f'data/layer{i:03}.png'
            ET.SubElement(stack,'layer',{'name':name,'src':src,'x':str(x),'y':str(y),'opacity':'1.0','visibility':'visible','composite-op':'svg:src-over'})
            z.writestr(src,png(im))
        z.writestr('stack.xml',ET.tostring(root,encoding='utf-8',xml_declaration=True))
        z.writestr('mergedimage.png',png(merged))
        thumb=merged.copy();thumb.thumbnail((256,256));z.writestr('Thumbnails/thumbnail.png',png(thumb))
    with zipfile.ZipFile(OUT/'All_Current_Stamps.ora') as z:
        assert z.testzip() is None
        check=Image.new('RGBA',(width,height))
        for layer in reversed(ET.fromstring(z.read('stack.xml')).find('stack').findall('layer')):
            check.alpha_composite(Image.open(io.BytesIO(z.read(layer.get('src')))).convert('RGBA'),(int(layer.get('x')),int(layer.get('y'))))
        assert check.tobytes()==merged.tobytes()
    (OUT/'manifest.json').write_text(json.dumps({'unique_stamps':len(records),'layers':len(layers),'validation':'GBR sizes, duplicate pixel hashes, ZIP integrity and independent layer recomposition passed','assets':manifest},indent=2)+'\n')
    print(f'{len(records)} unique stamps; {len(layers)} layers; saved {OUT}')

if __name__=='__main__': build()
