from pathlib import Path
import bpy
from mathutils import Vector
R=Path('C:/Users/chase/Documents/threadbound')
S=R/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'
print('INDEPENDENT_SOURCE',S.stat().st_mtime,S.stat().st_size,flush=True)
bpy.ops.wm.open_mainfile(filepath=str(S))
sc=bpy.context.scene; rig=bpy.data.objects['EaveRunner_Rig'];cam=sc.camera
sc.render.engine='CYCLES';sc.cycles.samples=20;sc.cycles.use_denoising=True
sc.render.resolution_x=1000;sc.render.resolution_y=1200;sc.render.resolution_percentage=100
cam.data.ortho_scale=2.05;cam.location=(2,-5,1.8)
cam.rotation_euler=(Vector((0,0,.94))-cam.location).to_track_quat('-Z','Y').to_euler()
rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1)
for pose in ['POSE','REST']:
 rig.data.pose_position=pose;sc.render.filepath=str(R/'work/eave-runner-v3/renders'/('Independent_10_27_'+pose+'.png'))
 bpy.ops.render.render(write_still=True)
print('INDEPENDENT_REVIEW_READY',flush=True)
