"""Use one constant grip roll for both locomotion clips; no camera-facing constraint."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
target=OUT/'Threadborne_Equipped_Animation_Test.blend'
bpy.ops.wm.open_mainfile(filepath=str(target));s=bpy.context.scene;root=bpy.data.objects['Threadborne_Sword_ROOT']
camera_direction=Vector((-1,0,0));samples=[]
for f in range(78,126):
    s.frame_set(f);m=root.matrix_world.to_3x3().normalized()
    samples.append(((m@Vector((1,0,0))).dot(camera_direction),(m@Vector((0,1,0))).dot(camera_direction)))
def score(angle):
    vals=[a*math.cos(angle)+b*math.sin(angle) for a,b in samples]
    return sum(vals)/len(vals),min(vals)
angle=max([math.radians(i) for i in range(-180,181)],key=lambda a:score(a)[0])
print('ROLL_DEGREES',math.degrees(angle),'BEFORE',score(0),'AFTER',score(angle),flush=True)
if '--apply' not in __import__('sys').argv:raise SystemExit
s.frame_set(1);root.matrix_basis=root.matrix_basis@Matrix.Rotation(angle,4,'Z')
root['readability_roll_degrees']=float(root.get('readability_roll_degrees',0))+math.degrees(angle)
root['readability_note']='Constant local grip-axis roll shared by idle/run/jump; optimized for side-camera visibility over run and jump. No per-clip sword rotation keys.'
bpy.ops.wm.save_as_mainfile(filepath=str(target))
(OUT/'sword_readability_report.json').write_text(json.dumps({'added_roll_degrees':math.degrees(angle),'before_mean_min':score(0),'after_mean_min':score(angle),'same_attachment_all_clips':True},indent=2))
