"""Background native model inspection and source-animation previews."""
from pathlib import Path
import bpy,math,sys
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/eave-runner-v3';OUT=WORK/'renders';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];cam=sc.camera
sc.render.engine='CYCLES';sc.cycles.samples=36;sc.cycles.use_denoising=True;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG'
mats={m for o in sc.objects if o.type=='MESH' for m in o.data.materials if m and 'charged thread' in m.name}
def charge(value):
    for m in mats:m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=value
def view(name,clip,frame,position,target,span,res=(1800,2100),samples=36):
    rig.animation_data.action=bpy.data.actions[clip];sc.frame_set(frame);charge(3 if clip in ['wall_windup','throw_windup'] else .18)
    cam.location=position;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=span
    sc.render.resolution_x,sc.render.resolution_y=res;sc.cycles.samples=samples;sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
if '--motion-only' not in sys.argv:
    view('Eave_v3_Beauty','idle',1,(2.6,-5.8,2.25),(0,-.01,.99),2.15)
    view('Eave_v3_Mask_and_Hood','idle',1,(1.5,-4,2.25),(0,-.08,1.65),.68,(1600,1600))
    view('Eave_v3_Hands_and_Bracer','idle',1,(1.2,-4,2.0),(-.30,-.18,1.05),.87,(1600,1800))
    view('Eave_v3_Back','idle',1,(-2,5,2.35),(0,.02,.99),2.15)
    view('Eave_v3_Wall_Perch','wall_perch',20,(3.0,-5,2.25),(0,.02,.98),2.15)
    view('Eave_v3_Jump_Slash','jump_slash',11,(2.6,-5.8,2.25),(0,-.01,1.02),2.3)
    view('Eave_v3_Landing','land_recover',1,(2.6,-5.8,2.25),(0,-.01,.87),2.15)
    view('Eave_v3_Throw','throw_release',4,(2.6,-5.8,2.25),(0,-.01,.99),2.15)
    a=math.radians(72)
    view('Eave_v3_Game_Camera','idle',1,(6*math.sin(a),-6*math.cos(a),1.05),(0,0,1.05),3.8,(1536,1536))
if '--stills-only' not in sys.argv:
    folder=WORK/'motion';folder.mkdir(exist_ok=True)
    cam.location=(2.6,-5.8,2.25);cam.rotation_euler=(Vector((0,-.01,1.0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=2.3
    sc.render.resolution_x=900;sc.render.resolution_y=1050;sc.cycles.samples=12
    index=0
    sequence=[('wall_attach',6),('wall_perch',4),('wall_windup',6),('wall_launch',4),('jump_slash',8),('land_recover',8),('throw_windup',6),('throw_release',6),('land_recover',6)]
    for clip,count in sequence:
        action=bpy.data.actions[clip];rig.animation_data.action=action;start,end=action.frame_range
        for i in range(count):
            t=i/max(1,count-1);sc.frame_set(round(start+(end-start)*t));charge(.18+t*t*4 if clip in ['wall_windup','throw_windup'] else .18)
            sc.render.filepath=str(folder/('%03d.png'%index));bpy.ops.render.render(write_still=True);index+=1
    print('EAVE_V3_MOTION_FRAMES',index,flush=True)
print('EAVE_V3_PREVIEWS_DONE',flush=True)
