"""Verify real socket/glove geometry, preserved curves, and swimming feet."""
from pathlib import Path
import bpy
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]

def curves():
    result = {}
    for action in bpy.data.actions:
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for fc in bag.fcurves:
                        result[(action.name, fc.data_path, fc.array_index)] = [
                            (tuple(k.co), tuple(k.handle_left), tuple(k.handle_right), k.interpolation)
                            for k in fc.keyframe_points]
    return result

bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v3.blend'))
old = curves()
old_shell = bpy.data.objects['Bellstriker_Shell']
def rear_weights(mesh):
    return {tuple(v.co): sorted((mesh.vertex_groups[g.group].name, round(g.weight, 6)) for g in v.groups if g.weight > 0)
            for v in mesh.data.vertices if v.co.x < -.10}
rear = rear_weights(old_shell)
original_faces = sum(len(bpy.data.objects[n].data.polygons) for n in ['Bellstriker_Shell', 'Bellstriker_Claw_L', 'Bellstriker_Claw_R'])
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v4.blend'))
assert rear == rear_weights(bpy.data.objects['Bellstriker_Shell']), 'Accepted rear-body skin must remain unchanged'
assert original_faces == sum(len(bpy.data.objects[n].data.polygons) for n in ['Bellstriker_Shell', 'Bellstriker_Claw_L', 'Bellstriker_Claw_R']), 'Preserve all supplied surface faces'
for mesh in [o for o in bpy.context.scene.objects if o.type == 'MESH']:
    assert all(abs(sum(g.weight for g in v.groups)-1.0) < .0001 for v in mesh.data.vertices), mesh.name
print('PASS original surface faces, rear-body skin, and normalized vertex weights')
new = curves()
assert old.keys() == new.keys()
changed = 0
for (clip, path, index), values in old.items():
    editable = clip in ['swim', 'swim_idle'] and any(f'pose.bones["{p}.' in path for p in ['leg', 'shin', 'toe']) and path.endswith('rotation_quaternion')
    if editable:
        changed += values != new[(clip, path, index)]
    else:
        assert values == new[(clip, path, index)], ('Original curve changed', clip, path)
assert changed > 100
print('PASS original body/tail/combat curves preserved; swim limb rotation curves changed', changed)

rig = bpy.data.objects['Bellstriker_Rig']
scene = bpy.context.scene
assert len(rig.data.bones) == 44
rig.data.pose_position = 'REST'
bpy.context.view_layer.update()
for side in ['L', 'R']:
    claw = bpy.data.objects['Bellstriker_Claw_'+side]
    bridge = bpy.data.objects['Bellstriker_Wrist_Bridge_'+side]
    socket = bpy.data.objects['Bellstriker_Wrist_Socket_'+side]
    bvh = BVHTree.FromObject(claw, bpy.context.evaluated_depsgraph_get())
    gap = min(bvh.find_nearest(v.co)[3] for v in bridge.data.vertices)
    assert gap < .04, ('Bridge must reach glove surface', side, gap)
    for mesh in [bridge, socket, claw]:
        assert {mesh.vertex_groups[g.group].name for v in mesh.data.vertices for g in v.groups if g.weight > .001} == {'claw.'+side}
    bvh = BVHTree.FromObject(socket, bpy.context.evaluated_depsgraph_get())
    forearm = bpy.data.objects['Bellstriker_Joint_forearm.'+side]
    arm_gap = min(bvh.find_nearest(v.co)[3] for v in forearm.data.vertices)
    assert arm_gap < .04, ('Socket must overlap forearm', side, arm_gap)
    print('PASS wrist surface continuity', side, 'glove gap', gap, 'forearm gap', arm_gap)
rig.data.pose_position = 'POSE'
for clip in ['box_idle', 'charge_1', 'charge_2', 'charge_3', 'jab', 'cross', 'smash', 'box_recover',
             'water_charge_1', 'water_charge_2', 'water_charge_3', 'water_jab', 'water_cross', 'water_smash', 'water_box_recover']:
    action = bpy.data.actions[clip]
    rig.animation_data.action = action
    for frame in range(int(action.frame_range[0]), int(action.frame_range[1])+1):
        scene.frame_set(frame)
        for side in ['L', 'R']:
            assert (rig.pose.bones['forearm.'+side].tail-rig.pose.bones['claw.'+side].head).length < .0001, (clip, frame, side)
print('PASS both wrist sockets remain attached at every land/water combo frame')
for clip in ['swim', 'swim_idle']:
    action = bpy.data.actions[clip]
    rig.animation_data.action = action
    first, last = map(int, action.frame_range)
    names = [f'toe.{i}.{side}' for side in ['L', 'R'] for i in range(4)]
    scene.frame_set(first)
    starts = {n: rig.pose.bones[n].rotation_quaternion.copy() for n in names}
    scene.frame_set(last)
    assert all(abs(starts[n].dot(rig.pose.bones[n].rotation_quaternion)) > .999999 for n in names)
    spans = {n: 0.0 for n in names}
    for fraction in [.25, .50, .75]:
        scene.frame_set(first+round((last-first)*fraction))
        for n in names:
            spans[n] = max(spans[n], starts[n].rotation_difference(rig.pose.bones[n].rotation_quaternion).angle)
    assert all(span > .02 for span in spans.values()), spans
    print('PASS every foot moves with seamless loop', clip)
print('BELL_ATTACHMENT_SOURCE_CHECKS_PASS')
