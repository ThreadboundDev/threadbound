"""Apply the reviewed knee correction without re-exporting animations/materials."""
import json,struct,shutil
from pathlib import Path
import numpy as np
R=Path(__file__).resolve().parents[2]
p=R/'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'
backup=R/'ArtSource/Player/Blender/ManualAttacks/threadborne_before_knee_cleanup.glb'
assert not backup.exists(),'Knee patch already applied; restore backup before rebuilding'
raw=bytearray(p.read_bytes());n=struct.unpack_from('<I',raw,12)[0];j=json.loads(raw[20:20+n]);start=28+n
prim=j['meshes'][0]['primitives'][0]
def array(index):
 a=j['accessors'][index];v=j['bufferViews'][a['bufferView']];dt={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']];size=np.dtype(dt).itemsize;cols={'SCALAR':1,'VEC3':3}[a['type']]
 return np.ndarray((a['count'],cols),dtype=dt,buffer=raw,offset=start+v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',size*cols),size))
pos=array(prim['attributes']['POSITION']);norm=array(prim['attributes']['NORMAL']);indices=array(prim['indices']).reshape(-1,3)
patch=json.loads((R/'tools/art/player_knee_vertex_patch.json').read_text())
def convert(v):return [v[0],v[2],-v[1]]
lookup={tuple(round(float(x),5) for x in convert(a)):convert(b) for a,b in patch}
changed=[]
for i,v in enumerate(pos):
 key=tuple(round(float(x),5) for x in v)
 if key in lookup:pos[i]=lookup[key];changed.append(i)
assert len(changed)>2000,len(changed)
# Recompute normals only for corrected vertices and their adjacent triangles.
face=np.cross(pos[indices[:,1]]-pos[indices[:,0]],pos[indices[:,2]]-pos[indices[:,0]])
acc=np.zeros_like(pos)
for corner in range(3):np.add.at(acc,indices[:,corner],face)
length=np.linalg.norm(acc,axis=1);valid=np.array(changed)[length[changed]>1e-10];norm[valid]=acc[valid]/length[valid,None]
shutil.copy2(p,backup);p.write_bytes(raw)
print('KNEE_PATCH',len(changed),'vertices; all animation, skin, UV and material buffers retained')

