from pathlib import Path
import bpy
from mathutils import Vector
R=Path('C:/Users/chase/Documents/threadbound')
bpy.ops.wm.open_mainfile(filepath=str(R/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];cam=sc.camera
sc.render.engine='CYCLES';sc.cycles.samples=16;sc.cycles.use_denoising=True
sc.render.resolution_x=1000;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
cam.data.ortho_scale=1.05;cam.location=(2,-5,1.8)
cam.rotation_euler=(Vector((0,0,1.32))-cam.location).to_track_quat('-Z','Y').to_euler()
rig.animation_data.action=None;rig.data.pose_position='REST';sc.frame_set(1)
hidden=[]
for ob in sc.objects:
 if 'Finished tunic and cowl cut hem' in ob.name: ob.hide_render=True;hidden.append(ob.name)
print('HIDDEN_HEMS',hidden,flush=True)
for m in bpy.data.materials:
 if m.node_tree:
  for n in m.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=0
sc.render.filepath=str(R/'work/eave-runner-v3/renders/Independent_Diagnostic_NoHem_NoNormal.png');bpy.ops.render.render(write_still=True)
