"""Remove unused prototype datablocks from the saved bird, preserving its art."""
from pathlib import Path
import bpy,json
ROOT=Path(__file__).resolve().parents[2]
path=ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v3.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
def fingerprint():
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    return {'components':len(meshes),'vertices':sum(len(o.data.vertices) for o in meshes),'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons),'clips':sorted(a.name for a in bpy.data.actions),'bones':list(bpy.data.objects['LoomHeron_Rig'].data.bones.keys())}
before=fingerprint()
for collection in [bpy.data.meshes,bpy.data.materials,bpy.data.images]:
    for data in list(collection):
        if not data.users and not data.use_fake_user:collection.remove(data)
assert before==fingerprint(),'Cleanup must not change visible topology, rig or actions'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
print('HERON_V3_SOURCE_CLEANED',json.dumps(before),flush=True)
