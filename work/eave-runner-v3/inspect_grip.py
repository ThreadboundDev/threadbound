import bpy,json
from pathlib import Path
R=Path('C:/Users/chase/Documents/threadbound')
bpy.ops.wm.open_mainfile(filepath=str(R/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
r=bpy.data.objects['EaveRunner_Rig'];r.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
for n in ['forearm.R','hand.R','blade']+['finger%d-%d.R'%(i,j) for i in range(1,6) for j in range(1,4)]:
 b=r.pose.bones[n];print('POSE_BONE',n,list(b.head),list(b.tail),flush=True)
for o in bpy.context.scene.objects:
 if 'Short blade wrapped handle' in o.name:
  ob=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ob.to_mesh();v=[o.matrix_world@p.co for p in me.vertices]
  print('HANDLE_BOUNDS',[[min(p[i] for p in v),max(p[i] for p in v)] for i in range(3)],flush=True)
