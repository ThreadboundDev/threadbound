from pathlib import Path
import bpy,json
R=Path.cwd();bpy.ops.wm.open_mainfile(filepath=str(R/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v2.blend'))
r=bpy.data.objects['EaveRunner_Rig'];r.animation_data.action=None
for p in r.pose.bones:p.location=(0,0,0);p.rotation_quaternion=(1,0,0,0);p.scale=(1,1,1)
print('EAVE_DATA',json.dumps({'bones':{b.name:[list(b.head_local),list(b.tail_local)] for b in r.data.bones if not b.name.startswith(('tail','finger'))},'meshes':[(o.name,len(o.data.vertices),[m.name for m in o.data.materials]) for o in bpy.context.scene.objects if o.type=='MESH'],'actions':[(a.name,list(a.frame_range)) for a in bpy.data.actions]}))
