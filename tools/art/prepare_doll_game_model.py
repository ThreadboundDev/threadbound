"""Fit the local Rigify doll to the game's animation rig; preserve input files.

Run in Blender 5.2 background mode. Character outputs stay local for review.
The game skeleton's bases/hierarchy and source actions are retained; its joint
origins are fitted to the doll. Donor animations need rest-position rebasing.
"""
from pathlib import Path
import bpy
import json
import math
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'ArtSource/Player/Blender/PaleDollStudy/RigifyDollPrototype/Threadborne_Doll_Rigify_WIP.blend'
OUT = ROOT / 'ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll'
EXPORT = ROOT / 'Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb'
OUT.mkdir(parents=True, exist_ok=True)
EXPORT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version = 0
body = next(o for o in bpy.context.scene.objects if o.type == 'MESH' and len(o.data.vertices) == 25022)
prototype = next(m.object for m in body.modifiers if m.type == 'ARMATURE')
prototype.data.pose_position = 'REST'
scale = 1.9
offset = Vector((0, -.04, 0))
turn = Matrix.Rotation(math.pi/2, 3, 'X')

def point(p, hand_side=None):
    p = p.copy()
    if hand_side:
        wrist = prototype.data.bones['DEF-hand.'+hand_side].head_local
        p = wrist + turn @ (p-wrist)
    return (p+offset)*scale

mapping = {'DEF-spine':'pelvis', 'DEF-spine.003':'chest', 'DEF-spine.006':'head'}
for side in 'LR':
    for part in ['upper_arm','forearm','hand','thigh','shin','foot']:
        mapping[f'DEF-{part}.{side}'] = f'{part}.{side}'
    for digit in ['index','middle','ring','pinky','thumb']:
        for seg in range(1,4):
            prefix = 'thumb' if digit == 'thumb' else 'f_'+digit
            mapping[f'DEF-{prefix}.{seg:02d}.{side}'] = f'{digit}.{seg:02d}.{side}'

heads = {}
for src,dst in mapping.items():
    hand_side = dst[-1] if dst.split('.')[0] in ['index','middle','ring','pinky','thumb'] else None
    heads[dst] = point(prototype.data.bones[src].head_local,hand_side)
heads['spine'] = point(Vector((0,.04,.60)))
heads['neck'] = point(Vector((0,.04,.83)))
for side in 'LR':
    heads['clavicle.'+side] = point(prototype.data.bones['ORG-shoulder.'+side].head_local)
    heads['toe.'+side] = point(prototype.data.bones['DEF-toe.'+side].head_local)

# Bake only the rest orientation of the palms. Body proportions and texture stay
# intact; facing palms become downward palms to match the game's hand convention.
weights = []
for v in body.data.vertices:
    entries = [(mapping[body.vertex_groups[g.group].name],g.weight) for g in v.groups if g.weight>1e-7]
    assert entries and all(math.isfinite(w) for _,w in entries)
    side = next((name[-1] for name,w in entries if name.split('.')[0] in ['hand','index','middle','ring','pinky','thumb']),None)
    p = body.matrix_world @ v.co
    v.co = point(p, side)
    entries = sorted(entries,key=lambda item:item[1],reverse=True)[:4]
    total = sum(w for _,w in entries)
    weights.append([(name,w/total) for name,w in entries])
body.parent = None
body.matrix_world = Matrix.Identity(4)
body.modifiers.clear()
body.vertex_groups.clear()
body.name = 'Threadborne_Doll'
for name in sorted({name for entries in weights for name,w in entries}):
    body.vertex_groups.new(name=name)
for v,entries in zip(body.data.vertices,weights):
    for name,w in entries:
        body.vertex_groups[name].add([v.index],w,'REPLACE')
for obj in list(bpy.data.objects):
    if obj != body:
        bpy.data.objects.remove(obj,do_unlink=True)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
bpy.context.scene.render.fps = 30
bpy.ops.import_scene.gltf(filepath=str(ROOT/'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
rig.animation_data.action = None
for track in rig.animation_data.nla_tracks:
    track.mute = True
for pb in rig.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
rig.data.pose_position = 'REST'
bpy.context.view_layer.update()
rest = {b.name:b.matrix_local.copy() for b in rig.data.bones}
# Socket offsets are expressed in the unchanged hand basis, so original weapon
# root transforms stay valid after the hand joint is moved.
for side in 'LR':
    for socket,anchor in [('weapon_socket','hand'),('hand_target','hand'),('foot_target','foot')]:
        n=socket+'.'+side; a=anchor+'.'+side
        heads[n] = heads[a] + rest[n].translation-rest[a].translation
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for bone in rig.data.edit_bones:
    bone.use_connect = False
for bone in rig.data.edit_bones:
    if bone.name in heads:
        delta = heads[bone.name]-bone.head
        bone.head += delta
        bone.tail += delta
bpy.ops.object.mode_set(mode='OBJECT')
for obj in list(bpy.data.objects):
    if obj.name in ['Threadborne_Character','Icosphere']:
        bpy.data.objects.remove(obj,do_unlink=True)
body.parent = rig
mod = body.modifiers.new('Game skeleton','ARMATURE')
mod.object = rig
rig.data.pose_position = 'POSE'
actions = {a.name: list(a.frame_range) for a in bpy.data.actions}
assert len(actions)==48
assert len(rig.data.bones)==62
assert max(abs(sum(g.weight for g in v.groups)-1) for v in body.data.vertices)<1e-5
assert max(len(v.groups) for v in body.data.vertices)<=4
assert all(n in rig.data.bones for n in mapping.values())
for bone in rig.data.bones:
    assert (bone.matrix_local.to_quaternion().rotation_difference(rest[bone.name].to_quaternion())).angle<.001

# The doll has longer, articulated fingers than the donor glove. Add a small
# local curl to its middle/distal joints while retaining each animated gesture.
# Only this export's copies of the action data are edited.
for action in bpy.data.actions:
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for side in 'LR':
                    for digit in ['index','middle','ring','pinky']:
                        for seg,degrees in [(1,-8),(2,-22),(3,-28)]:
                            path=f'pose.bones["{digit}.{seg:02d}.{side}"].rotation_quaternion'
                            curves={fc.array_index:fc for fc in bag.fcurves if fc.data_path==path}
                            if len(curves)!=4: continue
                            times=sorted({float(k.co.x) for fc in curves.values() for k in fc.keyframe_points})
                            values={t:Quaternion(tuple(curves[i].evaluate(t) for i in range(4))) @ Quaternion((1,0,0),math.radians(degrees)) for t in times}
                            for i,fc in curves.items():
                                for key in fc.keyframe_points:
                                    delta=values[float(key.co.x)][i]-key.co.y
                                    key.co.y+=delta
                                    key.handle_left.y+=delta
                                    key.handle_right.y+=delta

# Import places action strips in muted NLA tracks. Export each source action once.
for track in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(track)
rig.animation_data.action = bpy.data.actions['idle_4']
rig.animation_data.action_slot = bpy.data.actions['idle_4'].slots[0]
bpy.context.scene.frame_set(1)
for image in bpy.data.images:
    if image.source=='FILE' and not image.packed_file:
        image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Threadborne_Doll_GameReady.blend'),compress=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(EXPORT),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,
    export_skins=True,export_cameras=False,export_lights=False,export_materials='EXPORT')
report = {'source':str(SOURCE.relative_to(ROOT)),'bones':62,'actions':actions,
    'vertices':len(body.data.vertices),'triangles':sum(len(p.vertices)-2 for p in body.data.polygons),
    'maximum_influences':max(len(v.groups) for v in body.data.vertices),
    'maximum_weight_sum_error':max(abs(sum(g.weight for g in v.groups)-1) for v in body.data.vertices),
    'bone_map':mapping,'scale':scale,'rest_basis_preserved':True,
    'finger_curl_degrees':{'proximal':-8,'middle':-22,'distal':-28},
    'export':str(EXPORT.relative_to(ROOT))}
(OUT/'build_report.json').write_text(json.dumps(report,indent=2))
print('DOLL_GAME_EXPORT_COMPLETE',flush=True)
