"""Read local golem FBX geometry and animation metadata in disposable Blender state."""
import bpy
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT/'work/armored-golem-review-2026-10-28'
result=[]
for path in sorted((WORK/'temp/source').rglob('*.fbx')):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path))
    scene=bpy.context.scene
    meshes=[o for o in scene.objects if o.type=='MESH']
    rigs=[o for o in scene.objects if o.type=='ARMATURE']
    points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    record=dict(file=path.relative_to(WORK/'temp/source').as_posix(),
                meshes=[dict(name=o.name,vertices=len(o.data.vertices),
                             triangles=sum(len(p.vertices)-2 for p in o.data.polygons),
                             materials=[m.name for m in o.data.materials],
                             armature_modifier=any(m.type=='ARMATURE' for m in o.modifiers)) for o in meshes],
                rigs=[dict(name=r.name,bones=len(r.data.bones),bone_names=[b.name for b in r.data.bones]) for r in rigs],
                actions=[dict(name=r.animation_data.action.name,frame_range=list(r.animation_data.action.frame_range),fps=scene.render.fps,
                              duration_seconds=(r.animation_data.action.frame_range[1]-r.animation_data.action.frame_range[0])/scene.render.fps)
                         for r in rigs if r.animation_data and r.animation_data.action],
                helper_action_count=len(bpy.data.actions)-sum(bool(r.animation_data and r.animation_data.action) for r in rigs))
    if points:record['world_bounds']=[[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)]
    result.append(record)
    print(path.name,'meshes',len(meshes),'bones',[len(r.data.bones) for r in rigs],flush=True)
(WORK/'blender_inspection.json').write_bytes((json.dumps(result,indent=2)+'\n').encode())
print('GOLEM_FBX_INSPECTION_COMPLETE')
