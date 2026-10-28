"""Build an isolated, editable CC0 house / clothed worker comparison in Blender.

Run prepare_cc0_house_villager_comparison.py first, then background Blender:
blender -b --factory-startup --python tools/art/build_cc0_house_villager_comparison.py
Optional arguments after --: --animate (render loop), --still-only (default).
No production art, open Blender session, or game scene is modified.
"""
import bpy
import bmesh
import json
import math
import os
from pathlib import Path
import shutil
import sys
import uuid
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/cc0-house-villager-2026-10-28'
OUT = WORK / 'renders'
OUT.mkdir(parents=True, exist_ok=True)
TEMP = WORK / 'temp'
os.environ['TEMP'] = str(TEMP)
os.environ['TMP'] = str(TEMP)
MANIFEST = json.loads((WORK / 'source_manifest.json').read_text())
ANIMATE = '--animate' in sys.argv
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
scene.render.fps = 24
scene.frame_start, scene.frame_end = 1, 96


def load(stem):
    item = next(x for x in MANIFEST if x['selected_model'] and Path(x['member']).stem == stem)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(WORK / item['local_path']))
    objects = list(set(bpy.data.objects) - before)
    helpers = [o for o in objects if o.type == 'MESH' and not o.data.materials]
    for ob in helpers:
        bpy.data.objects.remove(ob, do_unlink=True)
    return [o for o in objects if o not in helpers]


def meshes(objects):
    return [o for o in objects if o.type == 'MESH']


def bounds(objects, evaluated=False):
    bpy.context.view_layer.update()
    points = []
    for ob in meshes(objects):
        if evaluated:
            obj = ob.evaluated_get(bpy.context.evaluated_depsgraph_get())
            data = obj.to_mesh()
            points += [obj.matrix_world @ v.co for v in data.vertices]
            obj.to_mesh_clear()
        else:
            points += [ob.matrix_world @ v.co for v in ob.data.vertices]
    return [[min(p[a] for p in points), max(p[a] for p in points)] for a in range(3)]


def material(name, color, roughness=.85):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, 1)
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    return mat


M = {
    'wood': material('Threadbound / warm walnut', (.25, .12, .058)),
    'edge': material('Threadbound / warm timber edge', (.43, .26, .13)),
    'plaster': material('Threadbound / parchment plaster', (.64, .56, .40)),
    'roof': material('Threadbound / slate roof', (.085, .19, .27)),
    'stone': material('Threadbound / slate foundation', (.13, .23, .30)),
    'iron': material('Threadbound / iron', (.065, .08, .09)),
    'cloth': material('Threadbound / indigo cloth', (.065, .13, .20)),
    'apron': material('Threadbound / work canvas', (.30, .20, .115)),
    'thread': material('Threadbound / flax seams', (.73, .61, .39)),
    'hair': material('Threadbound / dark brown hair', (.025, .014, .009)),
    'amber': material('Threadbound / amber glass', (.85, .42, .10)),
    'ground': material('Preview only / neutral floor', (.041, .075, .09)),
}


def unify_static_materials(objects):
    for ob in meshes(objects):
        for i, mat in enumerate(ob.data.materials):
            name = mat.name.lower()
            key = ('roof' if 'tile' in name else 'plaster' if 'plaster' in name else
                   'stone' if any(t in name for t in ('brick', 'rock')) else
                   'amber' if 'glass' in name else 'iron' if 'metal' in name else 'wood')
            ob.data.materials[i] = M[key]


def prop(stem, location, scale=(1, 1, 1), angle=0, flat=True):
    objects = load(stem)
    pivot = bpy.data.objects.new(stem + ' / placement', None)
    scene.collection.objects.link(pivot)
    for ob in objects:
        if ob.parent not in objects:
            ob.parent = pivot
    pivot.location, pivot.scale, pivot.rotation_euler.z = location, scale, angle
    if flat:
        unify_static_materials(objects)
    return objects


def box(name, location, size, mat, bevel=.015):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    ob = bpy.context.object
    ob.name = name
    ob.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(mat)
    if bevel:
        mod = ob.modifiers.new('Small readable edge', 'BEVEL')
        mod.width, mod.segments = bevel, 1
        ob.modifiers.new('Face normals', 'WEIGHTED_NORMAL')
    return ob


def bind_rigid(ob, rig, bone):
    matrix = ob.matrix_world.copy()
    ob.parent = rig
    ob.matrix_world = matrix
    group = ob.vertex_groups.new(name=bone)
    group.add(list(range(len(ob.data.vertices))), 1, 'REPLACE')
    mod = ob.modifiers.new('Downloaded rig / authored attachment', 'ARMATURE')
    mod.object = rig


def rebind(ob, rig):
    matrix = ob.matrix_world.copy()
    ob.parent = rig
    ob.matrix_world = matrix
    for mod in ob.modifiers:
        if mod.type == 'ARMATURE':
            mod.object = rig


# Four-metre modular house. The worker uses the porch; no game cutaway is changed.
house = []
for x in (-1, 1):
    house += prop('Wall_Plaster_Door_Round' if x < 0 else 'Wall_Plaster_Window_Wide_Round',
                  (x, .8, .08), (1, 1, .8))
    house += prop('Wall_Plaster_Straight', (x, 3.8, .08), (1, 1, .8), math.pi)
for x in (-2, 2):
    for y in (1.8, 3.0):
        house += prop('Wall_Plaster_Straight', (x, y, .08), (.6, 1, .8), math.pi / 2)
house += prop('DoorFrame_Round_WoodDark', (-1, .68, .08), (1, 1, .8))
house += prop('Door_1_Round', (-1.53, .60, .08), (1, 1, .8))
house += prop('Window_Wide_Round1', (1, .65, .08), (1, 1, .8))
house += prop('Roof_RoundTiles_4x6', (0, 2.25, 2.77), (.86, .49, .40))
house += prop('Roof_Front_Brick4', (0, .42, 2.61), (.88, .7, .49))
for x in (-1, 1):
    for y in (-.4, 1.6, 3.6):
        house += prop('Floor_WoodDark', (x, y, .07))
box('Porch / front rim', (0, -1.44, .045), (4.4, .16, .17), M['wood'])
box('Porch / foundation', (0, 1.5, -.09), (4.12, 6, .20), M['stone'])
for x in (-1.93, 1.93):
    box('Porch / upright', (x, .42, 1.33), (.13, .14, 2.6), M['wood'])
box('Porch / beam', (0, .42, 2.60), (4.25, .18, .18), M['wood'])

# Worker rig and clothing: imported Peasant rig is the master for the assembly.
outfit = load('Male_Peasant')
rig = next(o for o in outfit if o.type == 'ARMATURE')
rig.name = 'CC0_Worker_Rig / Quaternius 65 joints'
if rig.animation_data:
    rig.animation_data_clear()
for ob in meshes(outfit):
    for mat in ob.data.materials:
        if 'Peasant' in mat.name and mat.use_nodes:
            # Preserve source UV texture shading, add a mild indigo workwear tint.
            bsdf = mat.node_tree.nodes.get('Principled BSDF')
            base = bsdf.inputs['Base Color']
            if base.is_linked:
                source = base.links[0].from_socket
                multiply = mat.node_tree.nodes.new('ShaderNodeMixRGB')
                multiply.blend_type = 'MULTIPLY'
                multiply.inputs[0].default_value = 1
                multiply.inputs[2].default_value = (.48, .64, .86, 1)
                mat.node_tree.links.new(source, multiply.inputs[1])
                mat.node_tree.links.new(multiply.outputs[0], base)

extra = load('Superhero_Male_FullBody') + load('Hair_SimpleParted') + load('Hair_Beard')
head_meshes = meshes(extra)
for ob in head_meshes:
    if 'SuperHero' in ob.name:
        head_groups = {group.index for group in ob.vertex_groups if group.name in ('Head', 'neck_01')}
        head_vertices = {v.index for v in ob.data.vertices if sum(g.weight for g in v.groups if g.group in head_groups) > .5}
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        remove = [v for v in bm.verts if v.index not in head_vertices]
        bmesh.ops.delete(bm, geom=remove, context='VERTS')
        bm.to_mesh(ob.data)
        bm.free()
        ob.name = 'CC0 base / head and neck only (body hidden by clothes)'
    rebind(ob, rig)
    if 'Hair_' in ob.name or 'Eyebrows' in ob.name:
        for i in range(len(ob.data.materials)):
            ob.data.materials[i] = M['hair']
for ob in extra:
    if ob.type == 'ARMATURE':
        bpy.data.objects.remove(ob, do_unlink=True)

# Canvas apron with an asymmetric repair patch and visible flax stitches.
apron = box('Authored / canvas work apron', (0, -.175, .835), (.50, .028, .56), M['apron'], .01)
bind_rigid(apron, rig, 'pelvis')
patch = box('Authored / indigo apron patch', (.125, -.197, .73), (.15, .012, .14), M['cloth'], .004)
bind_rigid(patch, rig, 'pelvis')
for z in (.68, .72, .76):
    stitch = box('Authored / patch stitch', (.062, -.208, z), (.026, .007, .009), M['thread'], .001)
    bind_rigid(stitch, rig, 'pelvis')
for x in (-.19, .19):
    strap = box('Authored / apron waist tie', (x, -.17, 1.08), (.15, .035, .035), M['thread'], .005)
    bind_rigid(strap, rig, 'pelvis')
worker = meshes(outfit) + head_meshes + [apron, patch] + [o for o in scene.objects if o.name.startswith('Authored / patch stitch') or o.name.startswith('Authored / apron waist tie')]

# Load source animation for a shared-rig base; keep a copy for provenance/editing.
source_objects = load('UAL1_Standard')
source_rig = next(o for o in source_objects if o.type == 'ARMATURE')
idle = bpy.data.actions.get('Idle_Loop')
assert idle is not None
source_rig.animation_data_create()
source_rig.animation_data.action = idle
if idle.slots:
    source_rig.animation_data.action_slot = idle.slots[0]
idle_range = list(idle.frame_range)
rest_differences = {b.name: max(abs(v) for row in (b.matrix_local - source_rig.data.bones[b.name].matrix_local) for v in row)
                    for b in rig.data.bones}
rest_rotation_differences = {b.name: b.matrix_local.to_quaternion().rotation_difference(source_rig.data.bones[b.name].matrix_local.to_quaternion()).angle
                           for b in rig.data.bones}
rest_rotation_differences = {name: min(angle, abs(math.tau-angle)) for name, angle in rest_rotation_differences.items()}
print('REST_MATRIX_DIFF', max(rest_differences.values()), 'REST_ROTATION_DIFF', max(rest_rotation_differences.values()), flush=True)
axis_maps = {b.name: b.matrix_local.to_quaternion().inverted() @ source_rig.data.bones[b.name].matrix_local.to_quaternion()
             for b in rig.data.bones}
work_action = bpy.data.actions.new('Threadbound_Work_Plane_Loop_96f')
rig.animation_data_create()
rig.animation_data.action = work_action

# Directly transfer the source idle to the shared rig, then author subtle lean/head motion.
for frame in range(1, 98):
    phase = (frame - 1) / 96
    source_frame = idle_range[0] + (idle_range[1] - idle_range[0]) * (phase % 1)
    scene.frame_set(int(source_frame), subframe=source_frame % 1)
    poses = {pb.name: pb.matrix_basis.copy() for pb in source_rig.pose.bones}
    scene.frame_set(frame)
    for pb in rig.pose.bones:
        # The named skeletons have slightly different rest angles/proportions.
        # Transfer rotations through each bone's rest axes, never source translations.
        source_rotation = poses[pb.name].to_quaternion()
        axis_map = axis_maps[pb.name]
        pb.matrix_basis = (axis_map @ source_rotation @ axis_map.inverted()).to_matrix().to_4x4()
        # Keep both soles planted; source animation supplies upper-body breathing only.
        if pb.name in ('root', 'pelvis') or any(t in pb.name for t in ('thigh', 'calf', 'foot', 'ball')):
            pb.matrix_basis = Matrix.Identity(4)
        pb.rotation_mode = 'QUATERNION'
        if pb.name in ('spine_01', 'spine_02', 'spine_03'):
            pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion((1, 0, 0), .045 + .007 * math.sin(phase * math.tau * 2))
        if pb.name == 'Head':
            pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion((1, 0, 0), .20)
        pb.keyframe_insert('location', frame=frame, group=pb.name)
        pb.keyframe_insert('rotation_quaternion', frame=frame, group=pb.name)
        pb.keyframe_insert('scale', frame=frame, group=pb.name)
for ob in source_objects:
    bpy.data.objects.remove(ob, do_unlink=True)
idle.use_fake_user = True

# A fixed porch placement shared by every frame.
rig.location = (.65, -.30, .08)
bpy.context.view_layer.update()
bench = prop('Workbench', (.65, -.98, .08), (.78, .68, 1.03))
board = box('Authored / timber workpiece', (.65, -.725, 1.035), (.48, .76, .055), M['edge'], .008)
prop('Wood_Planks_Stack_Small', (-1.45, -.12, .09), (.65, .65, .65), math.pi / 2, flat=False)
prop('Textiles_Stack_Small', (1.48, .08, .09), (.34, .34, .34), flat=False)
prop('Bucket_Wooden_1', (1.67, -.85, .08), (1.05, 1.05, 1.05))
prop('Crate_Wooden', (-1.45, .03, .09), (.62, .62, .62))
prop('Rope_1', (-1.40, .03, .65), (.85, .85, .85))

plane_root = bpy.data.objects.new('Authored / hand-plane motion control', None)
scene.collection.objects.link(plane_root)
plane_parts = [box('Authored / hand plane body', (0, 0, 0), (.40, .24, .07), M['wood'], .012),
               box('Authored / plane iron', (0, 0, .045), (.19, .055, .04), M['iron'], .004)]
for x in (-.145, .145):
    plane_parts.append(box('Authored / plane grip', (x, -.02, .07), (.065, .11, .065), M['edge'], .012))
for ob in plane_parts:
    ob.parent = plane_root

controls = []
for side, sign in (('l', 1), ('r', -1)):
    target = bpy.data.objects.new('Work wrist target / ' + side, None)
    pole = bpy.data.objects.new('Work elbow pole / ' + side, None)
    scene.collection.objects.link(target)
    scene.collection.objects.link(pole)
    pole.location = (.65 + sign * .65, -.5, 1.28)
    lower = rig.pose.bones['lowerarm_' + side]
    ik = lower.constraints.new('IK')
    ik.name = 'Authored / keep hands at workpiece'
    ik.target, ik.pole_target = target, pole
    ik.chain_count, ik.iterations = 2, 100
    ik.use_stretch = False
    ik.pole_angle = -math.pi / 2 if side == 'l' else math.pi / 2
    hand = rig.pose.bones['hand_' + side]
    target.rotation_mode = 'QUATERNION'
    target.rotation_quaternion = (Matrix.Rotation(-sign * math.pi / 2, 4, 'Z') @ rig.data.bones['hand_' + side].matrix_local).to_quaternion()
    orient = hand.constraints.new('COPY_ROTATION')
    orient.name = 'Authored / palms follow plane handles'
    orient.target = target
    orient.owner_space = orient.target_space = 'WORLD'
    controls.append((target, sign))

for frame in range(1, 98):
    phase = (frame - 1) / 96
    # Two modest planing strokes in four seconds, slowing smoothly at reversal.
    travel = .075 * math.cos(phase * math.tau * 2)
    lift = .002 * (1 - math.cos(phase * math.tau * 2))
    plane_root.location = (.65, -.725 + travel, 1.10 + lift)
    plane_root.keyframe_insert('location', frame=frame)
    for target, sign in controls:
        target.location = (.65 + sign * .145, -.565 + travel, 1.17 + lift)
        target.keyframe_insert('location', frame=frame)

# Lock the authored result into exportable bone keys. Controls remain editable in a source collection.
samples = {}
contact = []
for frame in range(1, 98):
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    samples[frame] = {pb.name: pb.matrix.copy() for pb in rig.pose.bones}
    if frame in (1, 13, 25, 37, 49, 61, 73, 85, 97):
        contact.append(dict(frame=frame, wrist_target_errors=[(rig.matrix_world @ rig.pose.bones['hand_' + ('l' if sign == 1 else 'r')].head - target.location).length for target, sign in controls],
                            tool_board_gap=plane_root.location.z - .035 - (board.location.z + board.dimensions.z / 2)))
for pb in rig.pose.bones:
    for constraint in list(pb.constraints):
        pb.constraints.remove(constraint)
for frame, pose in samples.items():
    scene.frame_set(frame)
    for pb in rig.pose.bones:
        if pb.parent:
            pb.matrix_basis = pb.bone.convert_local_to_pose(
                pose[pb.name], pb.bone.matrix_local,
                parent_matrix=pose[pb.parent.name],
                parent_matrix_local=pb.parent.bone.matrix_local, invert=True)
        else:
            pb.matrix_basis = pb.bone.convert_local_to_pose(
                pose[pb.name], pb.bone.matrix_local, invert=True)
        pb.keyframe_insert('location', frame=frame, group=pb.name)
        pb.keyframe_insert('rotation_quaternion', frame=frame, group=pb.name)
        pb.keyframe_insert('scale', frame=frame, group=pb.name)

# Rendering stage only, not reusable asset lighting.
floor = box('Preview only / neutral stage', (0, 1, -.24), (200, 200, .1), M['ground'], 0)
world = bpy.data.worlds.new('Preview only / neutral blue world')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (.10, .16, .21, 1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = .65
scene.world = world


def area(name, location, energy, size, color):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy, data.shape, data.size, data.color = energy, 'DISK', size, color
    ob = bpy.data.objects.new(name, data)
    scene.collection.objects.link(ob)
    ob.location = location
    ob.rotation_euler = (Vector((0, 0, 1.6)) - ob.location).to_track_quat('-Z', 'Y').to_euler()


area('Preview / warm key', (-3, -5, 8), 1300, 6, (1, .86, .69))
area('Preview / cool fill', (5, -3, 5), 1000, 5, (.65, .81, 1))
area('Preview / soft rim', (1, 6, 7), 1400, 5, (.78, .88, 1))
data = bpy.data.cameras.new('Comparison camera')
camera = bpy.data.objects.new('Comparison camera', data)
scene.collection.objects.link(camera)
scene.camera = camera
camera.location = (2.6, -16, 6.5)
camera.rotation_euler = (Vector((0, 1.1, 1.95)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
data.type, data.ortho_scale = 'ORTHO', 7.5
scene.render.engine = 'CYCLES'
scene.cycles.samples = 12
scene.cycles.use_denoising = True
scene.cycles.device = 'CPU'
scene.render.resolution_x, scene.render.resolution_y = 1000, 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.view_settings.view_transform = 'AgX'
scene.render.film_transparent = False
scene.frame_set(13)
bpy.context.view_layer.update()

report = dict(source='CC0 download library; exact ZIP/member hashes in source_manifest.json',
              master_rig_joint_count=len(rig.data.bones), source_action='UAL1 / Idle_Loop',
              max_rest_matrix_difference=max(rest_differences.values()),
              max_rest_rotation_difference_radians=max(rest_rotation_differences.values()),
              retarget_method='Bone-name mapping with rest-axis rotation compensation; no source translations',
              work_action=work_action.name, frames=96, fps=24, duration_seconds=4,
              body_below_neck_removed=True, production_files_modified=False,
              contact_samples=contact, worker_bounds_frame13=bounds(worker, True),
              house_bounds=bounds(house),
              mesh_triangles=sum(sum(max(0, len(p.vertices)-2) for p in o.data.polygons) for o in meshes(list(scene.objects))))
(WORK / 'build_report.json').write_text(json.dumps(report, indent=2) + '\n')
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.file.pack_all()
temporary_blend = TEMP / ('comparison-' + uuid.uuid4().hex + '.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(temporary_blend), compress=True)
shutil.copyfile(temporary_blend, WORK / 'CC0_House_WorkingVillager_Comparison.blend')
scene.render.filepath = str(OUT / 'cc0_house_worker.png')
bpy.ops.render.render(write_still=True)

# A close view makes contact and clothing readable without pretending this is game scale.
wide_camera = camera.matrix_world.copy()
camera.location = (2.3, -6.5, 2.9)
camera.rotation_euler = (Vector((.65, -.65, 1)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
data.ortho_scale = 2.65
scene.render.resolution_x, scene.render.resolution_y = 800, 800
scene.render.filepath = str(OUT / 'cc0_worker_detail.png')
bpy.ops.render.render(write_still=True)
camera.matrix_world = wide_camera
data.ortho_scale = 7.5
scene.render.resolution_x, scene.render.resolution_y = 1000, 900
if ANIMATE:
    scene.render.resolution_percentage = 72
    scene.cycles.samples = 8
    for frame in range(1, 97, 2):
        scene.frame_set(frame)
        scene.render.filepath = str(TEMP / f'wide_{frame:03}.png')
        bpy.ops.render.render(write_still=True)
    camera.location = (2.3, -6.5, 2.9)
    camera.rotation_euler = (Vector((.65, -.65, 1)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    data.ortho_scale = 2.65
    scene.render.resolution_x = scene.render.resolution_y = 800
    for frame in range(1, 97, 2):
        scene.frame_set(frame)
        scene.render.filepath = str(TEMP / f'detail_{frame:03}.png')
        bpy.ops.render.render(write_still=True)
print('CC0_COMPARISON_BUILD_COMPLETE', flush=True)
