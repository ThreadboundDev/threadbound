"""Paint the OG Base FBX and fit it to the current modular player rest pose.

Run from the repository root in background Blender with --python and then
-- followed by the path to Old style character.fbx.
"""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector


ROOT = Path.cwd()
OUTPUT = ROOT / "LocalOnly/OG_Export_Trial"
# Digit landmarks in the 900 px orthographic calibration view of the FBX.
# Each entry gives the tip, palm-side center, and distances to the sculpted joints.
DIGITS = {
    "index": ((55, 220), (105, 230), (14, 29)),
    "middle": ((45, 245), (104, 246), (16, 31)),
    "ring": ((50, 272), (105, 259), (14, 29)),
    "pinky": ((64, 294), (109, 274), (14, 26)),
    "thumb": ((107, 188), (135, 225), (18,)),
}


def ramp(start, end, value):
    t = min(1, max(0, (value - start) / (end - start)))
    return t * t * (3 - 2 * t)


def color(hex_value):
    channels = bytes.fromhex(hex_value)
    return Vector([(c / 255 / 12.92 if c <= 10 else ((c / 255 + .055) / 1.055) ** 2.4)
                   for c in channels])


def locate_digit(point):
    x = 450 - abs(point.x) * 900 / 1.04
    y = 450 - (point.z - .5) * 900 / 1.04
    candidates = []
    for name, (tip, base, joints) in DIGITS.items():
        axis = Vector(base) - Vector(tip)
        delta = Vector((x, y)) - Vector(tip)
        along = delta.dot(axis.normalized())
        closest = axis.normalized() * min(axis.length, max(0, along))
        candidates.append(((delta - closest).length, name, along, axis.length, joints))
    return min(candidates)


def paint(point, digit):
    x, y, z = point
    ax = abs(x)
    # Material boundaries follow the sculpted cuff, belt and boot edges.
    leather = max(
        (1 - ramp(.236, .255, z)),
        ramp(.535, .544, z) * (1 - ramp(.613, .621, z)),
        ramp(.208, .225, ax) * ramp(.59, .63, z) * (1 - ramp(.81, .85, z)),
    )
    head = ramp(.818, .828, z)
    hand = ramp(.339, .352, ax)
    ivory = max(head, hand)
    cloth_color = color("2d2929")
    leather_color = color("78472b")
    ivory_color = color("d8ae83")
    base = cloth_color.lerp(leather_color, leather).lerp(ivory_color, ivory)
    sole = 1 - ramp(.016, .029, z)
    base = base.lerp(color("2b2220"), sole)

    eyes = 0
    stitches = 0
    if head > 0:
        eye = math.hypot((ax - .032) / .012, (z - .894) / .025)
        eyes = (1 - ramp(.82, 1.12, eye)) * (1 - ramp(-.082, -.055, y))
        seam = (1 - ramp(.001, .0032, ax)) * ramp(.062, .082, abs(y))
        pixel_y = 450 - (z - .5) * 900 / 1.04
        rows = (25, 39, 56, 76, 96, 117, 138, 156, 170, 180)
        nearest = min(abs(pixel_y - row) for row in rows)
        thread = (1 - ramp(4, 7, ax * 900 / 1.04)) * (1 - ramp(1, 2.6, nearest))
        stitches = head * max(seam, thread * ramp(.034, .061, abs(y)))
    distance, _, along, _, joints = digit
    gap = 0
    if hand > 0 and distance < 13:
        gap = 1 - ramp(.9, 2.9, min(abs(along - joint) for joint in joints))
        gap *= hand
    base = base.lerp(color("3c241b"), max(stitches, gap))
    base = base.lerp(color("171015"), eyes)
    # Keep the paint readable under the level lighting without baking highlights.
    grain = 1 + .028 * math.sin(105 * x + 128 * z) * math.sin(89 * y - 110 * z)
    return base * grain, max(eyes, stitches, gap), ivory, leather


def fit_position(source):
    point = source * 1.97
    point.z += .058 * ramp(.48, .72, source.z) * (1 - ramp(.82, .97, source.z))
    if abs(source.x) > .30:
        wrist = Vector((point.x, .013, 1.494))
        roll = math.pi / 2 * ramp(.315, .361, abs(source.x))
        point = wrist + Matrix.Rotation(roll, 3, "X") @ (point - wrist)
        # Slightly tuck the splayed fingertips toward the rig's fist arcs.
        tuck = ramp(.358, .456, abs(source.x))
        point.y = .013 + (point.y - .013) * (1 - .16 * tuck)
    return point


def skin_weights(source, point, digit):
    side = ".L" if source.x >= 0 else ".R"
    ax = abs(point.x)
    z = point.z
    if abs(source.x) > .322:
        wrist = ramp(.331, .368, abs(source.x))
        _, name, along, length, joints = digit
        finger = 1 - ramp(length - 7, length + 5, along)
        tip = 1 - ramp(joints[0] - 3, joints[0] + 3, along)
        base = ramp(joints[-1] - 3, joints[-1] + 3, along)
        if name == "thumb":
            segments = (.03, 1 - tip, tip)
        else:
            segments = (base, (1 - tip) * (1 - base), tip)
        return {"forearm" + side: 1 - wrist, "hand" + side: wrist * (1 - finger),
                **{f"{name}.{i:02}{side}": wrist * finger * weight
                   for i, weight in enumerate(segments, 1)}}
    if abs(source.x) > .067 and source.z > .59 and source.z < .806:
        arm = ramp(.139, .242, ax)
        elbow = ramp(.380, .511, ax)
        return {"chest": 1 - arm, "upper_arm" + side: arm * (1 - elbow),
                "forearm" + side: arm * elbow}
    if z > 1.53:
        head = ramp(1.573, 1.662, z)
        neck = ramp(1.53, 1.60, z) * (1 - head)
        return {"head": head, "neck": neck, "chest": 1 - head - neck}
    if z < 1.12:
        leg = 1 - ramp(.84, 1.105, z)
        shin = 1 - ramp(.577, .746, z)
        foot = 1 - ramp(.133, .254, z)
        toe = (1 - ramp(-.17, -.102, point.y)) * (1 - ramp(.065, .12, z))
        thigh = leg * (1 - shin)
        # The crotch bridges both legs. Fade across the center seam in that area.
        far_side = ".R" if side == ".L" else ".L"
        seam = .5 * (1 - ramp(0, .06, ax)) * ramp(.81, .96, z)
        return {"pelvis": 1 - leg, "thigh" + side: thigh * (1 - seam),
                "thigh" + far_side: thigh * seam,
                "shin" + side: leg * shin * (1 - foot),
                "foot" + side: leg * shin * foot * (1 - toe),
                "toe" + side: leg * shin * foot * toe}
    chest = ramp(1.17, 1.39, z)
    return {"spine": 1 - chest, "chest": chest}


def make_material(name, roughness):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    shader = nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Specular IOR Level"].default_value = .24
    paint_node = nodes.new("ShaderNodeVertexColor")
    paint_node.layer_name = "Paint"
    material.node_tree.links.new(paint_node.outputs["Color"], shader.inputs["Base Color"])
    return material


def build(source_file):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(source_file))
    mesh, = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    mesh.name = "OG_Base_Trial"
    world = mesh.matrix_world.copy()
    mesh.matrix_world = Matrix.Identity(4)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / "Assets/Threadborne/Player/LocalDoll/threadborne_doll_modular.glb"))
    rig, = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    for obj in list(bpy.context.scene.objects):
        if obj not in (mesh, rig):
            bpy.data.objects.remove(obj, do_unlink=True)
    rig.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    mesh.parent = rig
    mesh.matrix_parent_inverse = rig.matrix_world.inverted()
    modifier = mesh.modifiers.new("Current player bones", "ARMATURE")
    modifier.object = rig

    groups = {}
    colors = mesh.data.color_attributes.new(name="Paint", type="FLOAT_COLOR", domain="POINT")
    mesh.data.color_attributes.active_color = colors
    regions = []
    for vertex in mesh.data.vertices:
        source = world @ vertex.co
        digit = locate_digit(source)
        painted, detail, ivory, leather = paint(source, digit)
        colors.data[vertex.index].color = (*painted, 1)
        regions.append((detail, ivory, leather))
        point = fit_position(source)
        vertex.co = point
        weighted = sorted(skin_weights(source, point, digit).items(), key=lambda pair: -pair[1])[:4]
        weighted = [(name, weight) for name, weight in weighted if weight > 1e-5]
        total = sum(weight for _, weight in weighted)
        assert total > 0
        for name, weight in weighted:
            assert name in rig.data.bones, name
            if name not in groups:
                groups[name] = mesh.vertex_groups.new(name=name)
            groups[name].add([vertex.index], weight / total, "REPLACE")

    mesh.data.materials.clear()
    for name, roughness in [("Charcoal cloth", .94), ("Brown leather", .80),
                            ("Warm ivory", .74), ("Dark stitching and joints", .89)]:
        mesh.data.materials.append(make_material(name, roughness))
    for poly in mesh.data.polygons:
        detail, ivory, leather = (sum(regions[i][axis] for i in poly.vertices) / len(poly.vertices)
                                  for axis in range(3))
        poly.material_index = 3 if detail > .58 else 2 if ivory > .5 else 1 if leather > .5 else 0
        poly.use_smooth = True
    mesh.data.update()
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    rig.select_set(False)
    bpy.context.scene.display.shading.color_type = "VERTEX"
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.shading.color_type = "VERTEX"
    OUTPUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT / "OG_Base_Trial.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT / "OG_Base_Trial.glb"), export_animations=False,
                              export_vertex_color="ACTIVE", export_yup=True)
    print(f"OG fit exported {len(mesh.data.vertices)} weighted vertices and {len(groups)} bone groups.")


if __name__ == "__main__":
    build(Path(sys.argv[sys.argv.index("--") + 1]).resolve(strict=True))
