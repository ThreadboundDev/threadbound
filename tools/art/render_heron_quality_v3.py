"""Native model inspection views and a ranged motion loop, without GUI use."""
from pathlib import Path
import bpy,math,sys,json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/loom-heron-v3/renders';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v3.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['LoomHeron_Rig'];cam=sc.camera
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True
sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG'
charge_materials={m for o in sc.objects if o.type=='MESH' for m in o.data.materials if m and 'charged thread' in m.name}
def charge_strength(value):
    for mat in charge_materials:mat.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=value
def view(name,clip,frame,pos,target,span,res=(1800,1400),samples=32):
    rig.animation_data.action=bpy.data.actions[clip];sc.frame_set(frame)
    charge_strength(4 if clip=='needle_aim' else .18)
    target=Vector(target);cam.location=pos;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span
    sc.cycles.samples=samples;sc.render.resolution_x=res[0];sc.render.resolution_y=res[1]
    sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
if '--motion' not in sys.argv and '--charge-only' not in sys.argv:
    view('Heron_v3_Beauty','idle',1,(3,-5,2.6),(0,0,1.12),4.1)
    view('Heron_v3_Head_and_Craft','idle',1,(2,-4,2.7),(0,-.20,1.38),1.45,(1600,1600))
    view('Heron_v3_Rear','idle',1,(-3,5,2.8),(0,.04,1.12),4.0)
    view('Heron_v3_Perched','perch',1,(3,-5,2.6),(0,0,1.05),3.2)
    # Camera geometry matches the existing Godot prefab. Blender lighting is
    # still used: this is a scale/readability preview, not an in-game capture.
    a=math.radians(52)
    view('Heron_v3_Game_Camera','flight',1,(6*math.sin(a),-6*math.cos(a),1.05),(0,0,1.05),4.6,(1536,1536))
    view('Heron_v3_Aim','needle_aim',25,(3,-5,2.6),(0,0,1.12),4.1)
elif '--charge-only' in sys.argv:
    view('Heron_v3_Aim','needle_aim',25,(3,-5,2.6),(0,0,1.12),4.1)
if '--stills-only' not in sys.argv:
    frames=ROOT/'work/loom-heron-v3/motion';frames.mkdir(exist_ok=True)
    target=Vector((0,0,1.12));cam.location=(3,-5,2.6);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=4.1
    sc.render.resolution_x=1000;sc.render.resolution_y=780;sc.cycles.samples=12
    f=0
    for clip,num in [('flight',12),('needle_aim',10),('needle_fire',5),('low_recover',12)]:
        if '--charge-only' in sys.argv and clip!='needle_aim':
            f+=num;continue
        a=bpy.data.actions[clip];rig.animation_data.action=a;start,end=a.frame_range
        for i in range(num):
            t=i/max(1,num-1);sc.frame_set(round(start+(end-start)*t))
            charge_strength(.18+t*t*4 if clip=='needle_aim' else .18)
            sc.render.filepath=str(frames/('%03d.png'%f));bpy.ops.render.render(write_still=True);f+=1
    print('HERON_V3_MOTION',f,flush=True)
print('HERON_V3_VIEWS_DONE',flush=True)
