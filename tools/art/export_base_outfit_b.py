"""Bake and export the Outfit B fitting file for Godot.

Run Blender in background with the fitted Outfit B source open, then pass
-- --output <directory>. This exports three modular GLBs and a cloth/stitch
mask. The Blender source and installed game assets stay on disk as opened.
"""
from argparse import ArgumentParser
from pathlib import Path
import sys

import bpy
import numpy as np


SCENE = bpy.context.scene
LAYER = SCENE.view_layers["B - Hollowed older outfit"]
bpy.context.window.view_layer = LAYER
RIG = bpy.data.objects["Threadborne_Rig"]
RIG.animation_data_clear()
RIG.data.pose_position = "REST"


def select(objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.hide_set(False)
        obj.select_set(True)
    LAYER.objects.active = objects[0]


def apply_budget(obj, ratio):
    select([obj])
    modifier = obj.modifiers.new("Gameplay triangle budget", "DECIMATE")
    modifier.ratio = ratio
    # Collapse in rest space before skinning.
    bpy.ops.object.modifier_move_up(modifier=modifier.name)
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def smoothstep(lo, hi, values):
    t = np.clip((values - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)


def bake_outfit(obj, output):
    select([obj])
    SCENE.render.engine = "CYCLES"
    SCENE.cycles.device = "CPU"
    SCENE.cycles.samples = 2
    material = obj.data.materials[0]
    tree = material.node_tree
    shader = next(node for node in tree.nodes if node.type == "BSDF_PRINCIPLED")
    surface = next(node for node in tree.nodes if node.type == "OUTPUT_MATERIAL")
    base_link = shader.inputs["Base Color"].links[0].from_socket
    source_uv = tree.nodes.new("ShaderNodeUVMap")
    source_uv.uv_map = obj.data.uv_layers[0].name
    for tex in [node for node in tree.nodes if node.type == "TEX_IMAGE"]:
        if not tex.inputs["Vector"].is_linked:
            tree.links.new(source_uv.outputs["UV"], tex.inputs["Vector"])
    baked = bpy.data.images.new("Outfit B cloth base", 2048, 2048, alpha=True)
    target = tree.nodes.new("ShaderNodeTexImage")
    target.image = baked
    tree.nodes.active = target
    emit = tree.nodes.new("ShaderNodeEmission")
    tree.links.new(base_link, emit.inputs["Color"])
    tree.links.new(emit.outputs[0], surface.inputs["Surface"])
    bpy.ops.object.bake(type="EMIT", margin=10, margin_type="EXTEND")

    # Derive the two painted regions from the baked fabric and gold colors.
    # Green on the mask selects only the narrow warm-gold color range.
    rgba = np.empty(2048 * 2048 * 4, dtype=np.float32)
    baked.pixels.foreach_get(rgba)
    pixels = rgba.reshape(-1, 4)
    red, green, blue = pixels[:, 0], pixels[:, 1], pixels[:, 2]
    luminance = pixels[:, :3] @ np.array([.213, .715, .072], dtype=np.float32)
    cloth = smoothstep(-.057, .014, blue-red)
    gold = smoothstep(.095, .225, red-blue) * smoothstep(.325, .54, luminance)
    gold *= smoothstep(.022, .095, green-blue)
    mask = np.zeros_like(pixels)
    mask[:, 0], mask[:, 1], mask[:, 3] = cloth*pixels[:, 3], gold*pixels[:, 3], 1.
    print("DYE REGIONS", float((mask[:, 0]>.7).mean()), float((mask[:, 1]>.5).mean()), flush=True)
    dye = bpy.data.images.new("Outfit B dye mask", 2048, 2048, alpha=False, is_data=True)
    dye.pixels.foreach_set(mask.ravel())
    dye.filepath_raw = str(output / "base_outfit_b_dye.png")
    dye.file_format = "PNG"
    dye.save()

    baked.filepath_raw = str(output / "base_outfit_b_albedo.jpg")
    baked.file_format = "JPEG"
    baked.save()
    baked.pack()
    clean = bpy.data.materials.new("Outfit B Cloth")
    clean.use_nodes = True
    tree = clean.node_tree
    shader = tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = .78
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.image = baked
    tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    obj.data.materials[0] = clean
    # The bake carries the sleeve weave blend onto the primary atlas.
    for uv in list(obj.data.uv_layers)[1:]:
        obj.data.uv_layers.remove(uv)


def flatten_hardware_finishes(objects):
    # glTF carries constant PBR and UV textures. Preserve the leather, brass
    # and flax tones where the fitting file uses procedural object-space grain.
    for material in {mat for obj in objects for mat in obj.data.materials}:
        tree = material.node_tree
        if not tree or not any(node.type == "TEX_NOISE" for node in tree.nodes):
            continue
        shader = next(node for node in tree.nodes if node.type == "BSDF_PRINCIPLED")
        for name in ("Base Color", "Normal"):
            for link in list(shader.inputs[name].links):
                tree.links.remove(link)
        shader.inputs["Base Color"].default_value = material.diffuse_color


def export_item(rig_template, meshes, path):
    for mesh in meshes:
        pose = mesh.matrix_world.copy()
        mesh.parent = RIG
        mesh.matrix_world = pose

    bones = set()
    for mesh in meshes:
        names = {group.index: group.name for group in mesh.vertex_groups}
        for vertex in mesh.data.vertices:
            for weight in vertex.groups:
                bone = RIG.data.bones.get(names[weight.group])
                if weight.weight <= 0.0001 or bone is None:
                    continue
                while bone and bone.name not in bones:
                    bones.add(bone.name)
                    bone = bone.parent

    # The loader checks all binds in the exported skin. Keep the real
    # deformation bones and ancestor chains only, even on a full master rig.
    RIG.data = rig_template.copy()
    select([RIG])
    bpy.ops.object.mode_set(mode="EDIT")
    for bone in list(RIG.data.edit_bones):
        if bone.name not in bones:
            RIG.data.edit_bones.remove(bone)
    bpy.ops.object.mode_set(mode="OBJECT")
    select([RIG, *meshes])
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB",
                             use_selection=True, export_animations=False,
                             export_rest_position_armature=True, export_skins=True,
                             export_cameras=False, export_lights=False)
    print("GEAR", path.name, len(bones), "bones",
          sum(len(p.vertices)-2 for obj in meshes for p in obj.data.polygons),
          "triangles", flush=True)
    RIG.data = rig_template


def main():
    parser = ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    opts = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    output = opts.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    outfit = bpy.data.objects["B - Older outfit, hollowed"]
    outfit.name = "Base_Outfit_B"
    boots = [bpy.data.objects["Base_Boot."+side] for side in "LR"]
    bracers = [bpy.data.objects["Base_Bracer."+side] for side in "LR"]
    coil = bpy.data.objects["Base_Grapple_Coil"]
    needle = bpy.data.objects["Grapple_Needle_Base"]
    flatten_hardware_finishes([coil, needle])
    for obj, ratio in [(b, .19) for b in boots]+[(b, .27) for b in bracers]+[(coil, .26), (needle, .62)]:
        apply_budget(obj, ratio)
    bake_outfit(outfit, output)
    template = RIG.data
    for name, objects in (("base_outfit_b", [outfit]), ("base_boots_b", boots),
                          ("base_bracers_b", [*bracers, coil, needle])):
        export_item(template, objects, output / (name+".glb"))


if __name__ == "__main__":
    main()
