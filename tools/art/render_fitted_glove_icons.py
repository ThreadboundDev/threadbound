"""Render the actual fitted bracer, wooden hand and stowed grapple together.

Run in Blender with --background --factory-startup --python-exit-code 1
--python tools/art/render_fitted_glove_icons.py. This updates only two local PNGs.
The gear builder also calls render_glove_icon() to preserve the framing on rebuild.
"""

import bmesh
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets"


def render_glove_icon(key, objects, scene, camera, directory):
    """Isolate the shield-arm glove in temporary copies; keep source meshes intact."""
    copies = []
    try:
        for source in objects:
            obj = source.copy()
            obj.data = source.data.copy()
            scene.collection.objects.link(obj)
            world = obj.matrix_world.copy()
            obj.parent = None
            obj.matrix_world = world
            for modifier in list(obj.modifiers):
                obj.modifiers.remove(modifier)
            bm = bmesh.new()
            bm.from_mesh(obj.data)
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if (world @ v.co).x < 0], context="VERTS")
            bm.to_mesh(obj.data)
            bm.free()
            obj.hide_set(False)
            copies.append(obj)
        for obj in scene.objects:
            if obj.type == "MESH":
                obj.hide_render = obj not in copies
        points = [obj.matrix_world @ vertex.co for obj in copies for vertex in obj.data.vertices]
        low = Vector([min(point[axis] for point in points) for axis in range(3)])
        high = Vector([max(point[axis] for point in points) for axis in range(3)])
        target = (low + high) * .5
        camera.location = target + Vector((.20, -1, .60)).normalized() * 3
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        camera.rotation_euler.rotate_axis("Z", math.radians(40))
        bpy.context.view_layer.update()
        projected = [camera.matrix_world.inverted() @ point for point in points]
        span = max(max(point[axis] for point in projected) - min(point[axis] for point in projected) for axis in (0, 1))
        camera.data.ortho_scale = span * 1.16
        scene.render.filepath = str(Path(directory) / f"{key}_gloves_icon.png")
        bpy.ops.render.render(write_still=True)
    finally:
        for obj in copies:
            mesh = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.meshes.remove(mesh)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = 320
    scene.world = bpy.data.worlds.new("Glove icon studio")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.8, .8, .8, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = .62
    scene.view_settings.view_transform = "AgX"
    camera = bpy.data.objects.new("Glove icon camera", bpy.data.cameras.new("Glove icon camera"))
    scene.collection.objects.link(camera)
    camera.data.type = "ORTHO"
    scene.camera = camera
    lamp = bpy.data.objects.new("Glove key", bpy.data.lights.new("Glove key", "AREA"))
    scene.collection.objects.link(lamp)
    lamp.data.energy = 150
    lamp.data.size = 1.7
    lamp.location = (-1.1, -1.4, 2.7)
    lamp.rotation_euler = (Vector((.7, 0, 1.5)) - lamp.location).to_track_quat("-Z", "Y").to_euler()
    for key in ("base", "blue"):
        before = set(scene.objects)
        bpy.ops.import_scene.gltf(filepath=str(OUT / f"{key}_gloves.glb"))
        imported = set(scene.objects) - before
        rig = next(obj for obj in imported if obj.type == "ARMATURE")
        rig.animation_data_clear()
        rig.data.pose_position = "REST"
        bpy.context.view_layer.update()
        # Blender's glTF importer also creates a hidden mesh for bone gizmos.
        meshes = [obj for obj in imported if obj.type == "MESH" and obj.find_armature() == rig]
        render_glove_icon(key, meshes, scene, camera, OUT)
        for obj in imported:
            bpy.data.objects.remove(obj, do_unlink=True)
    print("FITTED_GLOVE_ICONS rendered bracer, wooden hand, reel/coil and hook", flush=True)


if __name__ == "__main__":
    main()
