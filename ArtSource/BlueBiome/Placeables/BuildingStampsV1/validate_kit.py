"""Check delivered bytes, Krita resource links and independent ORA rendering."""
import hashlib
import io
import json
import struct
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from PIL import Image, ImageChops

p=Path(__file__).resolve().parent
m=json.loads((p/'manifest.json').read_text(encoding='utf-8'))
assert m['total']==36 and m['new_components']==14 and m['reused_components']==22
ns={'m':'urn:oasis:names:tc:opendocument:xmlns:manifest:1.0'}
with zipfile.ZipFile(p/'Threadbound_Modular_Buildings_v1.bundle') as bundle:
    assert bundle.testzip() is None
    resources=ET.fromstring(bundle.read('META-INF/manifest.xml'))
    count=0
    for node in resources.findall('m:file-entry',ns):
        path=node.get('{'+ns['m']+'}full-path')
        if path=='/':continue
        assert hashlib.md5(bundle.read(path)).hexdigest()==node.get('{'+ns['m']+'}md5sum')
        count+=1
    assert count==72
    for entry in m['assets']:
        file=p/entry['file']
        assert hashlib.sha256(file.read_bytes()).hexdigest()==entry['sha256']
        im=Image.open(file).convert('RGBA')
        assert list(im.size)==entry['size']
        if entry['id'] in ['W01_Cream_Plaster_Intact','W02_Wide_Weathered_Plaster']:
            assert im.getchannel('A').getextrema()==(255,255)
        else:
            low,high=im.getchannel('A').getextrema()
            assert low==0 and high>=250
        brush=bundle.read('brushes/'+entry['brush_file'])
        header,version,w,h,channels,magic,spacing=struct.unpack('>7I',brush[:28])
        assert version==2 and channels==4 and magic==0x47494D50
        assert (w,h)==im.size and brush[header:]==im.tobytes()
        kpp=Image.open(io.BytesIO(bundle.read('paintoppresets/'+entry['preset_file'])))
        preset=ET.fromstring(kpp.info['preset'])
        params={e.get('name'):e.text for e in preset.findall('param')}
        definition=ET.fromstring(params['brush_definition'])
        assert definition.get('filename')==entry['brush_file']
        assert definition.get('md5sum')==hashlib.md5(brush).hexdigest()
        assert definition.get('ColorAsMask')=='0' and definition.get('brushApplication')=='1'
        assert params['requiredBrushFile']==entry['brush_file']
        assert float(definition.get('scale'))>0
with zipfile.ZipFile(p/'Building_Assembly_Example.ora') as ora:
    assert ora.testzip() is None and ora.read('mimetype')==b'image/openraster'
    image=ET.fromstring(ora.read('stack.xml'))
    layers=image.find('stack').findall('layer')
    assert len(layers)==m['assembly_layers']
    assembled=Image.new('RGBA',(int(image.get('w')),int(image.get('h'))))
    for layer in reversed(layers):
        im=Image.open(io.BytesIO(ora.read(layer.get('src')))).convert('RGBA')
        assembled.alpha_composite(im,(int(layer.get('x')),int(layer.get('y'))))
    merged=Image.open(io.BytesIO(ora.read('mergedimage.png'))).convert('RGBA')
    assert ImageChops.difference(assembled,merged).getbbox() is None
result={'passed':True,'stamps':36,'new':14,'reused':22,'bundle_resources':count,'ora_layers':len(layers),'rgba_brush_pixels_preserved':True,'resource_links_and_checksums_valid':True,'ora_recomposes_exactly':True,'live_installation_performed':False}
(p/'validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
