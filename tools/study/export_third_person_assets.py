"""Blender: inspect/export isolated workshop and current Threadborne working copies."""
import bpy
from pathlib import Path
import json
import sys
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
OUT = WORK / 'project/assets'


def bounds(ob):
    pts = [Vector(v) for v in ob.bound_box]
    return [[min(p[i] for p in pts) for i in range(3)],
            [max(p[i] for p in pts) for i in range(3)]]


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(WORK / 'temp/threadborne_original.glb'))
report = []
for ob in bpy.context.scene.objects:
    if ob.type == 'MESH':
        report.append(dict(name=ob.name, parent=ob.parent.name if ob.parent else None,
                           bone=ob.parent_bone, parent_type=ob.parent_type,
                           local_matrix=[list(r) for r in ob.matrix_local], bounds=bounds(ob)))
    elif ob.type == 'ARMATURE':
        report.append(dict(name=ob.name, bones=[b.name for b in ob.data.bones]))
(WORK / 'temp/player_inspection.json').write_text(json.dumps(report, indent=2))
print('PLAYER_INSPECTION', json.dumps(report), flush=True)

# Add optional weapon working copies beneath the same animated attachment roots.
# Keep original weapons too, so the study can compare both with V.
for old_name, stem, name in [('Threadborne_Sword', 'sword_B', 'Study_Sword'),
                              ('Threadborne_Shield_Combined_Test', 'shield_B', 'Study_Shield')]:
    old = bpy.data.objects[old_name]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(WORK / 'temp/weapons' / (stem + '.gltf')))
    added = set(bpy.data.objects) - before
    source = next(o for o in added if o.type == 'MESH')
    mesh = source.data.copy()
    lo, hi = bounds(source)
    old_lo, old_hi = bounds(old)
    factor = (old_hi[2] - old_lo[2]) / (hi[2] - lo[2])
    center = Vector([(a + b) / 2 for a, b in zip(old_lo, old_hi)])
    for vertex in mesh.vertices:
        x, y, z = vertex.co
        if stem.startswith('sword'):
            vertex.co = Vector((y * factor, x * factor, -(z - (hi[2]+lo[2])/2) * factor)) + center
        else:
            vertex.co = Vector((y * factor, x * factor, (z - (hi[2]+lo[2])/2) * factor)) + center
    replacement = old.copy()
    replacement.data = mesh
    replacement.name = name
    bpy.context.scene.collection.objects.link(replacement)
    for ob in added:
        bpy.data.objects.remove(ob, do_unlink=True)

rig = bpy.data.objects['Threadborne_Rig']
keep = ['idle_4', 'walk_1', 'run_1', 'jump_1', 'block_idle_1', 'slash_2',
        'attack_2', 'power_up_1', 'roll_1', 'grapple_swinging_1', 'casting_1', 'air_light_1', 'impact_1', 'death_1']
print('NLA', [t.name for t in rig.animation_data.nla_tracks], flush=True)
for track in list(rig.animation_data.nla_tracks):
    if not any(track.name == clip or track.name.endswith(clip) for clip in keep):
        rig.animation_data.nla_tracks.remove(track)
if rig.animation_data.action:
    rig.animation_data.action = None
bpy.ops.object.select_all(action='DESELECT')
for ob in bpy.context.scene.objects:
    if ob.name != 'Icosphere':
        ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT / 'threadborne_study.glb'), export_format='GLB',
                          use_selection=True, export_animation_mode='NLA_TRACKS',
                          export_animations=True, export_apply=False)
if '--player-only' in sys.argv:
    sys.exit(0)

# Export the already-authored workshop + rigged work loop, excluding its render stage.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'work/cc0-house-villager-2026-10-28/CC0_House_WorkingVillager_Comparison.blend'))
# Working-copy maps only: a single background villager does not need 4K/8K maps.
for index, image in enumerate(bpy.data.images):
    if image.packed_file:
        # Packed images load lazily in background Blender.
        _first_pixel = image.pixels[0]
    if image.has_data and max(image.size) > 1024:
        factor = 1024 / max(image.size)
        image.scale(round(image.size[0] * factor), round(image.size[1] * factor))
        image.filepath_raw = str(WORK / 'temp' / ('workshop_map_' + str(index) + '.png'))
        image.file_format = 'PNG'
        image.save()
        if image.packed_file:
            image.unpack(method='REMOVE')
        image.pack()
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = 97
bpy.context.scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT')
for ob in bpy.context.scene.objects:
    if ob.type in {'MESH', 'ARMATURE', 'EMPTY'} and not ob.name.startswith(('Preview', 'Work wrist', 'Work elbow')):
        ob.hide_set(False)
        ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT / 'workshop.glb'), export_format='GLB',
                          use_selection=True, export_animation_mode='ACTIVE_ACTIONS',
                          export_animations=True, export_frame_range=True,
                          export_force_sampling=True, export_apply=True)
print('EXPORTED', str(OUT), flush=True)

for stem in ['tree_pineTallA_detailed', 'tree_detailed', 'plant_bushLarge', 'rock_largeD', 'rock_smallFlatA']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=str(WORK / 'temp/nature' / (stem + '.obj')),
                         forward_axis='NEGATIVE_Z', up_axis='Y')
    for mat in bpy.data.materials:
        # Restrained leaf/stone/trunk colours; preserve the source geometry.
        if mat.use_nodes:
            bsdf = mat.node_tree.nodes.get('Principled BSDF')
            if bsdf:
                c = bsdf.inputs['Base Color'].default_value
                if 'leaf' in mat.name.lower() or 'grass' in mat.name.lower():
                    bsdf.inputs['Base Color'].default_value = (.12, .23, .18, 1)
                bsdf.inputs['Roughness'].default_value = .95
    bpy.ops.export_scene.gltf(filepath=str(OUT / 'foliage' / (stem + '.glb')),
                              export_format='GLB', export_animations=False)
