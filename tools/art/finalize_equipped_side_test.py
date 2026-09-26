"""Fit sword inside animated fist and prepare fixed side-on orthographic review."""
import bpy,math,json,numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
target=OUT/'Threadborne_Equipped_Animation_Test.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
s=bpy.context.scene;rig=bpy.data.objects['Threadborne_Rig'];sword=bpy.data.objects['Threadborne_Sword_ROOT'];cam=s.camera
report=json.loads((OUT/'animation_test_report.json').read_text())
def grip_fit():
    # Fit the handle axis through the curled fingers, not halfway along the hand bone.
    axis=(rig.pose.bones['index.01.R'].head-rig.pose.bones['pinky.01.R'].head).normalized()
    points=[]
    for finger in ['index','middle','ring','pinky']:
        points.extend(rig.pose.bones[finger+'.%02d.R'%i].head.copy() for i in [1,2,3])
        points.append(rig.pose.bones[finger+'.03.R'].tail.copy())
    origin=sum(points,Vector())/len(points)
    u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u).normalized()
    xy=np.array([[(p-origin).dot(u),(p-origin).dot(v)] for p in points])
    a=np.column_stack((2*xy[:,0],2*xy[:,1],np.ones(len(xy))))
    fit=np.linalg.lstsq(a,(xy*xy).sum(axis=1),rcond=None)[0]
    center=origin+u*float(fit[0])+v*float(fit[1])
    return center,axis
s.frame_set(1);bpy.context.view_layer.update();center,blade=grip_fit()
z=-blade;x=Vector((-1,0,0));x=(x-z*x.dot(z)).normalized();y=z.cross(x)
rotation=Matrix((x,y,z)).transposed().to_4x4()
desired=Matrix.Translation(center)@rotation@Matrix.Diagonal((.92,.92,.92,1))
desired=desired@Matrix.Rotation(math.radians(float(sword.get('readability_roll_degrees',0))),4,'Z')
sword.matrix_basis=sword.parent.matrix_world.inverted()@desired
sword['grip_note']='Grip centered by fitting the curled finger chain. Blade points from pinky toward index/thumb, not toward the pommel.'
errors=[];dots=[]
for frame in range(s.frame_start,s.frame_end+1):
    s.frame_set(frame);c,a=grip_fit();actual=sword.matrix_world.translation
    errors.append((actual-c).length)
    direction=(sword.matrix_world.to_3x3()@Vector((0,0,-1))).normalized();dots.append(direction.dot(a))
print('SWORD_GRIP_CHECK',max(errors),min(dots),flush=True)
def side_camera():
    center=Vector((0,0,1.275));cam.location=center+Vector((-6,0,0));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    s.render.resolution_x=900;s.render.resolution_y=1200;s.render.resolution_percentage=100
    cam.data.type='ORTHO';cam.data.ortho_scale=3
    corners=cam.data.view_frame(scene=s);height=max(p.y for p in corners)-min(p.y for p in corners)
    cam.data.ortho_scale*=3/height
side_camera();s.frame_set(1)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            space=area.spaces.active;space.region_3d.view_rotation=cam.rotation_euler.to_quaternion();space.region_3d.view_location=Vector((0,0,1.05));space.region_3d.view_perspective='ORTHO'
s['camera_note']='True side view from -X, zero elevation, orthographic. Forward -Y reads right on screen. Fixed 400 source px/m.'
bpy.ops.wm.save_as_mainfile(filepath=str(target))
metrics={'max_grip_center_error_m':max(errors),'min_blade_axis_alignment':min(dots),'camera':'orthographic side -X','canvas':[900,1200],'standing_source_height':720}
(OUT/'side_grip_validation.json').write_text(json.dumps(metrics,indent=2))
for label in ['Idle','Run','Jump']:
    start,end=report[label]['timeline'];s.frame_set(start+(end-start)//2)
    s.render.filepath=str(OUT/(label.lower()+'_equipped.png'));bpy.ops.render.render(write_still=True)
    center,_=grip_fit();cam.location=center+Vector((-2,0,0));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.25
    s.render.resolution_x=s.render.resolution_y=600;s.render.filepath=str(OUT/(label.lower()+'_grip_check.png'));bpy.ops.render.render(write_still=True)
    side_camera()
frames=OUT/'preview_frames';frames.mkdir(exist_ok=True)
s.render.resolution_percentage=25;s.cycles.samples=8
manifest=[]
for label in ['Idle','Run','Jump']:
    start,end=report[label]['timeline'];count=math.ceil((end-start+1)*12/30)
    for i in range(count):
        frame=min(end,start+round(i*30/12));s.frame_set(frame)
        name=label.lower()+'_%03d.png'%i;s.render.filepath=str(frames/name);bpy.ops.render.render(write_still=True)
        manifest.append({'clip':label,'frame':frame,'file':name,'duration_ms':round((end-start+1)/30/count*1000)})
    print('SIDE_PREVIEW_COMPLETE',label,count,flush=True)
(OUT/'preview_manifest.json').write_text(json.dumps(manifest,indent=2))
print('SIDE_AND_GRIP_COMPLETE',flush=True)
