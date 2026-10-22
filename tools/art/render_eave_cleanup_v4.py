"""Fresh native Blender views of the separate Eave Runner candidate."""
from pathlib import Path
import bpy, math
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'work/eave-runner-v4/renders'; OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v4.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];cam=scene.camera
scene.render.engine='CYCLES';scene.cycles.samples=18;scene.cycles.use_denoising=True
scene.render.resolution_x=900;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
def view(name,clip,frame,position,target=(0,0,.97),scale=2.15):
    rig.animation_data.action=bpy.data.actions[clip];scene.frame_set(frame)
    cam.location=position;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
    scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
    print('EAVE_V4_RENDER',name,flush=True)
view('Eave_v4_Front','idle',1,(0,-6,1.5))
view('Eave_v4_Back','idle',1,(2,6,1.9))
a=math.radians(72)
view('Eave_v4_GameSide','idle',1,(6*math.sin(a),-6*math.cos(a),1.05))
# Native appearance at the live wrapper's 96 pixels/metre. This matches its
# span/yaw, but is not a Godot screenshot or evidence of GPU material parity.
scene.render.resolution_x=365;scene.render.resolution_y=365
view('Eave_v4_GameReadability','idle',1,(6*math.sin(a),-6*math.cos(a),1.05),target=(0,0,1.05),scale=3.8)
scene.render.resolution_x=900;scene.render.resolution_y=1100
view('Eave_v4_WallPerch','wall_perch',20,(2.6,-5.8,2.25))
view('Eave_v4_JumpSlash','jump_slash',11,(2.6,-5.8,2.25),scale=2.45)
view('Eave_v4_Landing','land_recover',1,(2.6,-5.8,2.25),target=(0,0,.85))
view('Eave_v4_Throw','throw_release',4,(2.6,-5.8,2.25))

# Fresh before views use the same camera, frame and render settings. Opening
# these sources is read-only; no old source or existing delivery is overwritten.
for version in (2,3):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/('ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v%d.blend'%version)))
    scene=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];cam=scene.camera
    scene.render.engine='CYCLES';scene.cycles.samples=18;scene.cycles.use_denoising=True
    scene.render.resolution_x=1100;scene.render.resolution_y=1350;scene.render.resolution_percentage=100
    view('Eave_v%d_Before'%version,'idle',1,(2.6,-5.8,2.25),target=(0,-.01,.99))
