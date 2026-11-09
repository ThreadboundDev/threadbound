"""Reimport the portable delivery and verify geometry, UVs, and embedded texture."""
from pathlib import Path
import json
import struct
import bpy
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

D=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(D/'Bellstriker_Painted_v1.blend'))
original=[o for o in bpy.context.scene.objects if o.type=='MESH']
points=[o.matrix_world@v.co for o in original for v in o.data.vertices]
tree=KDTree(len(points))
for i,p in enumerate(points):tree.insert(p,i)
tree.balance()
for o in original:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(D/'Bellstriker_Painted_v1.glb'))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
triangle_count=0;max_error=0;uv_count=0
for o in objects:
    o.data.calc_loop_triangles();triangle_count+=len(o.data.loop_triangles)
    assert o.data.uv_layers.active is not None
    for uv in o.data.uv_layers.active.data:
        assert all(np.isfinite(v) and -.00001<=v<=1.00001 for v in uv.uv)
        uv_count+=1
    for v in o.data.vertices:
        max_error=max(max_error,tree.find(o.matrix_world@v.co)[2])
    for material in o.data.materials:
        tex=[n for n in material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
        assert tex and tuple(tex[0].image.size)==(4096,4096)
assert triangle_count==48489
assert max_error<1e-5
data=(D/'Bellstriker_Painted_v1.glb').read_bytes()
length=struct.unpack_from('<I',data,12)[0]
gltf=json.loads(data[20:20+length])
assert all('bufferView' in image and 'uri' not in image for image in gltf['images'])
report=json.loads((D/'validation.json').read_text())
report['export_validation']=dict(triangles=triangle_count,mesh_count=len(objects),max_world_position_error=max_error,uv_loops_checked=uv_count,embedded_images=len(gltf['images']),external_texture_dependencies=0)
(D/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.context.scene.render.filepath=str(D/'preview_exported_glb.png')
bpy.ops.render.render(write_still=True)
print('EXPORT_VERIFIED',json.dumps(report['export_validation']))
