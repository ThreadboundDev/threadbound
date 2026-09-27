"""Build water review actions and a baked animation-only donor for Godot."""
from pathlib import Path
import bpy,json
from mathutils import Matrix
R=Path(__file__).resolve().parents[2];D=R/'ArtSource/Player/Blender/ManualAttacks'
out=D/'Threadborne_Water_Attacks_Workspace.blend'
assert not out.exists()
bpy.ops.wm.open_mainfile(filepath=str(D/'Threadborne_Aerial_Attacks_Directional_v2.blend'))
s=bpy.context.scene;r=bpy.data.objects['Threadborne_Rig'];forward=bpy.data.actions['air_attack_forward']
r.animation_data.action=forward
samples={}
for f in range(1,25):
 s.frame_set(f);bpy.context.view_layer.update();samples[f]=(r.pose.bones['upper_arm.R'].head.copy(),r.pose.bones['CTRL_SwordHand'].matrix.copy(),r.pose.bones['CTRL_SwordElbow'].matrix.copy(),r.pose.bones['pelvis'].location.copy())
idle=forward.copy();idle.name='water_attack_idle';idle.use_fake_user=True
with bpy.data.libraries.load(str(R/'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'),link=False) as (src,dst):dst.actions=['swimming_1']
swim=bpy.data.actions['swimming_1'];r.animation_data.action=swim
poses={}
for f in range(1,25):
 s.frame_set(f);bpy.context.view_layer.update();poses[f]={b.name:b.matrix_basis.copy() for b in r.pose.bones}
move=bpy.data.actions.new('water_attack_move');move.use_fake_user=True;r.animation_data.action=move
for f in range(1,25):
 s.frame_set(f)
 for b in r.pose.bones:b.matrix_basis=poses[f][b.name]
 r.pose.bones['pelvis'].location=samples[f][3]
 bpy.context.view_layer.update();shift=r.pose.bones['upper_arm.R'].head-samples[f][0]
 for name,m in [('CTRL_SwordHand',samples[f][1]),('CTRL_SwordElbow',samples[f][2])]:
  m=m.copy();m.translation+=shift;r.pose.bones[name].matrix=m
 for b in r.pose.bones:
  for prop in ['location','rotation_quaternion','scale']:b.keyframe_insert(prop,frame=f,group=b.name)
s.frame_set(8);s['water_attack_notes']='Idle uses approved forward airborne pose. Moving uses swimming body/legs and the same forward sword-arm target path relative to the shoulder. Runtime blends by swim speed.'
bpy.ops.wm.save_as_mainfile(filepath=str(out),compress=True)
# Cache evaluated bone transforms before removing IK, then key a baked donor.
names=['air_attack_forward','air_attack_up','air_attack_down','water_attack_idle','water_attack_move']
cache={}
for name in names:
 r.animation_data.action=bpy.data.actions[name];cache[name]={}
 for f in range(1,25):
  s.frame_set(f);bpy.context.view_layer.update();cache[name][f]={b.name:b.matrix.copy() for b in r.pose.bones}
for b in r.pose.bones:
 for c in list(b.constraints):b.constraints.remove(c)
for a in list(bpy.data.actions):bpy.data.actions.remove(a)
for name in names:
 a=bpy.data.actions.new(name);a.use_fake_user=True;r.animation_data.action=a
 prev={}
 for f in range(1,25):
  s.frame_set(f)
  for b in r.pose.bones:
   b.matrix=cache[name][f][b.name];bpy.context.view_layer.update()
   if b.name in prev and b.rotation_quaternion.dot(prev[b.name])<0:b.rotation_quaternion.negate()
   prev[b.name]=b.rotation_quaternion.copy()
   for prop in ['location','rotation_quaternion','scale']:b.keyframe_insert(prop,frame=f,group=b.name)
# Only a small skinned mesh is needed to carry the skeleton and bone tracks.
if bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
mesh=bpy.data.objects['Threadborne_Posing_Preview']
for o in [r,mesh]:o.hide_set(False);o.select_set(True)
bpy.context.view_layer.objects.active=r
path=R/'Assets/Threadborne/Player/Equipped3DTest/threadborne_authored_attacks.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_materials='NONE',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True,export_lights=False,export_cameras=False)
print('AUTHORED_ATTACKS_EXPORTED',path)
