"""Export the equipped Blender character as an isolated, game-ready live 3D test."""
import json
import csv
import argparse
import sys
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, default=ROOT / 'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend')
parser.add_argument('--output', type=Path, default=ROOT / 'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_live_3d.glb')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
SOURCE = args.source
INVENTORY = SOURCE.parent / "animation_inventory.csv"
DEST = args.output.parent
DEST.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
if bpy.context.object and bpy.context.object.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")

# The full-resolution render collection is intentionally disabled in Blender's
# interactive viewport. Enable it only in this disposable export process.
for collection in bpy.data.collections:
    collection.hide_viewport = False
    collection.hide_render = False
def enable_layer_collection(layer_collection):
    layer_collection.exclude = False
    layer_collection.hide_viewport = False
    for child in layer_collection.children:
        enable_layer_collection(child)
enable_layer_collection(bpy.context.view_layer.layer_collection)

# Keep only the production character, its target rig, and the fitted equipment hierarchy.
keep = {bpy.data.objects.get("Threadborne_Rig"), bpy.data.objects.get("Threadborne_Character")}
for root_name in (
    "Threadborne_Sword_ROOT_FOLLOW",
    "Threadborne_Shield_ROOT_FOLLOW",
    "Threadborne_Base_Grapple_ROOT_FOLLOW",
):
    root = bpy.data.objects.get(root_name)
    if root:
        keep.add(root)
        keep.update(root.children_recursive)
keep.discard(None)

for obj in list(scene.objects):
    if obj not in keep:
        bpy.data.objects.remove(obj, do_unlink=True)

# glTF does not carry Blender constraints. Replace the two follower constraints
# with real bone parenting while preserving their authored frame-one placement.
scene.frame_set(1)
rig = bpy.data.objects.get("Threadborne_Rig")
for follower_name, bone_name in (
    ("Threadborne_Sword_ROOT_FOLLOW", "hand.R"),
    ("Threadborne_Shield_ROOT_FOLLOW", "forearm.L"),
):
    follower = bpy.data.objects.get(follower_name)
    if follower and rig:
        world_transform = follower.matrix_world.copy()
        follower.constraints.clear()
        follower.parent = rig
        follower.parent_type = "BONE"
        follower.parent_bone = bone_name
        follower.matrix_world = world_transform

character = bpy.data.objects.get("Threadborne_Character")

# Blender's procedural shield-back materials are not representable in glTF.
# Give their Principled shaders explicit fallback colors so Godot does not
# receive the default white Base Color when those node graphs are exported.
shield_material_fallbacks = {
    "Shield • dark worn backing": (0.028, 0.024, 0.020, 1.0),
    "Shield • charcoal sewn wraps": (0.040, 0.044, 0.045, 1.0),
    "Shield • brown leather arm straps": (0.130, 0.072, 0.030, 1.0),
    "Shield • aged brass": (0.430, 0.245, 0.089, 1.0),
    "Shield • golden stitching": (0.500, 0.280, 0.080, 1.0),
}
for material_name, color in shield_material_fallbacks.items():
    material = bpy.data.materials.get(material_name)
    if not material:
        continue
    material.diffuse_color = color
    if material.use_nodes:
        for node in material.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            base_color = node.inputs.get("Base Color")
            if base_color:
                for link in list(base_color.links):
                    material.node_tree.links.remove(link)
                base_color.default_value = color

# Curves are not native glTF geometry. Convert only the in-memory export copies.
bpy.context.view_layer.objects.active = rig
bpy.ops.object.select_all(action="DESELECT")
for obj in list(scene.objects):
    if obj.type == "CURVE":
        obj.hide_set(False)
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.convert(target="MESH")
        obj.select_set(False)

# Consolidate the export-only shield construction. It remains a separate item under
# its attachment root, but no longer asks Godot to submit hundreds of tiny objects.
shield_root = bpy.data.objects.get("Threadborne_Shield_ROOT")
shield_thickness_factor = 0.68
if shield_root:
    shield_meshes = [obj for obj in shield_root.children_recursive if obj.type == "MESH"]
    if shield_meshes:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in shield_meshes:
            obj.hide_set(False)
            obj.select_set(True)
        bpy.context.view_layer.objects.active = shield_meshes[0]
        bpy.ops.object.join()
        shield_meshes[0].name = "Threadborne_Shield_Combined_Test"
        coordinates = [vertex.co for vertex in shield_meshes[0].data.vertices]
        ranges = [max(co[i] for co in coordinates) - min(co[i] for co in coordinates) for i in range(3)]
        thickness_axis = min(range(3), key=lambda axis: ranges[axis])
        center = (max(co[thickness_axis] for co in coordinates) + min(co[thickness_axis] for co in coordinates)) * 0.5
        for vertex in shield_meshes[0].data.vertices:
            vertex.co[thickness_axis] = center + (vertex.co[thickness_axis] - center) * shield_thickness_factor

# At the test's ~180 px display size, this retains the authored silhouette and folds
# while avoiding a one-million-vertex live character. The source .blend is unchanged.
if character:
    decimate = character.modifiers.new("Live3D_Test_Decimate", "DECIMATE")
    decimate.ratio = 0.35
    decimate.use_collapse_triangulate = True
    character.modifiers.move(character.modifiers.find(decimate.name), 0)
    bpy.ops.object.select_all(action="DESELECT")
    character.select_set(True)
    bpy.context.view_layer.objects.active = character
    bpy.ops.object.modifier_apply(modifier=decimate.name)

# Export only the reviewed canonical library. Earlier three-clip actions and
# source actions are rebuild inputs, not production clips.
with INVENTORY.open(newline="", encoding="utf-8") as handle:
    canonical_actions = {row["action"] for row in csv.DictReader(handle)}
runtime_actions = {
    "idle_1", "idle_2", "idle_3", "idle_4",
    "run_1", "run_2", "walk_1", "walk_2",
    "jump_1", "jump_2",
    "crouch_1", "crouch_idle_1", "crouching_1", "crouching_2", "crouching_3",
    "block_1", "block_idle_1", "impact_1", "impact_2", "impact_3",
    "crouch_block_1", "crouch_block_2", "crouch_block_idle_1",
    "death_1", "death_2",
    "attack_1", "attack_2", "attack_3", "slash_1", "slash_2", "slash_5", "casting_1", "casting_2", "power_up_1",
    "turn_1", "turn_2", "stand_to_sit_1", "sit_to_stand_1", "jumping_into_water_1",
    "grapple_swinging_1", "water_idle_1", "swimming_1",
    "grab_ledge_from_water_1", "get_up_from_hang_1", "hanging_idle_1",
    "jump_into_wall_hang_1", "roll_1",
}
unknown_runtime_actions = runtime_actions - canonical_actions
if bpy.data.actions.get('air_light_1'):
    runtime_actions.add('air_light_1')
if unknown_runtime_actions:
    raise RuntimeError(f"Runtime action names missing from source library: {unknown_runtime_actions}")
for action in list(bpy.data.actions):
    if action.name not in runtime_actions:
        bpy.data.actions.remove(action)

for obj in scene.objects:
    obj.hide_set(False)
    obj.hide_viewport = False
    obj.hide_render = False
    obj.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects.get("Threadborne_Rig")
output = args.output
bpy.ops.export_scene.gltf(
    filepath=str(output),
    export_format="GLB",
    use_selection=True,
    # Keep this false: applying transforms during glTF export omits skinned meshes.
    export_apply=False,
    export_materials="EXPORT",
    export_normals=True,
    export_tangents=True,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
    export_frame_step=1,
    export_skins=True,
    export_all_influences=False,
    export_lights=False,
    export_cameras=False,
    export_image_format="AUTO",
)

report = {
    "source": str(SOURCE),
    "output": str(output),
    "source_character_vertices": 982421,
    "character_export_decimate_ratio": 0.35,
    "shield_thickness_factor": shield_thickness_factor,
    "animations": {a.name: list(a.frame_range) for a in bpy.data.actions},
    "canonical_animation_count": len(canonical_actions),
    "runtime_animation_count": len(runtime_actions),
    "objects": len(scene.objects),
}
output.with_suffix('.export.json').write_text(json.dumps(report, indent=2))
print("EQUIPPED_LIVE_3D_EXPORT_READY", json.dumps(report), flush=True)
