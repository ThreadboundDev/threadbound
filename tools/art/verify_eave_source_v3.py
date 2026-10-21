"""Inspect the saved, editable Eave Runner source using background Blender.

Run: blender --background --factory-startup --python THIS_FILE -- [--source FILE]
Checks data, deformation and retained rig contracts; does not judge art quality.
"""
from pathlib import Path
import argparse
import json
import math
import sys

import bpy


ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/eave-runner-v3'
CLIPS = ('idle', 'run', 'wall_attach', 'wall_perch', 'wall_windup',
         'wall_launch', 'jump_slash', 'land_recover', 'throw_windup',
         'throw_release', 'hurt', 'death')
LOOPS = {'idle', 'run', 'wall_perch'}
EXPECTED_BONES = {'root', 'pelvis', 'spine', 'chest', 'neck', 'head',
                  'blade', 'held_pin'}
for side in ('L', 'R'):
    EXPECTED_BONES.update(name + '.' + side for name in (
        'clavicle', 'upper_arm', 'forearm', 'hand', 'thigh', 'shin', 'foot', 'toe'))
    EXPECTED_BONES.update('finger%d-%d.%s' % (digit, segment, side)
                          for digit in range(1, 6) for segment in range(1, 4))
    EXPECTED_BONES.update('tail_%s_%d' % (side, index) for index in range(1, 4))
checks = 0
failures = []


def check(ok, message):
    global checks
    checks += 1
    if not ok:
        failures.append(message)
        print('EAVE_V3_SOURCE_FAIL', message, flush=True)


def finite(values):
    return all(math.isfinite(value) for value in values)


def snapshot(rig):
    return {pose.name: pose.matrix.copy() for pose in rig.pose.bones}


def matrix_error(a, b):
    return max(abs(a[row][column] - b[row][column])
               for row in range(4) for column in range(4))


def bounds(points):
    return ([min(point[axis] for point in points) for axis in range(3)],
            [max(point[axis] for point in points) for axis in range(3)])


def evaluated_positions(meshes):
    dependency_graph = bpy.context.evaluated_depsgraph_get()
    return {obj.name: [obj.matrix_world @ vertex.co for vertex in
                      obj.evaluated_get(dependency_graph).data.vertices]
            for obj in meshes}


def hand_radius(positions, indices, rig, side, posed):
    center = rig.matrix_world @ (rig.pose.bones['hand.' + side].matrix.translation
                                 if posed else rig.data.bones['hand.' + side].head_local)
    return max(((positions[name][index] - center).length
                for name, entries in indices.items() for index in entries[side]), default=0)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, default=(
        ROOT / 'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
    arguments = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    WORK.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(arguments.source))
    rigs = [obj for obj in bpy.data.objects if obj.type == 'ARMATURE' and 'EaveRunner' in obj.name]
    check(len(rigs) == 1, 'Exactly one Eave Runner armature exists')
    if not rigs:
        return finish({'source': str(arguments.source)})
    rig = rigs[0]
    scene = rig.users_scene[0]
    bpy.context.window.scene = scene
    meshes = [obj for obj in scene.objects if obj.type == 'MESH' and any(
        modifier.type == 'ARMATURE' and modifier.object == rig for modifier in obj.modifiers)]
    check(bool(meshes), 'Visible character geometry uses the retained armature')
    check(set(rig.data.bones.keys()) == EXPECTED_BONES, 'All 60 named rig bones are retained')
    check(not any(pose.constraints for pose in rig.pose.bones), 'Runtime rig requires no live authoring constraints')
    check(rig.data.bones['blade'].parent.name == 'hand.R', 'Blade remains parented to the right hand')
    check(rig.data.bones['held_pin'].parent.name == 'hand.L', 'Held pin remains parented to the left hand')
    triangles = sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons)
    vertices = sum(len(obj.data.vertices) for obj in meshes)
    check(triangles > 0 and vertices > 0, 'Source contains render geometry')
    materials, images = set(), set()
    hand_indices = {}
    weapon_vertices = 0
    for obj in meshes:
        data = obj.data
        check(bool(data.uv_layers), obj.name + ': UV map exists')
        if data.uv_layers:
            uv_points = [entry.uv for entry in data.uv_layers.active.data]
            check(len(uv_points) == len(data.loops) and all(finite(uv) for uv in uv_points),
                  obj.name + ': Every mesh corner has finite UVs')
            check(bool(uv_points) and any((uv - uv_points[0]).length > 1e-6 for uv in uv_points),
                  obj.name + ': UV map is not collapsed')
        check(all(finite(vertex.co) and finite(vertex.normal) and vertex.normal.length > .8
                  for vertex in data.vertices), obj.name + ': Positions and normals are finite and nonzero')
        valid_weights = True
        hand_indices[obj.name] = {'L': [], 'R': []}
        for vertex in data.vertices:
            groups = [(obj.vertex_groups[group.group].name, group.weight)
                      for group in vertex.groups if group.weight > 1e-7]
            if not (1 <= len(groups) <= 4 and abs(sum(weight for _, weight in groups) - 1) < .0002
                    and all(name in EXPECTED_BONES and math.isfinite(weight) for name, weight in groups)):
                valid_weights = False
            if not groups:
                continue
            strongest = max(groups, key=lambda item: item[1])[0]
            for side in ('L', 'R'):
                if strongest == 'hand.' + side or (strongest.startswith('finger') and strongest.endswith('.' + side)):
                    hand_indices[obj.name][side].append(vertex.index)
            weapon_vertices += strongest == 'blade'
        check(valid_weights, obj.name + ': Every vertex has 1–4 normalized valid bone influences')
        for material in data.materials:
            if material:
                materials.add(material)
                if material.use_nodes:
                    images.update(node.image for node in material.node_tree.nodes
                                  if node.type == 'TEX_IMAGE' and node.image)
    check(bool(images), 'Component materials reference texture maps')
    check(all(image.packed_file for image in images if image.source == 'FILE'),
          'All referenced file textures are packed into the editable source')
    check(sum(1 for image in images if min(image.size) >= 4096) >= 3,
          'High-resolution component maps remain available')
    check(weapon_vertices >= 20, 'Modeled weapon geometry is weighted to the blade attachment')

    rig.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    positions = evaluated_positions(meshes)
    points = [point for values in positions.values() for point in values]
    low, high = bounds(points)
    span = [high[index] - low[index] for index in range(3)]
    check(1.6 <= span[2] <= 2.05, 'Rest height remains at the established character scale')
    check(-.1 <= low[2] <= .15, 'Feet remain at the established floor origin')
    check(max(span) < 3.2, 'Rest geometry stays within the established camera framing')
    hand_rows = {}
    for side in ('L', 'R'):
        count = sum(len(entries[side]) for entries in hand_indices.values())
        radius = hand_radius(positions, hand_indices, rig, side, False)
        check(count >= 100, side + ': Modeled hand and finger geometry exists')
        check(.025 < radius < .34, side + ': Rest hand geometry stays close to its wrist without spikes')
        hand_rows[side] = {'vertices': count, 'rest_wrist_radius': radius, 'maximum_animated_wrist_radius': 0}
    rig.data.pose_position = 'POSE'
    rig.animation_data_create()
    clips = []
    for name in CLIPS:
        action = bpy.data.actions.get(name)
        check(action is not None, name + ': Existing clip retained')
        if action is None:
            continue
        rig.animation_data.action = action
        start, end = action.frame_range
        check(end > start, name + ': Clip has positive duration')
        scene.frame_set(int(start), subframe=start % 1)
        initial = snapshot(rig)
        maximum_motion, maximum_span = 0.0, 0.0
        finite_poses, attached_weapon, compact_hands = True, True, True
        for fraction in (0, .25, .5, .75, 1):
            frame = start + (end - start) * fraction
            scene.frame_set(int(frame), subframe=frame % 1)
            pose = snapshot(rig)
            finite_poses &= all(finite(row) for matrix in pose.values() for row in matrix)
            maximum_motion = max(maximum_motion, max(matrix_error(pose[bone], initial[bone]) for bone in initial))
            attached_weapon &= (pose['blade'].translation - pose['hand.R'].translation).length < .0002
            positions = evaluated_positions(meshes)
            points = [point for values in positions.values() for point in values]
            finite_poses &= all(finite(point) for point in points)
            if finite_poses:
                low_pose, high_pose = bounds(points)
                maximum_span = max(maximum_span, max(high_pose[index] - low_pose[index] for index in range(3)))
            for side in ('L', 'R'):
                radius = hand_radius(positions, hand_indices, rig, side, True)
                compact_hands &= radius < .42
                hand_rows[side]['maximum_animated_wrist_radius'] = max(hand_rows[side]['maximum_animated_wrist_radius'], radius)
        check(finite_poses, name + ': Sampled bones and skinned vertices remain finite')
        check(maximum_motion > .001, name + ': Clip has actual rig motion')
        check(maximum_span < 3.3, name + ': Skinning stays within plausible animated bounds')
        check(attached_weapon, name + ': Weapon attachment follows the wrist')
        check(compact_hands, name + ': Animated hand geometry has no stretched wrist spikes')
        loop_error = None
        if name in LOOPS:
            ending = snapshot(rig)
            loop_error = max(matrix_error(ending[bone], initial[bone]) for bone in initial)
            check(loop_error < .0003, name + ': Loop endpoints match without a pose snap')
        clips.append({'name': name, 'seconds': (end - start) / scene.render.fps,
                      'motion': maximum_motion, 'maximum_span': maximum_span, 'loop_error': loop_error})
    rig.animation_data.action = bpy.data.actions.get('idle')
    scene.frame_set(1)
    finish({'source': str(arguments.source), 'triangles': triangles, 'vertices': vertices,
            'bones': len(rig.data.bones), 'rest_bounds': {'minimum': low, 'maximum': high, 'span': span},
            'material_count': len(materials), 'packed_image_count': len(images), 'hands': hand_rows, 'clips': clips})


def finish(asset):
    result = {'passed': not failures, 'checks': checks, 'failures': failures, 'asset': asset}
    (WORK / 'source_verification.json').write_text(json.dumps(result, indent=2))
    print('EAVE_V3_SOURCE_CHECKS', checks, 'failures=', failures, flush=True)
    if failures:
        raise RuntimeError('; '.join(failures))


if __name__ == '__main__':
    main()
