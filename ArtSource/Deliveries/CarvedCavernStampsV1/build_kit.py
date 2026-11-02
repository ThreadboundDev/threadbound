"""Package source pixels as full-color Krita brushes; no painting or alpha edits."""
import hashlib
import io
import json
import struct
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, PngImagePlugin

KIT = Path(__file__).resolve().parent
NS = 'urn:oasis:names:tc:opendocument:xmlns:manifest:1.0'
ET.register_namespace('manifest', NS)

def png(im, info=None):
    stream = io.BytesIO()
    im.save(stream, 'PNG', pnginfo=info)
    return stream.getvalue()

def build():
    specs = json.loads((KIT/'generation_prompts.json').read_text())['assets']
    resources, entries = {}, []
    sizes = [384, 512, 768, 896, 1280, 1408]
    catalog = Image.new('RGB', (1400, 1030), '#263e4c')
    draw = ImageDraw.Draw(catalog)
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 23)
    draw.text((25, 18), 'CARVED CAVERN — six flat-top rock stamps', font=font, fill='white')
    for i, spec in enumerate(specs):
        name = spec['id']
        source = KIT/'generated'/f'{name}.png'
        original = Image.open(source).convert('RGBA')
        assert original.getchannel('A').getextrema() == (0, 255), name
        box = original.getbbox()
        solid_box = original.getchannel('A').point(lambda a: 255 if a > 128 else 0).getbbox()
        assert solid_box and solid_box[0] > 0 and solid_box[1] > 0 and solid_box[2] < original.width and solid_box[3] < original.height, name
        im = original.crop(box)  # Trim empty margins only; preserve all painted pixels.
        stem = 'Cavern_'+name
        label = name.encode()+b'\0'
        gbr = struct.pack('>7I', 28+len(label), 2, *im.size, 4, 0x47494D50, 150)+label+im.tobytes()
        resources['brushes/'+stem+'.gbr'] = gbr
        root = ET.fromstring((KIT/'preset_template.xml').read_text())
        root.set('name', 'Cavern '+name.replace('_', ' '))
        params = {e.get('name'):e for e in root.findall('param')}
        brush = ET.fromstring(params['brush_definition'].text)
        for key, value in {'filename':stem+'.gbr', 'md5sum':hashlib.md5(gbr).hexdigest(), 'scale':str(sizes[i]/max(im.size)), 'brushApplication':'1', 'ColorAsMask':'0'}.items():
            brush.set(key, value)
        params['brush_definition'].text = ET.tostring(brush, encoding='unicode')
        for key in ['requiredBrushFile', 'requiredBrushFilesList']:
            params[key].text = stem+'.gbr'
        info = PngImagePlugin.PngInfo()
        info.add_text('preset', ET.tostring(root, encoding='unicode'))
        info.add_text('version', '2.2')
        thumb = Image.new('RGBA', (200,200), '#263e4c')
        small = im.copy(); small.thumbnail((188,155))
        thumb.alpha_composite(small, ((200-small.width)//2, (170-small.height)//2))
        ImageDraw.Draw(thumb).text((8,177), name[:22], font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',13), fill='white')
        resources['paintoppresets/'+stem+'.kpp'] = png(thumb, info)
        x, y = (i%2)*700, 65+(i//2)*320
        draw.rectangle((x+12,y,x+688,y+308), fill='#36515e')
        display = im.copy(); display.thumbnail((640,242))
        catalog.paste(display, (x+(700-display.width)//2,y+12+(242-display.height)//2), display)
        draw.text((x+26,y+266), f'{name}  |  start at {sizes[i]} px', font=font, fill='white')
        # Independently decode serialized GBR header and compare actual RGBA bytes.
        header = struct.unpack('>7I', gbr[:28])
        assert header[2:5] == (*im.size,4)
        assert gbr[header[0]:] == im.tobytes()
        entries.append({'id':name,'file':'generated/'+name+'.png','size':list(original.size),'content_box':box,'solid_content_box':solid_box,'suggested_width':sizes[i],'sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
    catalog.save(KIT/'catalog.jpg', quality=94)
    manifest = ET.Element('{'+NS+'}manifest', {'{'+NS+'}version':'1.2'})
    ET.SubElement(manifest,'{'+NS+'}file-entry', {'{'+NS+'}media-type':'application/x-krita-resourcebundle','{'+NS+'}full-path':'/'})
    for path, data in resources.items():
        entry = ET.SubElement(manifest,'{'+NS+'}file-entry',{'{'+NS+'}media-type':path.split('/')[0],'{'+NS+'}full-path':path,'{'+NS+'}md5sum':hashlib.md5(data).hexdigest()})
        if path.startswith('paintoppresets/'):
            tags = ET.SubElement(entry,'{'+NS+'}tags')
            ET.SubElement(tags,'{'+NS+'}tag').text = 'Cavern - Carved Walkways'
    with zipfile.ZipFile(KIT/'Threadbound_Carved_Cavern_v1.bundle','w',zipfile.ZIP_DEFLATED) as z:
        for path, data in resources.items(): z.writestr(path,data)
        z.writestr('META-INF/manifest.xml', ET.tostring(manifest,encoding='utf-8',xml_declaration=True))
        z.writestr('meta.xml','<?xml version="1.0"?><meta:meta xmlns:meta="http://www.calligra.org/DTD/krita-resourcebundle-meta" xmlns:dc="http://purl.org/dc/elements/1.1/"><meta:bundle-version>1</meta:bundle-version><dc:title>Threadbound Carved Cavern v1</dc:title></meta:meta>')
        preview = catalog.copy(); preview.thumbnail((256,256)); z.writestr('preview.png',png(preview))
    with zipfile.ZipFile(KIT/'Threadbound_Carved_Cavern_v1.bundle') as z:
        assert z.testzip() is None
        for node in ET.fromstring(z.read('META-INF/manifest.xml')):
            path = node.get('{'+NS+'}full-path')
            if path == '/': continue
            assert hashlib.md5(z.read(path)).hexdigest() == node.get('{'+NS+'}md5sum')
            if path.startswith('paintoppresets/'):
                preset = Image.open(io.BytesIO(z.read(path)))
                params = {e.get('name'):e.text for e in ET.fromstring(preset.info['preset']).findall('param')}
                brush = ET.fromstring(params['brush_definition'])
                data = z.read('brushes/'+brush.get('filename'))
                assert hashlib.md5(data).hexdigest() == brush.get('md5sum')
                assert brush.get('brushApplication') == '1' and brush.get('ColorAsMask') == '0'
    (KIT/'manifest.json').write_text(json.dumps({'assets':entries,'checks':'RGBA alpha, uncropped silhouette, exact brush pixels, ZIP integrity, resource hashes, preset links passed','native_krita_import':'pending user review'},indent=2)+'\n')
    print('Packaged and verified six transparent PNGs, six full-color brush presets and catalog.')

if __name__ == '__main__': build()
