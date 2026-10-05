"""Bake editable swim-idle-based combo actions and a separate Godot donor.
Run with Blender --background --python tools/art/build_water_combo.py.
Existing manual workspaces are never overwritten.
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_v1.blend'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Save your manual edits separately before regenerating; --replace-generated replaces the generated workspace.'
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Attacks_Workspace.blend'))
rig = bpy.data.objects['Threadborne_Rig']
scene = bpy.context.scene
scene.render.fps = 30
with bpy.data.libraries.load(str(ROOT / 'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'), link=False) as (src, dst):
    dst.actions = ['water_idle_1']
idle = dst.actions[0]
slash = bpy.data.actions['water_attack_idle']
bones = list(rig.pose.bones)

def sample(action, frame):
    rig.animation_data.action = action
    scene.frame_set(int(frame), subframe=frame-int(frame))
    bpy.context.view_layer.update()
    return {b.name: b.matrix.copy() for b in bones}

def localize(pose):
    return {b.name: pose[b.parent.name].inverted() @ pose[b.name] if b.parent else pose[b.name] for b in bones}

base = sample(idle, 1)
idle_local = localize(base)
arm_names = {'upper_arm.R', 'forearm.R', 'hand.R'}
arm_names.update(b.name for b in bones if b.name.endswith('.R') and any(s in b.name.lower() for s in ['finger', 'thumb', 'index', 'middle', 'ring', 'pinky']))
cache = {}
for step, frames in enumerate([19, 25, 31]):
    name = f'water_combo_{step+1}'
    cache[name] = {}
    for frame in range(1, frames+1):
        t = (frame-1)/(frames-1)
        envelope = min(1.0, t/0.22, (1-t)/0.22)
        source = localize(sample(slash, 1 + t*23 if step == 0 else 8))
        pose = {}
        for b in bones:
            local = idle_local[b.name].lerp(source[b.name], envelope) if b.name in arm_names else idle_local[b.name].copy()
            pose[b.name] = pose[b.parent.name] @ local if b.parent else local
        # Blender Z is upright; X is the side camera axis. Rotate about the
        # pelvis, never the feet, to keep a stationary swimmer centered.
        if step > 0:
            progress = max(0.0, min(1.0, (t-0.18)/0.64))
            progress = progress*progress*(3-2*progress)
            pivot = base['pelvis'].translation
            angle = (-1 if step == 1 else 1) * math.tau * progress
            turn = Matrix.Translation(pivot) @ Matrix.Rotation(angle, 4, 'Z' if step == 1 else 'X') @ Matrix.Translation(-pivot)
            pose = {name: turn @ matrix for name, matrix in pose.items()}
        cache[name][frame] = pose

# Bake evaluated transforms, including the source sword IK, into editable keys.
for b in bones:
    for constraint in list(b.constraints):
        b.constraints.remove(constraint)
rig.animation_data.action = None
for track in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(track)
for name, frames in cache.items():
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    previous = {}
    for frame, pose in frames.items():
        scene.frame_set(frame)
        for b in bones:
            b.rotation_mode = 'QUATERNION'
            b.matrix = pose[b.name]
            bpy.context.view_layer.update()
            if b.name in previous and b.rotation_quaternion.dot(previous[b.name]) < 0:
                b.rotation_quaternion.negate()
            previous[b.name] = b.rotation_quaternion.copy()
            for prop in ['location', 'rotation_quaternion', 'scale']:
                b.keyframe_insert(prop, frame=frame, group=b.name)
rig.animation_data.action = bpy.data.actions['water_combo_1']
scene.frame_start = 1
scene.frame_end = 19
scene.frame_set(1)
scene['water_combo_notes'] = '30 FPS: water_combo_1 frames 1-19 front slash; water_combo_2 1-25 horizontal spin; water_combo_3 1-31 front flip. Swim-idle body, fixed pelvis. Each action is baked and editable. Export only these three clips to threadborne_water_combo.glb.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
# Keep only combo actions in the export session; the saved workspace retains
# source actions for reference. Export the small preview mesh and its skeleton.
for action in list(bpy.data.actions):
    if action.name not in cache:
        bpy.data.actions.remove(action)
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
mesh = bpy.data.objects['Threadborne_Posing_Preview']
for obj in [rig, mesh]:
    obj.hide_set(False)
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(ROOT / 'Assets/Threadborne/Player/Equipped3DTest/threadborne_water_combo.glb'), export_format='GLB', use_selection=True, export_materials='NONE', export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True, export_skins=True, export_lights=False, export_cameras=False)
print('WATER_COMBO_EXPORTED', DEST)
