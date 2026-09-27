"""Create a separate, user-editable IK workspace; never overwrite an existing copy."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'ArtSource/Player/Blender/ManualAttacks/Threadborne_Aerial_Attacks_Workspace.blend'
if DEST.exists():
    raise RuntimeError('Manual workspace already exists; refusing to overwrite user animation.')
DEST.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Air_Light_v3_final.blend'))
scene=bpy.context.scene
rig=bpy.data.objects['Threadborne_Rig']
rig.animation_data.use_nla=False
rig.animation_data.action=bpy.data.actions['jump_1']
scene.frame_set(7)
bpy.context.view_layer.update()
base={b.name:b.matrix_basis.copy() for b in rig.pose.bones}
hand_matrix=rig.pose.bones['hand.R'].matrix.copy()
shoulder=rig.pose.bones['upper_arm.R'].head.copy()
elbow=rig.pose.bones['forearm.R'].head.copy()
wrist=rig.pose.bones['hand.R'].head.copy()
axis=(wrist-shoulder).normalized()
bend=elbow-shoulder
bend=(bend-axis*bend.dot(axis)).normalized()
pole_position=elbow+bend*.6
# Remove only duplicated/reference models in this NEW workspace.
for ob in list(bpy.data.objects):
    if ob.name.startswith('Mixamo_Source') or ob.name=='Threadborne_Source_Duplicate':
        bpy.data.objects.remove(ob,do_unlink=True)
rig.animation_data_clear()
for bone in rig.pose.bones:
    for constraint in list(bone.constraints):
        if constraint.type=='IK': bone.constraints.remove(constraint)
bpy.ops.object.select_all(action='DESELECT')
rig.hide_set(False)
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
ctrl=rig.data.edit_bones.new('CTRL_SwordHand')
ctrl.matrix=hand_matrix
ctrl.length=.16
ctrl.use_deform=False
pole=rig.data.edit_bones.new('CTRL_SwordElbow')
pole.head=pole_position
pole.tail=pole_position+Vector((0,0,.14))
pole.use_deform=False
bpy.ops.object.mode_set(mode='POSE')
for name,matrix in base.items(): rig.pose.bones[name].matrix_basis=matrix
bpy.context.view_layer.update()
ik=rig.pose.bones['forearm.R'].constraints.new('IK')
ik.name='Sword arm - hand and elbow controls'
ik.target=rig
ik.subtarget='CTRL_SwordHand'
ik.pole_target=rig
ik.pole_subtarget='CTRL_SwordElbow'
ik.chain_count=2
ik.use_stretch=False
ik.iterations=100
best=(float('inf'),0)
for i in range(144):
    angle=-math.pi+i*math.tau/144
    ik.pole_angle=angle
    bpy.context.view_layer.update()
    error=(rig.pose.bones['forearm.R'].head-elbow).length
    if error<best[0]:best=(error,angle)
ik.pole_angle=best[1]
rotation=rig.pose.bones['hand.R'].constraints.new('COPY_ROTATION')
rotation.name='Sword orientation from hand control'
rotation.target=rig
rotation.subtarget='CTRL_SwordHand'
rotation.owner_space='POSE'
rotation.target_space='POSE'
bpy.context.view_layer.update()
initial_error=(rig.pose.bones['hand.R'].head-wrist).length
assert initial_error<.01, initial_error

# A wire cube and diamond remain selectable in front of the mesh.
def shape(name,vertices,edges):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,edges,[])
    ob=bpy.data.objects.new(name,mesh)
    scene.collection.objects.link(ob)
    ob.hide_render=True
    ob.hide_set(True)
    return ob
cube=shape('CONTROL_SHAPE_hand',[(x,y,z) for x in [-.5,.5] for y in [-.5,.5] for z in [-.5,.5]],[(a,b) for a in range(8) for b in range(a+1,8) if bin(a^b).count('1')==1])
diamond=shape('CONTROL_SHAPE_elbow',[(0,0,1),(0,0,-1),(1,0,0),(-1,0,0),(0,1,0),(0,-1,0)],[(a,b) for a in [0,1] for b in [2,3,4,5]]+[(2,4),(4,3),(3,5),(5,2)])
for name,obj,palette in [('CTRL_SwordHand',cube,'THEME03'),('CTRL_SwordElbow',diamond,'THEME09')]:
    rig.pose.bones[name].custom_shape=obj
    rig.data.bones[name].color.palette=palette
rig.show_in_front=True
rig.data.display_type='STICK'
for b in rig.data.bones:
    b.hide=b.name not in ['CTRL_SwordHand','CTRL_SwordElbow','pelvis','spine','chest','neck','head','upper_arm.L','forearm.L','hand.L','thigh.R','thigh.L','shin.R','shin.L','foot.R','foot.L']
    rig.pose.bones[b.name].hide=b.hide
    rig.pose.bones[b.name].select=False
rig.pose.bones['CTRL_SwordHand'].select=True
rig.data.bones.active=rig.data.bones['CTRL_SwordHand']

rig.animation_data_create()
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
for name in ['air_attack_forward','air_attack_up','air_attack_down']:
    action=bpy.data.actions.new(name)
    action.use_fake_user=True
    rig.animation_data.action=action
    # Held airborne start/end only; the user authors the attack in between.
    for frame in [1,24]:
        for bone in rig.pose.bones:
            bone.rotation_mode='QUATERNION'
            for prop in ['location','rotation_quaternion','scale']:
                bone.keyframe_insert(prop,frame=frame,group=bone.name)
rig.animation_data.action=bpy.data.actions['air_attack_forward']
scene.render.fps=30
scene.frame_start=1
scene.frame_end=24
scene.frame_set(1)
scene.tool_settings.use_keyframe_insert_auto=False
scene.keying_sets_all.active=next(k for k in scene.keying_sets_all if k.bl_idname=='LocRotScale')
scene.timeline_markers.clear()
for frame,label in [(1,'READY'),(5,'WINDUP'),(8,'CONTACT'),(12,'FOLLOW THROUGH'),(18,'RECOVER'),(24,'END')]:
    scene.timeline_markers.new(label,frame=frame)
preview=bpy.data.objects['Threadborne_Posing_Preview']
preview.hide_set(False)
preview.hide_select=True
for ob in bpy.data.objects:
    if ob.type=='MESH':ob.hide_select=True
# Keep high-resolution art available for a later export, off during posing.
bpy.data.objects['Threadborne_Character'].hide_set(True)
for collection in bpy.data.collections:
    if collection.name.startswith(('REFERENCE','SOURCE','RENDER')):collection.hide_viewport=True
workspace=bpy.data.workspaces.get('Layout')
workspace.name='Aerial Attacks'
if bpy.context.window:bpy.context.window.workspace=workspace
view_rotation=(Vector((0,0,1.0))-Vector((-6,0,1.0))).to_track_quat('-Z','Y')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            space=area.spaces.active
            space.shading.type='MATERIAL'
            space.shading.use_scene_lights=False
            space.shading.use_scene_world=False
            space.overlay.show_floor=False
            space.overlay.show_extras=False
            space.show_region_ui=False
            space.region_3d.view_rotation=view_rotation
            space.region_3d.view_location=Vector((0,0,1.0))
            space.region_3d.view_distance=3.1
            space.region_3d.view_perspective='ORTHO'
        elif area.type=='DOPESHEET_EDITOR':
            area.spaces.active.mode='ACTION'
            area.spaces.active.dopesheet.show_only_selected=False
guide='''AERIAL ATTACK WORKSPACE — START HERE

You are in Pose Mode. Green cube = CTRL_SwordHand. Yellow diamond = CTRL_SwordElbow.
Select the hand cube, G to move it, R to rotate the sword. The arm follows via IK.
In this side view: screen right is global -Y; up is global +Z. R then X sweeps in the gameplay plane.
The elbow diamond controls the bend direction. Move it only when the elbow points the wrong way.
Do not rotate the hidden sword arm bones: the IK controls own that arm.

Choose air_attack_forward / air_attack_up / air_attack_down in the Action Editor below.
These are three blank held-pose templates, not finished attacks. Forward can mirror for west.
At frame 5 make a windup; frame 8 contact; frame 12 follow-through; frame 18 recovery.
After posing, select the controls you changed and press I over the 3D view to insert LocRotScale keys.
Auto Key is OFF. Unkeyed changes disappear when you move to another frame.
Space plays/stops. Ctrl+S saves this separate workspace. Originals/game exports are untouched.

Animate the chest/pelvis a little with R for weight. The sword/shield follow the rig.
Do not move the whole rig object/root for travel: Godot owns the jump and movement.
Change key timing later by selecting keys in the Action Editor and pressing G.
Use Pose Mode, not Edit Mode. Ctrl+Z undoes a bad pose.

When done, tell Codex which action is ready. IK must be baked to deformation bones for export,
and these actions need to replace the runtime directional arm override. Saving alone does not change the game.
'''
text=bpy.data.texts.new('START HERE - Aerial Attacks')
text.write(guide)
rig['manual_workspace']='Three held-pose templates. User authors arcs; do not regenerate over their edits.'
rig['initial_ik_hand_error']=initial_error
bpy.ops.wm.save_as_mainfile(filepath=str(DEST),compress=True)
print('MANUAL_AERIAL_WORKSPACE_READY',json.dumps({'file':str(DEST),'hand_error':initial_error,'pole_angle':best[1],'actions':[a.name for a in bpy.data.actions]}))
