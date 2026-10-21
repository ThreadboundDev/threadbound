"""Read-only native comparison of the actual player and saved Eave v3 source.

Run in background Blender after a completed source build. Both characters use
rest T poses, a shared ground plane and unchanged world scale. This script
never saves either .blend file and imports only the two named player objects.
"""
from pathlib import Path
import hashlib
import json
import math
import os
import struct
import tempfile

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "work/eave-runner-v3"
OUT = WORK / "renders"
OUT.mkdir(parents=True, exist_ok=True)
(WORK / "temp").mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(WORK / "temp")
os.environ["TEMP"] = tempfile.tempdir
os.environ["TMP"] = tempfile.tempdir
SOURCE = ROOT / "ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend"
PLAYER = WORK / "player_reference_only.blend"

source_mtime_ns = SOURCE.stat().st_mtime_ns
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
eave_rig = bpy.data.objects["EaveRunner_Rig"]
eave_meshes = [obj for obj in scene.objects if obj.type == "MESH" and (
    obj.parent == eave_rig or any(mod.type == "ARMATURE" and mod.object == eave_rig for mod in obj.modifiers))]
for obj in scene.objects:
    obj.hide_render = True

with bpy.data.libraries.load(str(PLAYER), link=False) as (available, loaded):
    assert "Threadborne_Character" in available.objects and "Threadborne_Rig" in available.objects
    loaded.objects = ["Threadborne_Character", "Threadborne_Rig"]
hero, hero_rig = loaded.objects
for obj in (hero, hero_rig):
    if not obj.users_collection:
        scene.collection.objects.link(obj)
    obj.hide_render = False
    obj.hide_viewport = False
    obj.hide_set(False)
assert hero.parent == hero_rig, "Actual player rig parent must survive append"


def geometry_digest(mesh):
    value = hashlib.sha256()
    for vertex in mesh.vertices:
        value.update(struct.pack("<3f", *vertex.co))
    for polygon in mesh.polygons:
        value.update(struct.pack("<I", len(polygon.vertices)))
        value.update(struct.pack("<" + "I" * len(polygon.vertices), *polygon.vertices))
    return value.hexdigest()


hero_hash = geometry_digest(hero.data)
hero_materials = tuple(mat.name for mat in hero.data.materials)
hero_scale = tuple(hero.scale)
hero_rig_scale = tuple(hero_rig.scale)
for rig in (hero_rig, eave_rig):
    rig.hide_render = False
    rig.hide_viewport = False
    rig.hide_set(False)
    rig.data.pose_position = "REST"

visible_eave, omitted = [], []
for obj in eave_meshes:
    groups = {group.name for group in obj.vertex_groups}
    is_weapon = obj.get("art_component") == "weapon" or (groups and groups <= {"blade", "held_pin"})
    if is_weapon:
        omitted.append(obj.name)
        continue
    obj.hide_render = False
    obj.hide_viewport = False
    obj.hide_set(False)
    visible_eave.append(obj)
bpy.context.view_layer.update()


def world_bounds(objects):
    points = [obj.matrix_world @ vertex.co for obj in objects for vertex in obj.data.vertices]
    return [[min(point[axis] for point in points), max(point[axis] for point in points)] for axis in range(3)]


before_hero = world_bounds([hero])
before_eave = world_bounds(visible_eave)
# Translation alone places the original, unchanged meshes on the same ground.
hero_rig.location.x -= .95
hero_rig.location.z -= before_hero[2][0]
eave_rig.location.x += .95
eave_rig.location.z -= before_eave[2][0]
bpy.context.view_layer.update()

world = bpy.data.worlds.new("Read-only comparison neutral world")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (.045, .055, .070, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = .52
scene.world = world


def material(name, color, emission=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = .90
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*color, 1)
        bsdf.inputs["Emission Strength"].default_value = .55
    return mat


floor_mat = material("Comparison floor", (.025, .031, .041))
text_mat = material("Comparison labels", (.70, .77, .86), True)
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.004))
floor = bpy.context.object
floor.name = "Comparison ground"
floor.data.materials.append(floor_mat)


def area(name, location, energy, size, color):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size, data.color = energy, size, color
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 0, 1)) - obj.location).to_track_quat("-Z", "Y").to_euler()


area("Comparison shared key", (0, -4, 5), 600, 4, (1, .91, .82))
area("Comparison shared fill", (0, -3, 2), 290, 5, (.70, .82, 1))
area("Comparison shared rim", (0, 3, 4), 680, 5, (.75, .85, 1))


def label(body, x, z, size):
    curve = bpy.data.curves.new("Comparison label", "FONT")
    curve.body, curve.align_x, curve.size = body, "CENTER", size
    curve.space_character = 1.03
    obj = bpy.data.objects.new(body, curve)
    scene.collection.objects.link(obj)
    obj.location, obj.rotation_euler = (x, -.70, z), (math.pi / 2, 0, 0)
    curve.materials.append(text_mat)


label("ACTUAL PLAYER", -.95, -.20, .095)
label("EAVE RUNNER V3", .95, -.20, .095)
label("UNMODIFIED PLAYER REFERENCE  /  SAME WORLD SCALE", 0, 2.30, .064)
label("Neutral rest T poses  |  shared lighting and ground  |  held weapons hidden", 0, 2.17, .049)

camera_data = bpy.data.cameras.new("Comparison orthographic camera")
camera = bpy.data.objects.new("Comparison orthographic camera", camera_data)
scene.collection.objects.link(camera)
camera.location = (0, -8, 1.03)
camera.rotation_euler = (Vector((0, 0, 1.03)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type, camera_data.sensor_fit, camera_data.ortho_scale = "ORTHO", "VERTICAL", 3.2
scene.camera = camera
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 2400, 1800
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(OUT / "Eave_Player_Proportions.png")
scene.view_settings.view_transform = "AgX"
bpy.ops.render.render(write_still=True)
assert geometry_digest(hero.data) == hero_hash, "Player geometry changed during read-only comparison"
assert tuple(mat.name for mat in hero.data.materials) == hero_materials
assert tuple(hero.scale) == hero_scale and tuple(hero_rig.scale) == hero_rig_scale
report = {
    "player_reference": str(PLAYER.relative_to(ROOT)),
    "eave_source": str(SOURCE.relative_to(ROOT)),
    "source_mtime_ns": source_mtime_ns,
    "player_geometry_sha256": hero_hash,
    "player_vertices": len(hero.data.vertices),
    "player_original_bounds": before_hero,
    "eave_original_bounds": before_eave,
    "player_scale_unchanged": True,
    "rest_poses": True,
    "center_spacing_metres": 1.9,
    "vertical_orthographic_span": 3.2,
    "hidden_eave_weapon_components": omitted,
    "output": str(Path(scene.render.filepath).relative_to(ROOT)),
}
(WORK / "player_comparison_render.json").write_text(json.dumps(report, indent=2) + "\n")
print("EAVE_PLAYER_COMPARISON_RENDERED", json.dumps(report), flush=True)
