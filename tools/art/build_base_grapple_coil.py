"""Build the base grapple's stowed braided-rope coil on the left forearm."""

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend"


def make_material(name, color, roughness):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    principled = next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Roughness"].default_value = roughness
    return material


def build_strand(name, points, radius, material, collection):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    curve.resolution_u = 1
    curve.materials.append(material)
    spline = curve.splines.new("NURBS")
    spline.points.add(len(points) - 1)
    for control, point in zip(spline.points, points):
        control.co = (*point, 1.0)
    spline.order_u = 3
    spline.use_endpoint_u = True
    object_ = bpy.data.objects.new(name, curve)
    collection.objects.link(object_)
    return object_


def main():
    bpy.ops.wm.open_mainfile(filepath=str(LIBRARY))
    scene = bpy.context.scene
    rig = bpy.data.objects["Threadborne_Rig"]
    # Author attachment coordinates against the unanimated skeleton. The review
    # reel is active at frame one, so using its evaluated pose here would bake a
    # pose-specific offset into every later action.
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    bone = rig.data.bones["forearm.L"]

    old_root = bpy.data.objects.get("Threadborne_Base_Grapple_ROOT_FOLLOW")
    if old_root:
        for child in list(old_root.children_recursive):
            bpy.data.objects.remove(child, do_unlink=True)
        bpy.data.objects.remove(old_root, do_unlink=True)

    collection = bpy.data.collections.get("THREADBORNE_BASE_GRAPPLE")
    if not collection:
        collection = bpy.data.collections.new("THREADBORNE_BASE_GRAPPLE")
        scene.collection.children.link(collection)

    rope_light = make_material("Base Grapple • rope light", (0.38, 0.17, 0.045), 0.82)
    rope_mid = make_material("Base Grapple • rope mid", (0.23, 0.085, 0.020), 0.88)
    rope_dark = make_material("Base Grapple • rope dark", (0.105, 0.030, 0.009), 0.92)
    materials = (rope_light, rope_mid, rope_dark)

    head = rig.matrix_world @ bone.head_local
    tail = rig.matrix_world @ bone.tail_local
    axis = (tail - head).normalized()
    reference = Vector((0.0, 0.0, 1.0))
    if abs(axis.dot(reference)) > 0.9:
        reference = Vector((0.0, 1.0, 0.0))
    basis_u = axis.cross(reference).normalized()
    basis_v = axis.cross(basis_u).normalized()

    # Eight close turns occupy the wrist-side two thirds of the forearm, matching
    # the stacked rope bands in the original 2D base-grapple equipment art.
    start = head.lerp(tail, 0.30)
    coil_length = bone.length * 0.64
    turns = 8.0
    samples = 385
    coil_radius = bone.length * 0.185
    strand_offset = bone.length * 0.012
    strand_radius = bone.length * 0.0115
    objects = []
    for strand_index, material in enumerate(materials):
        phase = strand_index * math.tau / 3.0
        points = []
        for index in range(samples):
            progress = index / float(samples - 1)
            angle = progress * math.tau * turns
            radial = basis_u * math.cos(angle) + basis_v * math.sin(angle)
            around = -basis_u * math.sin(angle) + basis_v * math.cos(angle)
            centerline = start + axis * (coil_length * progress) + radial * coil_radius
            braid_angle = angle * 3.0 + phase
            point = (
                centerline
                + radial * (math.cos(braid_angle) * strand_offset)
                + axis * (math.sin(braid_angle) * strand_offset)
                + around * (math.sin(angle * 0.5 + phase) * bone.length * 0.0015)
            )
            points.append(point)
        objects.append(
            build_strand(
                f"Base_Grapple_Braided_Strand_{strand_index + 1}",
                points,
                strand_radius,
                material,
                collection,
            )
        )

    root = bpy.data.objects.new("Threadborne_Base_Grapple_ROOT_FOLLOW", None)
    collection.objects.link(root)
    root["equipment_role"] = "base_grapple_stowed_coil"
    root["design_reference"] = "Assets/Threadborne/Equipment/RopeCoilTest.png"
    for object_ in objects:
        object_.parent = root

    world = root.matrix_world.copy()
    root.parent = rig
    root.parent_type = "BONE"
    root.parent_bone = "forearm.L"
    root.matrix_world = world

    rig.data.pose_position = "POSE"
    scene.frame_set(1)
    bpy.context.view_layer.update()
    bpy.ops.wm.save_as_mainfile(filepath=str(LIBRARY))
    print(
        "BASE_GRAPPLE_COIL_READY",
        {"turns": turns, "strands": len(objects), "bone": root.parent_bone},
        flush=True,
    )


main()
