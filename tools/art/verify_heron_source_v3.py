"""Validate the saved bird-only art source with background Blender.

Run: blender --background --factory-startup --python THIS_FILE -- [--source FILE]
This verifies editable asset data, not artistic quality or an in-game render.
"""
from pathlib import Path
import argparse
import json
import math
import sys

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/loom-heron-v3'
EXPECTED_BONES = {
    'root', 'body', 'neck', 'head', 'tail', 'beak_tip',
    *[prefix + side for side in ('L', 'R') for prefix in
      ('wing_arm.', 'wing_fan.', 'tassel.', 'thigh.', 'shin.', 'foot.')],
}
CLIPS = ('idle', 'flight', 'perch', 'dive_windup', 'dive', 'brake',
         'hurt', 'death', 'needle_aim', 'needle_fire', 'low_recover')
LOOPS = {'idle', 'flight', 'perch'}
checks = 0
failures = []


def check(ok, message):
    global checks
    checks += 1
    if not ok:
        failures.append(message)
        print('HERON_V3_SOURCE_FAIL', message, flush=True)


def finite_vector(point):
    return all(math.isfinite(value) for value in point)


def bone_snapshot(rig):
    return {pose.name: pose.matrix.copy() for pose in rig.pose.bones}


def matrix_error(a, b):
    return max(abs(a[row][column] - b[row][column])
               for row in range(4) for column in range(4))


def bounds(points):
    return ([min(point[axis] for point in points) for axis in range(3)],
            [max(point[axis] for point in points) for axis in range(3)])


def evaluated_points(meshes):
    dependency_graph = bpy.context.evaluated_depsgraph_get()
    return [obj.matrix_world @ vertex.co
            for obj in meshes
            for vertex in obj.evaluated_get(dependency_graph).data.vertices]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, default=(
        ROOT / 'ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v3.blend'))
    arguments = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    WORK.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(arguments.source))
    rigs = [obj for obj in bpy.data.objects if obj.type == 'ARMATURE' and 'LoomHeron' in obj.name]
    check(len(rigs) == 1, 'Exactly one Loom Heron armature exists')
    if not rigs:
        return finish({'source': str(arguments.source)})
    rig = rigs[0]
    scene = rig.users_scene[0]
    bpy.context.window.scene = scene
    meshes = [obj for obj in scene.objects if obj.type == 'MESH' and any(
        modifier.type == 'ARMATURE' and modifier.object == rig for modifier in obj.modifiers)]
    check(bool(meshes), 'Character meshes use the retained armature')
    check(set(rig.data.bones.keys()) == EXPECTED_BONES, 'All 18 expected rig bones are retained')
    check(rig.data.bones['beak_tip'].parent.name == 'head', 'Projectile marker remains parented to head')
    triangles = sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons)
    vertices = sum(len(obj.data.vertices) for obj in meshes)
    check(triangles > 0 and vertices > 0, 'Source has nonempty render geometry')
    materials = set()
    image_set = set()
    for obj in meshes:
        data = obj.data
        check(bool(data.uv_layers), obj.name + ': UV map exists')
        if data.uv_layers:
            uv_data = data.uv_layers.active.data
            check(len(uv_data) == len(data.loops) and all(finite_vector(uv.uv) for uv in uv_data),
                  obj.name + ': UV values are finite for every corner')
            uv_points = [uv.uv for uv in uv_data]
            check(bool(uv_points) and any((point - uv_points[0]).length > 1e-6 for point in uv_points),
                  obj.name + ': UV map is not collapsed to a point')
        check(all(finite_vector(vertex.co) and finite_vector(vertex.normal)
                  and vertex.normal.length > .8 for vertex in data.vertices),
              obj.name + ': Coordinates and vertex normals are finite and nonzero')
        weight_valid = True
        for vertex in data.vertices:
            groups = [(obj.vertex_groups[group.group].name, group.weight)
                      for group in vertex.groups if group.weight > 1e-7]
            if not (1 <= len(groups) <= 4
                    and abs(sum(weight for _, weight in groups) - 1) < .0002
                    and all(name in EXPECTED_BONES and math.isfinite(weight) for name, weight in groups)):
                weight_valid = False
                break
        check(weight_valid, obj.name + ': Every vertex has 1–4 normalized valid bone influences')
        for material in data.materials:
            if material is None:
                continue
            materials.add(material)
            if material.use_nodes:
                image_set.update(node.image for node in material.node_tree.nodes
                                 if node.type == 'TEX_IMAGE' and node.image)
    check(bool(image_set), 'Visible component materials reference texture maps')
    check(all(image.packed_file for image in image_set if image.source == 'FILE'),
          'All referenced file textures are packed into the editable source')
    check(sum(1 for image in image_set if max(image.size) >= 4096) >= 3,
          'High-resolution component maps remain available in the source')

    original_pose_position = rig.data.pose_position
    rig.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    points = evaluated_points(meshes)
    low, high = bounds(points)
    span = [high[index] - low[index] for index in range(3)]
    check(2.8 <= span[0] <= 4.3, 'Rest wing span stays at the established gameplay scale')
    check(1.45 <= span[2] <= 2.35, 'Rest height stays at the established gameplay scale')
    check(-.2 <= low[2] <= .35, 'Feet remain near the established floor origin')
    marker = rig.matrix_world @ rig.data.bones['beak_tip'].head_local
    check(finite_vector(marker) and min((point - marker).length for point in points) < .13,
          'Projectile marker lies near the modeled beak tip')
    rig.data.pose_position = original_pose_position
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
        check(end > start, name + ': Clip has a positive duration')
        scene.frame_set(int(start), subframe=start % 1)
        initial = bone_snapshot(rig)
        maximum_motion = 0.0
        maximum_span = 0.0
        finite_poses = True
        for fraction in (0, .25, .5, .75, 1):
            frame = start + (end - start) * fraction
            scene.frame_set(int(frame), subframe=frame % 1)
            pose = bone_snapshot(rig)
            finite_poses &= all(math.isfinite(value) for matrix in pose.values()
                                for row in matrix for value in row)
            maximum_motion = max(maximum_motion, max(
                matrix_error(pose[bone], initial[bone]) for bone in initial))
            points = evaluated_points(meshes)
            finite_poses &= all(finite_vector(point) for point in points)
            if finite_poses:
                low_pose, high_pose = bounds(points)
                maximum_span = max(maximum_span, max(
                    high_pose[index] - low_pose[index] for index in range(3)))
        check(finite_poses, name + ': Sampled bones and skinned vertices remain finite')
        check(maximum_motion > .001, name + ': Clip has actual rig motion')
        check(maximum_span < 4.9, name + ': Skinning remains within plausible animated bounds')
        loop_error = None
        if name in LOOPS:
            final = bone_snapshot(rig)
            loop_error = max(matrix_error(final[bone], initial[bone]) for bone in initial)
            check(loop_error < .0003, name + ': Loop endpoints match without a pose snap')
        clips.append({'name': name, 'seconds': (end - start) / scene.render.fps,
                      'motion': maximum_motion, 'maximum_span': maximum_span,
                      'loop_error': loop_error})
    rig.animation_data.action = bpy.data.actions.get('idle')
    scene.frame_set(1)
    finish({'source': str(arguments.source), 'triangles': triangles,
            'vertices': vertices, 'bones': len(rig.data.bones),
            'rest_bounds': {'minimum': low, 'maximum': high, 'span': span},
            'material_count': len(materials), 'packed_image_count': len(image_set),
            'clips': clips})


def finish(asset):
    result = {'passed': not failures, 'checks': checks, 'failures': failures, 'asset': asset}
    (WORK / 'source_verification.json').write_text(json.dumps(result, indent=2))
    print('HERON_V3_SOURCE_CHECKS', checks, 'failures=', failures, flush=True)
    if failures:
        raise RuntimeError('; '.join(failures))


if __name__ == '__main__':
    main()
