from pathlib import Path
import json,struct
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT=ROOT/'outputs/central-tower-model-v3'
measure=json.loads((OUT/'roof_clearance_verification.json').read_text())
result={}
for filename,full in [('CentralTower_Exterior.glb',True),('CentralTower_Cutaway.glb',False)]:
    raw=(OUT/filename).read_bytes();magic,version,size=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and size==len(raw)
    n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
    nodes={node.get('name'):node for node in doc['nodes']}
    checks=[]
    for c in measure['checks']:
        assert (c['hidden_inner_return'] in nodes)==full
        node=nodes[c['fixed_side']];mesh=doc['meshes'][node['mesh']]
        ranges=[doc['accessors'][p['attributes']['POSITION']] for p in mesh['primitives']]
        minimum=min(a['min'][0] for a in ranges) if c['side']=='Right' else min(-a['max'][0] for a in ranges)
        assert minimum>=c['trim_abs_x']-2e-5
        checks.append({'side':c['fixed_side'],'minimum_abs_x':minimum,'wall_inner_abs_x':c['interior_wall_abs_x']})
    assert len(doc.get('images',[]))==12
    assert all('bufferView' in im and 'uri' not in im for im in doc['images'])
    assert all('TEXCOORD_0' in p['attributes'] and 'TANGENT' in p['attributes'] for m in doc['meshes'] for p in m['primitives'])
    result[filename]={'checks':checks,'has_hidden_return_objects':full,'embedded_images':12,'uv_and_tangents':True}
result['checks_passed']=True
(OUT/'glb_clearance_verification.json').write_text(json.dumps(result,indent=2))
print('EXPORTED_ROOF_CLEARANCE_PASS')
