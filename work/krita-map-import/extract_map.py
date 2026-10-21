"""Lossless KRA layer extraction for this saved RGBA8, normal-blend map.

Reads the documented Krita VERSION 2 64px LZF tile format. Never writes KRA.
The recomposed visible layers are checked against Krita's saved projection.
"""
from pathlib import Path
import hashlib, io, json, zipfile
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
WORK = Path(__file__).resolve().parent
SOURCE = Path('C:/Users/chase/Documents/Codex/2026-10-07/ri/outputs/blue_village_stamp_pack/cave_connections_v1/Blue_Village_Connections_Review.kra')
OUT = ROOT / 'Assets/BlueBiome/Art/LakesideMap'
OUT.mkdir(parents=True, exist_ok=True)
NS = {'k': 'http://www.calligra.org/DTD/krita'}

def lzf(data):
    out = bytearray()
    i = 0
    while i < len(data):
        ctrl = data[i]; i += 1
        if ctrl < 32:
            length = ctrl + 1
            out.extend(data[i:i+length]); i += length
        else:
            length = ctrl >> 5
            offset = (ctrl & 31) << 8
            if length == 7:
                length += data[i]; i += 1
            offset += data[i] + 1; i += 1
            for _ in range(length + 2):
                out.append(out[-offset])
    assert len(out) == 16384, len(out)
    return out

with zipfile.ZipFile(SOURCE) as z:
    doc = ET.fromstring(z.read('maindoc.xml'))
    image = doc.find('k:IMAGE', NS)
    size = (int(image.get('width')), int(image.get('height')))
    iname = image.get('name')
    manifest = dict(source=str(SOURCE), source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(), canvas=list(size), world_origin=[-1408,-2560], pixels_per_unit=1, groups=[], chunks=[])

    def decode(node):
        assert node.get('colorspacename') == 'RGBA'
        assert node.get('compositeop') == 'normal'
        key = iname + '/layers/' + node.get('filename')
        assert z.read(key + '.defaultpixel') == bytes(4)
        stream = io.BytesIO(z.read(key))
        header = [stream.readline().strip() for _ in range(5)]
        assert header[:4] == [b'VERSION 2', b'TILEWIDTH 64', b'TILEHEIGHT 64', b'PIXELSIZE 4'], header
        count = int(header[4].split()[1])
        canvas = Image.new('RGBA', size)
        for _ in range(count):
            x,y,codec,length = stream.readline().strip().split(b',')
            assert codec == b'LZF'
            block = stream.read(int(length))
            if block[0] == 1:
                raw = np.frombuffer(lzf(block[1:]), dtype=np.uint8).reshape(4,4096).T.copy().tobytes()
            else:
                assert block[0] == 0
                raw = block[1:]
            tile = Image.frombytes('RGBA',(64,64),raw,'raw','BGRA')
            canvas.paste(tile,(int(x)+int(node.get('x','0')),int(y)+int(node.get('y','0'))))
        opacity = int(node.get('opacity','255'))
        if opacity != 255:
            canvas.putalpha(canvas.getchannel('A').point(lambda a: round(a*opacity/255)))
        return canvas

    groups = image.find('k:layers', NS)
    visible = Image.new('RGBA',size)
    artwork = Image.new('RGBA',size)
    names = {'layer7':'foreground','layer9':'bridges','layer12':'breakables','layer14':'terrain','layer17':'rear_cave'}
    for group in reversed(list(groups)):
        merged = Image.new('RGBA',size)
        for node in reversed(list(group.find('k:layers',NS))):
            if node.get('visible') != '1': continue
            leaf = decode(node)
            merged.alpha_composite(leaf)
            bbox = leaf.getchannel('A').getbbox()
            if bbox:
                leaf.save(WORK/(node.get('filename')+'.png'))
            print(node.get('name'),bbox,flush=True)
        visible.alpha_composite(merged)
        label = names.get(group.get('filename'))
        if not label: continue
        artwork.alpha_composite(merged)
        manifest['groups'].append(dict(name=label,bounds=merged.getchannel('A').getbbox()))
        # Independent 1024px chunks preserve transparent margins and 1:1 scale.
        for y in range(0,size[1],1024):
            for x in range(0,size[0],1024):
                chunk = merged.crop((x,y,min(x+1024,size[0]),min(y+1024,size[1])))
                if not chunk.getchannel('A').getbbox(): continue
                name=f'{label}_{x//1024:02}_{y//1024:02}.png'
                chunk.save(OUT/name)
                manifest['chunks'].append(dict(group=label,path=name,position=[x-1408,y-2560],size=list(chunk.size)))
    saved=Image.open(io.BytesIO(z.read('mergedimage.png'))).convert('RGBA')
    # Krita and Pillow round 8-bit compositing slightly differently.
    dif=np.abs(np.asarray(visible,dtype=np.int16)-np.asarray(saved,dtype=np.int16))
    manifest['projection_check']=dict(max_channel_error=int(dif.max()),mean_channel_error=float(dif.mean()),fraction_over_two=float(np.mean(np.max(dif,axis=2)>2)))
    print('PROJECTION_CHECK',manifest['projection_check'],flush=True)
    assert manifest['projection_check']['fraction_over_two'] < .002, 'Layer decoding does not match saved Krita projection'
    visible.thumbnail((1382,1178));visible.save(WORK/'reference_preview.png')
    artwork.thumbnail((1382,1178));artwork.save(WORK/'art_preview.png')
    (OUT/'map_manifest.json').write_text(json.dumps(manifest,indent=2))
    print('CHUNKS',len(manifest['chunks']),flush=True)
