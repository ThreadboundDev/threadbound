from pathlib import Path
import json,struct,io
from PIL import Image
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT=ROOT/'outputs/central-tower-model-v2'
result={}
for file,full in [('CentralTower_Exterior.glb',True),('CentralTower_Cutaway.glb',False)]:
    raw=(OUT/file).read_bytes();magic,version,size=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and size==len(raw)
    n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);start=20+n
    binlen,kind=struct.unpack_from('<II',raw,start);data=raw[start+8:start+8+binlen]
    nodes=[n.get('name','') for n in doc['nodes']]
    sides=[n for n in nodes if '_Side_With_Corners' in n]
    fronts=[n for n in nodes if '_Front_Mitered' in n]
    backs=[n for n in nodes if '_Back_Mitered' in n]
    assert len(sides)==8 and len(backs)==4
    assert len(fronts)==(4 if full else 0)
    assert any('02_Facade_Removable' in n for n in nodes)==full
    assert all('TEXCOORD_0' in p['attributes'] and 'TANGENT' in p['attributes'] for m in doc['meshes'] for p in m['primitives'])
    sizes=[]
    for im in doc['images']:
        bv=doc['bufferViews'][im['bufferView']];off=bv.get('byteOffset',0)
        size=list(Image.open(io.BytesIO(data[off:off+bv['byteLength']])).size);sizes.append(size)
    assert sum(s==[4096,4096] for s in sizes)==4
    assert sum(s==[2048,2048] for s in sizes)==8
    result[file]={'bytes':len(raw),'side_parts_with_corners':sides,'front_parts':fronts,'back_parts':backs,'embedded_texture_sizes':sizes,'uv_and_tangents_present':True}
result['checks_passed']=True
(OUT/'glb_roof_verification.json').write_text(json.dumps(result,indent=2))
print('ROOF_EXPORT_CHECKS_PASS')
