"""Render the existing rig with an illustrated material; never edit its source.

Run with Blender --background --factory-startup --python render_study.py.
The optional argument after -- selects 'stills' (default), 'motion', or 'jump'.
"""
import hashlib
import json
import math
import sys
from array import array
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
SOURCE = ROOT / "ArtSource/Player/Blender/imported_character/mixamo_test/Threadborne_Equipped_Animation_Test.blend"
MODE = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "stills"
source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
s = bpy.context.scene
rig = bpy.data.objects["Threadborne_Rig"]
body = bpy.data.objects["Threadborne_Character"]
positions = array("f", [0.0]) * (len(body.data.vertices) * 3)
body.data.vertices.foreach_get("co", positions)
geometry_digest = hashlib.sha256(positions.tobytes()).hexdigest()
original_surfaces = {mat.name: next(n for n in mat.node_tree.nodes if n.type == "OUTPUT_MATERIAL").inputs["Surface"].links[0].from_socket for mat in bpy.data.materials if mat.use_nodes and any(n.type == "OUTPUT_MATERIAL" and n.inputs["Surface"].is_linked for n in mat.node_tree.nodes)}


def camera(quarter=False):
    target = Vector((0, 0, 1.275))
    s.camera.location = target + (Vector((-4, -6, 0)) if quarter else Vector((-6, 0, 0)))
    s.camera.rotation_euler = (target - s.camera.location).to_track_quat("-Z", "Y").to_euler()
    s.camera.data.type = "ORTHO"
    s.camera.data.ortho_scale = 3.0


def render(name):
    s.render.filepath = str(OUT / name)
    bpy.ops.render.render(write_still=True)
    print("STUDY_RENDER", name, flush=True)


def equipment(visible):
    for name in ["Threadborne_Sword_ROOT", "Threadborne_Shield_ROOT"]:
        root = bpy.data.objects[name]
        for ob in [root, *root.children_recursive]:
            ob.hide_render = not visible


def illustrated_materials():
    # Use baked painted texture detail, broad geometric form shading, and AO.
    # Deliberately omit the noisy normal maps and metallic/specular response.
    # This renderer is Cycles-compatible and has no live-game dependency.
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        p = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
        output = next((n for n in nodes if n.type == "OUTPUT_MATERIAL"), None)
        if p is None or output is None:
            continue
        base = p.inputs["Base Color"]
        if base.is_linked:
            color = base.links[0].from_socket
        else:
            constant = nodes.new("ShaderNodeRGB")
            constant.outputs[0].default_value = base.default_value
            color = constant.outputs[0]
        curves = nodes.new("ShaderNodeRGBCurve")
        curves.name = "STUDY - painted value contrast"
        curve = curves.mapping.curves[3]
        curve.points.new(0.04, 0.022)
        curve.points.new(0.18, 0.13)
        curve.points.new(0.55, 0.64)
        curves.mapping.update()
        links.new(color, curves.inputs["Color"])
        tint = nodes.new("ShaderNodeMixRGB")
        tint.name = "STUDY - warm ivory and leather"
        tint.blend_type = "MULTIPLY"
        tint.inputs[0].default_value = 1.0
        tint.inputs[2].default_value = (1.08, 0.94, 0.79, 1.0)
        links.new(curves.outputs["Color"], tint.inputs[1])
        geom = nodes.new("ShaderNodeNewGeometry")
        dot = nodes.new("ShaderNodeVectorMath")
        dot.operation = "DOT_PRODUCT"
        dot.inputs[1].default_value = Vector((-0.65, -0.45, 0.85)).normalized()
        links.new(geom.outputs["Normal"], dot.inputs[0])
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.name = "STUDY - broad illustrated form shading"
        ramp.color_ramp.interpolation = "EASE"
        elements = ramp.color_ramp.elements
        elements[0].position = 0.0
        elements[0].color = (0.46, 0.46, 0.48, 1)
        elements[1].position = 0.95
        elements[1].color = (1.15, 1.15, 1.15, 1)
        for position, value in [(0.23, 0.65), (0.49, 0.86), (0.73, 1.03)]:
            e = elements.new(position)
            e.color = (value, value, value, 1)
        links.new(dot.outputs["Value"], ramp.inputs[0])
        shade = nodes.new("ShaderNodeMixRGB")
        shade.blend_type = "MULTIPLY"
        shade.inputs[0].default_value = 1
        links.new(tint.outputs[0], shade.inputs[1])
        links.new(ramp.outputs[0], shade.inputs[2])
        ao = nodes.new("ShaderNodeAmbientOcclusion")
        ao.inputs["Distance"].default_value = 0.10
        ao.samples = 8
        occlude = nodes.new("ShaderNodeMixRGB")
        occlude.blend_type = "MULTIPLY"
        occlude.inputs[0].default_value = 0.35
        links.new(shade.outputs[0], occlude.inputs[1])
        links.new(ao.outputs["AO"], occlude.inputs[2])
        emission = nodes.new("ShaderNodeEmission")
        links.new(occlude.outputs[0], emission.inputs["Color"])
        links.new(emission.outputs[0], output.inputs["Surface"])
    s.view_settings.view_transform = "Standard"
    s.view_settings.look = "None"
    s.view_settings.exposure = 0
    s.view_settings.gamma = 1


def reference_pose():
    # A new display pose only. No rest-bone or mesh/proportion modifications.
    rig.animation_data_clear()
    for pb in rig.pose.bones:
        for constraint in pb.constraints:
            constraint.mute = True
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    for side, angle in [("L", 76), ("R", -76)]:
        pb = rig.pose.bones[f"upper_arm.{side}"]
        head = pb.bone.head_local
        rotation = Quaternion((0, 1, 0), math.radians(angle)).to_matrix().to_4x4()
        pb.matrix = Matrix.Translation(head) @ rotation @ Matrix.Translation(-head) @ pb.bone.matrix_local
        bpy.context.view_layer.update()


s.render.resolution_x, s.render.resolution_y = (600, 800)
s.render.resolution_percentage = 100
s.render.film_transparent = True
s.render.image_settings.file_format = "PNG"
s.render.image_settings.color_mode = "RGBA"
s.render.image_settings.color_depth = "8"
s.cycles.samples = 16
s.cycles.use_denoising = True
s.render.use_persistent_data = True
camera()
s.frame_set(38)

if MODE == "stills":
    illustrated_materials()
    render("ink_side_raw.png")
    camera(True)
    render("ink_quarter_raw.png")
    equipment(False)
    reference_pose()
    render("ink_reference_raw.png")
    for name, socket in original_surfaces.items():
        mat = bpy.data.materials[name]
        output = next(n for n in mat.node_tree.nodes if n.type == "OUTPUT_MATERIAL")
        mat.node_tree.links.new(socket, output.inputs["Surface"])
    render("source_reference_raw.png")
    illustrated_materials()
    camera()
    render("ink_reference_side_raw.png")
elif MODE in {"motion", "jump"}:
    camera(True)
    illustrated_materials()
    (OUT / "frames").mkdir(exist_ok=True)
    manifest = []
    if MODE == "jump":
        manifest = [record for record in json.loads((OUT / "motion_manifest.json").read_text()) if record["clip"] != "jump"]
    origin = s.camera.location.copy()
    rest_z = rig.data.bones["pelvis"].head_local.z
    # Exact source spans, sampled at approximately 12 fps. Strip baked airborne
    # lift as the prior export did, leaving future world travel to the controller.
    for label, start, end, samples in [("idle", 1, 77, 31), ("run", 78, 99, 9), ("jump", 100, 125, 11)]:
        if MODE == "jump" and label != "jump":
            continue
        for index in range(samples):
            frame = min(end, start + round(index * (end - start + 1) / samples))
            s.frame_set(frame)
            lift = max(0.0, rig.pose.bones["pelvis"].head.z - rest_z) if label == "jump" else 0.0
            s.camera.location = origin + Vector((0, 0, lift))
            name = f"frames/{label}_{index:03d}.png"
            render(name)
            manifest.append({"clip": label, "frame": frame, "file": name, "duration_ms": round((end - start + 1) / 30 / samples * 1000), "removed_vertical_travel_m": lift})
    (OUT / "motion_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
else:
    raise ValueError(MODE)

assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == source_hash
body.data.vertices.foreach_get("co", positions)
assert hashlib.sha256(positions.tobytes()).hexdigest() == geometry_digest
report = {"source": str(SOURCE.relative_to(ROOT)), "source_sha256": source_hash, "geometry_sha256": geometry_digest, "geometry_vertices": len(body.data.vertices), "source_unchanged": True, "geometry_changes": False, "mode": MODE, "canvas": [600, 800], "camera": "level three-quarter orthographic (-4,-6); true -X side stills also supplied", "outline": "applied by package_study.py after rendering"}
(OUT / f"render_{MODE}_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("STUDY_COMPLETE", MODE, flush=True)
