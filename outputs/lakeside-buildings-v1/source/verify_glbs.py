"""Independent GLB payload checks: dimensions, textures, UVs and cutaway roof."""
import json, struct, io, hashlib, math
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT=ROOT/'outputs/lakeside-buildings-v1'
manifest=json.loads((OUT/'asset_manifest.json').read_text())
results={};image_provenance={}
def rotation(q):
    x,y,z,w=q
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),0],
                     [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),0],
                     [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y),0],
                     [0,0,0,1]],dtype=float)
for path in sorted((OUT/'models').glob('*.glb')):
    raw=path.read_bytes();magic,version,size=struct.unpack_from('<4sII',raw)
    assert magic==b'glTF' and version==2 and size==len(raw)
    jlen,jtype=struct.unpack_from('<II',raw,12);assert jtype==0x4e4f534a
    doc=json.loads(raw[20:20+jlen]);offset=20+jlen
    blen,btype=struct.unpack_from('<II',raw,offset);assert btype==0x004e4942
    binary=raw[offset+8:offset+8+blen]
    def accessor(index):
        ac=doc['accessors'][index];bv=doc['bufferViews'][ac['bufferView']]
        dtype={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}[ac['componentType']]
        channels={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[ac['type']]
        item=np.dtype(dtype).itemsize;start=bv.get('byteOffset',0)+ac.get('byteOffset',0)
        stride=bv.get('byteStride',channels*item)
        return np.ndarray((ac['count'],channels),dtype=dtype,buffer=binary,offset=start,strides=(stride,item)).copy()
    allpos=[];tris=0;meshes=0;uv=True;tangents=True;roofchecks=[]
    def walk(idx,parent):
        node=doc['nodes'][idx]
        if 'matrix' in node:local=np.array(node['matrix']).reshape(4,4,order='F')
        else:
            local=rotation(node.get('rotation',[0,0,0,1]))@np.diag(node.get('scale',[1,1,1])+[1])
            local[:3,3]=node.get('translation',[0,0,0])
        world=parent@local
        if 'mesh' in node:
            for primitive in doc['meshes'][node['mesh']]['primitives']:
                attrs=primitive['attributes'];p=accessor(attrs['POSITION']);assert np.isfinite(p).all()
                hp=np.concatenate([p,np.ones((len(p),1))],axis=1)@world.T
                allpos.append(hp[:,:3])
                counter['meshes']+=1
                counter['tris']+=(len(accessor(primitive['indices'])) if 'indices' in primitive else len(p))//3
                assert 'TEXCOORD_0' in attrs,node['name']
                assert np.isfinite(accessor(attrs['TEXCOORD_0'])).all()
                assert 'NORMAL' in attrs and 'TANGENT' in attrs,node['name']
                if 'Roof_Sides_Fixed' in node.get('name','') and 'HideWithFacade' not in node.get('name',''):
                    key=path.stem.split('_')[0]
                    lim=manifest['assets'][key]['roof']['inner_wall_cut_limit']
                    minimum=float(np.min(np.abs(hp[:,0])))
                    assert minimum>=lim-2e-5,(node['name'],minimum,lim)
                    roofchecks.append({'node':node['name'],'minimum_abs_x':minimum,'limit':lim})
        for child in node.get('children',[]):walk(child,world)
    counter={'tris':0,'meshes':0}
    for idx in doc['scenes'][doc.get('scene',0)]['nodes']:walk(idx,np.eye(4))
    p=np.concatenate(allpos);dims=(p.max(axis=0)-p.min(axis=0)).tolist()
    key=path.stem.split('_')[0];mode='cutaway' if 'Cutaway' in path.name else 'exterior'
    expected=manifest['assets'][key][mode]['dimensions_blender_units']
    # Y-up glTF dimensions: X width, Y height, Z depth.
    assert np.allclose(dims,[expected[0],expected[2],expected[1]],atol=3e-5),(path.name,dims,expected)
    assert counter['tris']==manifest['assets'][key][mode]['triangles'],(path.name,counter)
    if mode=='cutaway':assert not any('Facade_Removable' in n.get('name','') or 'HideWithFacade' in n.get('name','') for n in doc['nodes'])
    ims=[]
    for im in doc.get('images',[]):
        assert 'uri' not in im and 'bufferView' in im
        bv=doc['bufferViews'][im['bufferView']];data=binary[bv.get('byteOffset',0):bv.get('byteOffset',0)+bv['byteLength']]
        pic=Image.open(io.BytesIO(data));pic.load()
        sha=hashlib.sha256(data).hexdigest();name=im.get('name','unnamed')
        if name in image_provenance:assert sha==image_provenance[name],name
        image_provenance[name]=sha
        assert pic.size in [(4096,4096),(2048,2048)],(name,pic.size)
        ims.append({'name':name,'size':list(pic.size),'embedded':True,'sha256':sha})
    assert len(ims)==(9 if key=='CoveredBoatSlip' else 12),len(ims)
    results[path.name]={'bytes':len(raw),'triangles':counter['tris'],'mesh_primitives':counter['meshes'],'dimensions_gltf_y_up':dims,'all_have_uv_normals_tangents':True,'texture_images':ims,'fixed_roof_checks':roofchecks,'checks_passed':True}
assert len(results)==5
(OUT/'glb_verification.json').write_text(json.dumps({'files':results,'checks_passed':True},indent=2))
print('ALL_FIVE_GLBS_VERIFIED', {k:v['triangles'] for k,v in results.items()})
