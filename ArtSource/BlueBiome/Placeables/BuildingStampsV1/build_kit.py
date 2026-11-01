"""Package original imagegen art and byte-identical library sources for Krita.

Source PNG pixels are never repainted/recolored. Pillow only converts formats,
lays out contact sheets and assembles the separate native document layers.
"""
import copy
import hashlib
import io
import json
import math
import struct
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, PngImagePlugin

KIT = Path(__file__).resolve().parent
FONT_PATH = 'C:/Windows/Fonts/arial.ttf'
MANIFEST_NS = 'urn:oasis:names:tc:opendocument:xmlns:manifest:1.0'
META_NS = 'urn:oasis:names:tc:opendocument:xmlns:meta:1.0'
DC_NS = 'http://purl.org/dc/elements/1.1/'
ET.register_namespace('manifest', MANIFEST_NS)
ET.register_namespace('meta', META_NS)
ET.register_namespace('dc', DC_NS)

def png_bytes(im, info=None):
    output = io.BytesIO()
    im.save(output, format='PNG', pnginfo=info)
    return output.getvalue()

def content_box(im):
    # Framing only: ignore tiny isolated alpha specks when fitting a thumbnail.
    alpha = im.getchannel('A')
    return alpha.point(lambda x: 255 if x > 64 else 0).getbbox() or (0, 0, *im.size)

def fit_picture(im, size):
    im = im.crop(content_box(im))
    im.thumbnail(size, Image.Resampling.LANCZOS)
    return im

def family(stem, generated):
    if generated:
        return {'W':'Walls', 'B':'Timber', 'N':'Windows', 'D':'Doors', 'R':'Roofs'}[stem[0]]
    if stem.startswith('LT'): return 'Lights'
    if stem.startswith(('L','Q')): return 'Stone'
    if stem.startswith('R'): return 'Roofs'
    if stem.startswith('D'): return 'Supports'
    if stem.startswith(('A','B')) or stem.startswith('J03'): return 'Walkways'
    return 'Building bays'

def default_size(stem, generated):
    if generated:
        return {'W':512, 'B':512, 'N':192, 'D':256, 'R':512}[stem[0]]
    if stem.startswith('LT'): return 112
    return 640

def gbr(im, description, spacing):
    label = description.encode('utf-8') + b'\0'
    header = struct.pack('>7I', 28+len(label), 2, *im.size, 4, 0x47494D50, spacing)
    return header + label + im.tobytes()

def new_preset(entry, brush_data, im):
    root = ET.fromstring((KIT/'preset_template.xml').read_text(encoding='utf-8'))
    root.set('name', 'Village Modular '+entry['id'].replace('_',' '))
    params = {e.get('name'):e for e in root.findall('param')}
    filename = entry['brush_file']
    brush = ET.fromstring(params['brush_definition'].text)
    brush.set('filename', filename)
    brush.set('md5sum', hashlib.md5(brush_data).hexdigest())
    brush.set('scale', str(entry['suggested_brush_size']/max(im.size)))
    brush.set('brushApplication', '1') # Preserve painted RGBA rather than a mask.
    brush.set('ColorAsMask', '0')
    params['brush_definition'].text = ET.tostring(brush, encoding='unicode')
    for name in ['requiredBrushFile','requiredBrushFilesList']:
        params[name].text = filename
    info = PngImagePlugin.PngInfo()
    info.add_text('preset', ET.tostring(root, encoding='unicode'))
    info.add_text('version', '2.2')
    thumb = Image.new('RGBA',(200,200),(29,48,59,255))
    pic = fit_picture(im,(184,166))
    thumb.alpha_composite(pic,((200-pic.width)//2,4+(166-pic.height)//2))
    ImageDraw.Draw(thumb).text((8,177),entry['id'][:22],font=ImageFont.truetype(FONT_PATH,13),fill='white')
    return png_bytes(thumb,info)

def catalog(entries, filename, columns=4):
    cell_w, cell_h = 400, 290
    rows = math.ceil(len(entries)/columns)
    out = Image.new('RGB',(columns*cell_w,64+rows*cell_h),'#20333f')
    draw = ImageDraw.Draw(out)
    font = ImageFont.truetype(FONT_PATH,17)
    title = ImageFont.truetype(FONT_PATH,27)
    draw.text((18,16),'Threadbound modular buildings — '+('new components' if 'new' in filename else 'matching library parts'),font=title,fill='white')
    for i,entry in enumerate(entries):
        x,y = (i%columns)*cell_w,64+(i//columns)*cell_h
        draw.rectangle((x+5,y+5,x+cell_w-5,y+cell_h-5),fill='#2d4655',outline='#4c6672')
        im=fit_picture(Image.open(KIT/entry['file']).convert('RGBA'),(cell_w-36,216))
        out.paste(im,(x+(cell_w-im.width)//2,y+12+(216-im.height)//2),im)
        draw.text((x+14,y+236),entry['id'].replace('_',' '),font=font,fill='white')
        draw.text((x+14,y+260),entry['family'],font=font,fill='#b8d4df')
    out.save(KIT/filename,quality=94)
    return out

def create_example(by_id):
    width,height=1536,1024
    layers=[]
    def layer(label,im,x,y): layers.append((label,im,x,y))
    def stamp(key,box,label=None):
        im=Image.open(KIT/by_id[key]['file']).convert('RGBA')
        im=im.crop(content_box(im)).resize(box[2:],Image.Resampling.LANCZOS)
        layer(label or key,im,box[0],box[1])
    layer('00 Background — hide for transparent export',Image.new('RGBA',(width,height),'#334f61'),0,0)
    # Two footprints in world pixels. Plain plaster remains a fill; joinery,
    # opening and roof images are independent movable document layers.
    for house,x,top,w in [('Wide house',160,448,576),('Tall house',960,192,384)]:
        bottom=832
        wall=Image.open(KIT/by_id['W01_Cream_Plaster_Intact']['file']).convert('RGBA')
        tile=wall.resize((256,256),Image.Resampling.LANCZOS)
        for dy in range(0,bottom-top,256):
            for dx in range(0,w,256):
                chunk=tile.crop((0,0,min(256,w-dx),min(256,bottom-top-dy)))
                layer(house+' / plaster infill',chunk,x+dx,top+dy)
        for edge in [x-12,x+w-28]: stamp('B02_Tall_Lashed_Post',(edge,top-16,40,bottom-top+38),house+' / upright')
        for at in range(top,bottom+1,256): stamp('B01_Long_Timber_Beam',(x-24,at-10,w+48,32),house+' / crossbeam')
        stamp('B01_Long_Timber_Beam',(x-24,bottom-12,w+48,36),house+' / base beam')
        stamp('L01_Quarried_Wall',(x-24,bottom+20,w+48,84),house+' / stone footing')
    # Windows/doors sit on top of the fills, never embedded in their pixels.
    stamp('D01_Plank_Door',(212,608,150,224),'Wide house / door')
    stamp('N01_Square_Lattice_Window',(450,555,192,174),'Wide house / lattice window')
    stamp('LT01_Hanging_Paper_Lantern',(378,538,52,112),'Wide house / lamp — keep separate for engine light')
    stamp('D02_Sliding_Lattice_Door',(1040,650,228,182),'Tall house / sliding door')
    stamp('N03_Round_Spoke_Window',(1060,308,180,180),'Tall house / round window')
    # Use the new low eave and existing peaked roof as two roof silhouettes.
    # Curled returns remain separate kit options; their tile pitch needs manual
    # fitting/paint-over rather than nonuniformly stretching them into a join.
    stamp('R01_Slate_Eave_Strip',(116,370,664,84),'Wide house / straight low eave')
    stamp('R01_Blue_Slate_Roof',(908,58,488,164),'Tall house / peaked roof')
    guides=Image.new('RGBA',(width,height))
    d=ImageDraw.Draw(guides);font=ImageFont.truetype(FONT_PATH,22)
    d.text((35,24),'MODULAR BUILDING STUDY',font=ImageFont.truetype(FONT_PATH,29),fill='white')
    d.text((35,64),'Independent layers • 128 px guide grid • example only',font=font,fill='#bed7df')
    d.line((848,647,848,832),fill='#f3dc9b',width=3)
    d.line((837,647,859,647),fill='#f3dc9b',width=3);d.line((837,832,859,832),fill='#f3dc9b',width=3)
    d.text((775,855),'185 px',font=font,fill='#f3dc9b')
    d.text((775,884),'player scale',font=ImageFont.truetype(FONT_PATH,15),fill='#f3dc9b')
    layer('99 Guides — hide for art export',guides,0,0)
    merged=Image.new('RGBA',(width,height))
    for name,im,x,y in layers: merged.alpha_composite(im,(x,y))
    merged.convert('RGB').save(KIT/'assembly-example.jpg',quality=94)
    image=ET.Element('image',{'w':str(width),'h':str(height),'name':'Threadbound modular buildings v1','version':'0.0.3','xres':'72','yres':'72'})
    stack=ET.SubElement(image,'stack')
    with zipfile.ZipFile(KIT/'Building_Assembly_Example.ora','w',compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,(name,im,x,y) in reversed(list(enumerate(layers))):
            src=f'data/layer{i:03d}.png'
            ET.SubElement(stack,'layer',{'name':name,'src':src,'x':str(x),'y':str(y),'opacity':'1.0','visibility':'visible','composite-op':'svg:src-over'})
            z.writestr(src,png_bytes(im))
        z.writestr('stack.xml',ET.tostring(image,encoding='utf-8',xml_declaration=True))
        z.writestr('mergedimage.png',png_bytes(merged))
        thumbnail=merged.copy();thumbnail.thumbnail((256,256));z.writestr('Thumbnails/thumbnail.png',png_bytes(thumbnail))
    return len(layers)

def build():
    reused=json.loads((KIT/'reused_sources.json').read_text(encoding='utf-8'))
    entries=[];resources={}
    for path in sorted((KIT/'generated').glob('*.png')):
        entries.append({'id':path.stem,'file':'generated/'+path.name,'origin':'new image_gen component'})
    for record in reused:
        entries.append({**record,'origin':'byte-identical library reuse'})
    for entry in entries:
        new=entry['origin'].startswith('new')
        im=Image.open(KIT/entry['file']).convert('RGBA')
        entry.update(family=family(entry['id'],new),size=list(im.size),alpha_range=list(im.getchannel('A').getextrema()),sha256=hashlib.sha256((KIT/entry['file']).read_bytes()).hexdigest(),suggested_brush_size=default_size(entry['id'],new))
        filename=('Village_MB_' if new else 'Village_')+entry['id']
        entry['brush_file']=filename+'.gbr';entry['preset_file']=filename+'.kpp'
        b=gbr(im,entry['id'].replace('_',' ') if new else entry['gbr_description'],140 if new else entry['gbr_spacing'])
        if not new: assert hashlib.md5(b).hexdigest()==entry['gbr_md5'],entry['id']+' legacy brush changed'
        preset=new_preset(entry,b,im) if new else (KIT/'preset_sources'/entry['preset']).read_bytes()
        resources['brushes/'+entry['brush_file']]=b
        resources['paintoppresets/'+entry['preset_file']]=preset
    catalog([e for e in entries if e['origin'].startswith('new')],'catalog-new.jpg')
    catalog([e for e in entries if not e['origin'].startswith('new')],'catalog-library.jpg')
    manifest=ET.Element('{'+MANIFEST_NS+'}manifest',{'{'+MANIFEST_NS+'}version':'1.2'})
    ET.SubElement(manifest,'{'+MANIFEST_NS+'}file-entry',{'{'+MANIFEST_NS+'}media-type':'application/x-krita-resourcebundle','{'+MANIFEST_NS+'}full-path':'/'})
    for path,data in resources.items():
        kind=path.split('/')[0]
        node=ET.SubElement(manifest,'{'+MANIFEST_NS+'}file-entry',{'{'+MANIFEST_NS+'}media-type':kind,'{'+MANIFEST_NS+'}full-path':path,'{'+MANIFEST_NS+'}md5sum':hashlib.md5(data).hexdigest()})
        tags=ET.SubElement(node,'{'+MANIFEST_NS+'}tags')
        if kind=='paintoppresets':
            entry=next(e for e in entries if e['preset_file']==path.split('/')[-1])
            for label in ['Village - Modular Buildings','Village - Modular '+entry['family']]: ET.SubElement(tags,'{'+MANIFEST_NS+'}tag').text=label
    meta=ET.Element('{'+META_NS+'}meta')
    ET.SubElement(meta,'{'+META_NS+'}bundle-version').text='1'
    ET.SubElement(meta,'{'+DC_NS+'}title').text='Threadbound Modular Buildings v1'
    ET.SubElement(meta,'{'+DC_NS+'}description').text='14 new modular components with 22 matching source-library parts. Painted RGBA stamps; no gameplay changes.'
    with zipfile.ZipFile(KIT/'Threadbound_Modular_Buildings_v1.bundle','w',compression=zipfile.ZIP_DEFLATED) as z:
        for path,data in resources.items(): z.writestr(path,data)
        z.writestr('meta.xml',ET.tostring(meta,encoding='utf-8',xml_declaration=True))
        z.writestr('META-INF/manifest.xml',ET.tostring(manifest,encoding='utf-8',xml_declaration=True))
        preview=Image.open(KIT/'catalog-new.jpg');preview.thumbnail((256,256));z.writestr('preview.png',png_bytes(preview))
    layers=create_example({e['id']:e for e in entries})
    (KIT/'manifest.json').write_text(json.dumps({'new_components':14,'reused_components':22,'total':len(entries),'assembly_layers':layers,'assets':entries},indent=2)+'\n',encoding='utf-8')
    print(f'Packaged {len(entries)} stamps, {len(resources)} brush/preset resources and {layers} independent ORA layers.')

if __name__=='__main__': build()
