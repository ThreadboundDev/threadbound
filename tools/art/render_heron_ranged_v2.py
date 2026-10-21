"""Background animation preview of the actual saved ranged-heron rig."""
from pathlib import Path
import bpy,math
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/character-quality-v2/heron-motion';OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v2.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['LoomHeron_Rig'];scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True;scene.render.resolution_x=900;scene.render.resolution_y=700;scene.render.resolution_percentage=100
cam=scene.camera;cam.location=(3,-5,2.7);cam.rotation_euler=(Vector((0,0,1.18))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=4.1
frame=0
for clip,duration,samples in [('needle_aim',.85,9),('needle_fire',.35,4),('low_recover',1.1,11)]:
    a=bpy.data.actions[clip];rig.animation_data.action=a;start,end=a.frame_range
    for i in range(samples):
        t=i/max(1,samples-1);scene.frame_set(round(start+(end-start)*t))
        mat=bpy.data.materials.get('Heron | charged thread');mat.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.15+t*t*4 if clip=='needle_aim' else .15
        scene.render.filepath=str(OUT/('%03d.png'%frame));bpy.ops.render.render(write_still=True);frame+=1
print('HERON_RANGED_V2_POSE_FRAMES',frame,flush=True)
