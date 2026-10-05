"""Surgical v3 revision: connected wrist sockets and trailing swim feet.

Preserves v3 and all existing body/combat animation tracks. Outputs v4.
"""
from pathlib import Path
import math
import sys
import bpy
import bmesh
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v4.blend'
EXPORT = ROOT / 'Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v4.glb'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Preserve manual v4 edits.'
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v3.blend'))
rig = bpy.data.objects['Bellstriker_Rig']
scene = bpy.context.scene
blue = bpy.data.materials['Bellstriker_Joint_Navy']

# The source creature faces diagonally in mesh space. The old +/-Y split
# mistakenly put the near glove on the body and walking legs on claw.R.
# Extract both actual glove shells; preserve the accepted head/rear-body skin.
rig.data.pose_position = 'REST'
bpy.ops.object.select_all(action='DESELECT')
shell = bpy.data.objects['Bellstriker_Shell']
for source_index, obj in enumerate([shell, bpy.data.objects['Bellstriker_Claw_L'], bpy.data.objects['Bellstriker_Claw_R']]):
    attr = obj.data.attributes.new('v3_part', 'INT', 'FACE')
    for item in attr.data: item.value = source_index
    obj.select_set(True)
bpy.context.view_layer.objects.active = shell
bpy.ops.object.join()
original_data = shell.data.copy()
original_faces = len(original_data.polygons)

def region(face):
    x, y, z = face.calc_center_median()
    if x > .91 and -.27 < y < .58 and z < 1.33:
        return 'R'
    if -.08 < x < .79 and y > .73 and z < 1.33:
        return 'L'
    return 'body'

stations = [(-1.75, 'tail_fan'), (-1.46, 'tail.04'), (-1.18, 'tail.03'),
            (-.86, 'tail.02'), (-.52, 'tail.01'), (-.18, 'abdomen'),
            (.16, 'body'), (.46, 'thorax'), (.68, 'neck'), (.96, 'head')]
def between(value, samples):
    if value <= samples[0][0]: return [(samples[0][1], 1.0)]
    if value >= samples[-1][0]: return [(samples[-1][1], 1.0)]
    for (a, an), (b, bn) in zip(samples, samples[1:]):
        if a <= value <= b:
            t = (value-a)/(b-a); t = t*t*(3-2*t)
            return [(an, 1-t), (bn, t)]

parts = []
for name in ['body', 'L', 'R']:
    part = shell if name == 'body' else shell.copy()
    if part != shell:
        scene.collection.objects.link(part)
        part.name = 'Bellstriker_Claw_'+name
    part.data = original_data.copy()
    edit = bmesh.new(); edit.from_mesh(part.data)
    face_layers = edit.faces.layers.int
    bmesh.ops.delete(edit, geom=[f for f in edit.faces if region(f) != name], context='FACES')
    bmesh.ops.delete(edit, geom=[v for v in edit.verts if not v.link_faces], context='VERTS')
    edit.to_mesh(part.data); edit.free()
    groups = {b.name: part.vertex_groups.get(b.name) or part.vertex_groups.new(name=b.name) for b in rig.data.bones}
    for vertex in part.data.vertices:
        x, y, z = vertex.co
        side = 'L' if y >= 0 else 'R'
        old_groups = [(part.vertex_groups[g.group].name, g.weight) for g in vertex.groups]
        if name == 'body' and not any(n == 'claw.R' and w > .001 for n, w in old_groups):
            continue
        for group in part.vertex_groups: group.remove([vertex.index])
        if name != 'body': weights = [('claw.'+name, 1.0)]
        elif x > .65 and z > 1.30: weights = [('head', 1.0)]
        elif -.95 < x < .67 and z < .46 and abs(y) > .39:
            i = min(range(4), key=lambda index: abs(x-[.35, 0, -.35, -.70][index]))
            weights = between(abs(y), [(.4, f'leg.{i}.{side}'), (.74, f'shin.{i}.{side}'), (1.05, f'toe.{i}.{side}')])
        else: weights = between(x, stations)
        for bone, weight in weights:
            if weight > 0: groups[bone].add([vertex.index], weight, 'REPLACE')
    if name != 'body':
        # Mount the real shell at the already-animated wrist, with its long
        # axis forward. No changes to IK, guard or punch animation curves.
        socket = Vector((.20, .83, .75) if name == 'L' else (.98, .10, .75))
        angle = math.radians(-55 if name == 'L' else -30)
        rotation = Matrix.Rotation(angle, 3, 'Z')
        pivot = rig.data.bones['claw.'+name].head_local
        for vertex in part.data.vertices:
            vertex.co = pivot + rotation @ (vertex.co-socket)
    parts.append(part)
assert sum(len(p.data.polygons) for p in parts) == original_faces
print('V4_ACTUAL_GLOVES', [(p.name, len(p.data.polygons)) for p in parts])
rig.data.pose_position = 'POSE'

def joint_mesh(name, center, radius, length=None, direction=None, bone=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1, location=center)
    obj = bpy.context.object
    obj.name = name
    if direction is not None:
        obj.rotation_mode = 'QUATERNION'
        obj.rotation_quaternion = direction.to_track_quat('Z', 'Y')
    obj.scale = (radius, radius, length if length is not None else radius)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.data.materials.append(blue)
    for face in obj.data.polygons:
        face.use_smooth = True
    obj.vertex_groups.new(name=bone).add(list(range(len(obj.data.vertices))), 1.0, 'REPLACE')
    obj.parent = rig
    obj.modifiers.new('Rigid wrist socket', 'ARMATURE').object = rig
    return obj

# The far glove's bounding-box centre is NOT inside its surface. The
# previous forearm ended there, leaving a visible gap. Bridge to the closest
# actual glove surface with overlap at both ends, rigidly following the fist.
for side in ['L', 'R']:
    bone = 'claw.' + side
    pivot = rig.data.bones[bone].head_local.copy()
    claw = bpy.data.objects['Bellstriker_Claw_' + side]
    surface = min(claw.data.vertices, key=lambda v: (v.co-pivot).length).co.copy()
    direction = (surface-pivot).normalized()
    start, end = pivot-direction*.10, surface+direction*.16
    joint_mesh('Bellstriker_Wrist_Bridge_'+side, (start+end)/2, .14,
               (end-start).length/2, direction, bone)
    joint_mesh('Bellstriker_Wrist_Socket_'+side, pivot, .145, bone=bone)
    print('V4_WRIST_SURFACE_GAP', side, (surface-pivot).length)

for name, energy in [('swim', 1.0), ('swim_idle', .38)]:
    action = bpy.data.actions[name]
    rig.animation_data.action = action
    first, last = map(int, action.frame_range)
    names = [f'{part}.{i}.{side}' for side in ['L', 'R'] for i in range(4)
             for part in ['leg', 'shin', 'toe']]
    # Snapshot before changing any keys, so inserted keys cannot contaminate
    # subsequent samples of the original curves.
    original = {}
    for frame in range(first, last+1):
        scene.frame_set(frame)
        original[frame] = {n: rig.pose.bones[n].rotation_quaternion.copy() for n in names}
    for frame, values in original.items():
        phase = math.tau*(frame-first)/(last-first)
        scene.frame_set(frame)
        for side, sign in [('L', 1), ('R', -1)]:
            for i in range(4):
                lag = i*.50 + .25
                for part, amplitude, delay in [('leg', 2.5, 0), ('shin', 4.0, .30), ('toe', 6.0, .65)]:
                    n = f'{part}.{i}.{side}'
                    rest = rig.data.bones[n].matrix_local.to_quaternion()
                    pitch = math.radians(amplitude*energy*math.sin(phase-lag-delay))
                    roll = math.radians(sign*1.5*energy*math.sin(phase-lag-delay-.2))
                    delta = Quaternion((0, 1, 0), pitch) @ Quaternion((1, 0, 0), roll)
                    pb = rig.pose.bones[n]
                    pb.rotation_quaternion = values[n] @ (rest.inverted() @ delta @ rest)
                    pb.keyframe_insert('rotation_quaternion', frame=frame, group=n)
    print('V4_TRAILING_FEET', name, first, last)

rig.animation_data.action = bpy.data.actions['box_idle']
scene.frame_start, scene.frame_end = 1, 61
scene.frame_set(1)
scene['attachment_notes'] = 'v4: rigid wrist socket/bridge reaches actual glove surface on BOTH fists. Swimming feet flex with delayed tail rhythm. Original v3 body and combat curves unchanged.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in scene.objects:
    if obj.type == 'MESH' or obj == rig:
        obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT), export_format='GLB', use_selection=True,
                          export_animation_mode='ACTIONS', export_force_sampling=True,
                          export_lights=False, export_cameras=False)
print('BELL_V4_READY', DEST, EXPORT)
