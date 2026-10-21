"""Inspect exported GLBs independently, including actual embedded image sizes."""
from pathlib import Path
import json,struct,io
import numpy as np
from PIL import Image
HERE=Path(__file__).resolve()
ROOT=HERE.parents[3] if HERE.parent.name=='source' else HERE.parents[2]
OUT=HERE.parents[1] if HERE.parent.name=='source' else ROOT/'outputs/central-tower-model-v1'
reports={}
for fn in ['CentralTower_Exterior.glb','CentralTower_Cutaway.glb']:
    raw=(OUT/fn).read_bytes()
    magic,version,size=struct.unpack_from('<III',raw,0)
    assert magic==0x46546c67 and version==2 and size==len(raw)
    jsonsize,kind=struct.unpack_from('<II',raw,12)
    assert kind==0x4e4f534a
    doc=json.loads(raw[20:20+jsonsize]);binstart=20+jsonsize
    binsize,binkind=struct.unpack_from('<II',raw,binstart);data=raw[binstart+8:binstart+8+binsize]
    assert binkind==0x004e4942
    sizes=[]
    for im in doc.get('images',[]):
        assert 'bufferView' in im and 'uri' not in im
        bv=doc['bufferViews'][im['bufferView']];start=bv.get('byteOffset',0)
        image=Image.open(io.BytesIO(data[start:start+bv['byteLength']]))
        sizes.append({'name':im.get('name'),'size':list(image.size),'format':image.format})
    mins=[];maxs=[];tris=0;hasuv=True
    for m in doc['meshes']:
        for p in m['primitives']:
            acc=doc['accessors'][p['attributes']['POSITION']]
            mins.append(acc['min']);maxs.append(acc['max'])
            assert p.get('mode',4)==4
            tris+=doc['accessors'][p['indices']]['count']//3
            hasuv=hasuv and 'TEXCOORD_0' in p['attributes']
    # Blender glTF's mesh positions are Y-up; root transforms are identity.
    lo=np.min(mins,axis=0);hi=np.max(maxs,axis=0);dims=hi-lo
    hasfacade=any('02_Facade_Removable' in node.get('name','') for node in doc['nodes'])
    assert hasfacade==(fn=='CentralTower_Exterior.glb')
    assert hasuv
    assert abs(float(dims[0])-1200/128)<.06
    assert abs(float(dims[1])-4100/128)<.06
    assert sum(im['size']==[4096,4096] for im in sizes)>=4
    assert len(doc['materials'])>=6
    assert all(mat.get('pbrMetallicRoughness',{}).get('baseColorTexture') for mat in doc['materials'] if mat['name'] in ['walnut','plaster','blue_tiles','slate'])
    reports[fn]={'bytes':len(raw),'triangles':tris,'mesh_objects':len(doc['meshes']),'dimensions_gltf_xyz':[float(x) for x in dims],'embedded_textures':sizes,'has_uv':hasuv,'contains_removable_facade':hasfacade}
reports['checks_passed']=True
(OUT/'glb_verification.json').write_text(json.dumps(reports,indent=2))
print(json.dumps(reports,indent=2))
