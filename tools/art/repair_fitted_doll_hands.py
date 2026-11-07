"""Repair the shared carved hands using the unchanged game skeleton and clips.

Blender --background --factory-startup --python-exit-code 1 --python this_file.
Reads the immutable before-pass GLB and writes the approved local candidate.
"""
from collections import defaultdict
from pathlib import Path
import json
import bpy
import bmesh
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "LocalOnly/Equipment/FeedbackReview2026_11_07"
SOURCE = REVIEW / "BeforeAssets/threadborne_doll_equipped.glb"
OUTPUT = ROOT / "Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
rig = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
body = bpy.data.objects["Threadborne_Doll"]
rig.data.pose_position = "REST"
for track in rig.animation_data.nla_tracks:
    track.mute = True
bpy.context.view_layer.update()
rest = {bone.name: list(bone.matrix_local) for bone in rig.data.bones}
original_actions = {action.name: tuple(action.frame_range) for action in bpy.data.actions}
material = body.data.materials[0]
hinge = material.copy()
hinge.name = "Doll_Dark_Wood_Hinges"
bsdf = next(node for node in hinge.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
# A material multiplier retains the existing texture; no raster repainting.
socket = bsdf.inputs["Base Color"]
if socket.is_linked:
    source_socket = socket.links[0].from_socket
    hinge.node_tree.links.remove(socket.links[0])
    tint = hinge.node_tree.nodes.new("ShaderNodeMix")
    tint.data_type = "RGBA"
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 1
    color_a = next(s for s in tint.inputs if s.type == "RGBA" and s.name == "A")
    color_b = next(s for s in tint.inputs if s.type == "RGBA" and s.name == "B")
    color_b.default_value = (.26, .16, .10, 1)
    hinge.node_tree.links.new(source_socket, color_a)
    hinge.node_tree.links.new(next(s for s in tint.outputs if s.type == "RGBA"), socket)
bsdf.inputs["Roughness"].default_value = .56
parts = []
stats = []


def bind_rigid(obj, bone):
    obj.vertex_groups.clear()
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1, "REPLACE")
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    obj.modifiers.clear()
    modifier = obj.modifiers.new("Rigid carved articulation", "ARMATURE")
    modifier.object = rig
    parts.append(obj)


def closed_part(name, face_ids):
    obj = body.copy()
    obj.data = body.data.copy()
    obj.name = name
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[face for face in bm.faces if face.index not in face_ids], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    # glTF splits vertices along UV seams. Weld their positions before capping;
    # UVs remain per-corner, so painted seams do not become false geometric holes.
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.000001)
    # The rigid round hinges cover the articulation ends. Filling these
    # irregular painted boundaries creates large, incorrectly UV-mapped caps.
    bm.to_mesh(obj.data)
    bm.free()
    return obj


owners = defaultdict(set)
remove = set()
for face in body.data.polygons:
    center = sum((body.data.vertices[index].co for index in face.vertices), Vector()) / len(face.vertices)
    side = "L" if center.x >= 0 else "R"
    wrist = rig.data.bones["hand."+side].head_local
    if abs(center.x) <= abs(wrist.x)-.028 or center.z < 1.35:
        continue
    remove.add(face.index)
    if abs(center.x) < abs(wrist.x)+.028:
        continue  # Replace the displaced old wrist with a centered rigid ball.
    weights = defaultdict(float)
    for index in face.vertices:
        for group in body.data.vertices[index].groups:
            name = body.vertex_groups[group.group].name
            if name.endswith("."+side):
                weights[name] += group.weight
    bone = max(weights, key=weights.get)
    if not bone.startswith(("index.", "middle.", "ring.", "pinky.", "thumb.")):
        bone = "hand."+side
    owners[bone].add(face.index)

for bone, faces in owners.items():
    part = closed_part("Carved_"+bone, faces)
    low = Vector([min(v.co[i] for v in part.data.vertices) for i in range(3)])
    high = Vector([max(v.co[i] for v in part.data.vertices) for i in range(3)])
    anchor = rig.data.bones[bone].head_local
    if bone.startswith("hand."):
        desired = anchor
    else:
        digit, segment, side = bone.split(".")
        successor = rig.data.bones.get(f"{digit}.{int(segment)+1:02d}.{side}")
        end = successor.head_local if successor else anchor+(anchor-rig.data.bones[f"{digit}.02.{side}"].head_local)
        desired = (anchor+end)*.5
    offset = Vector((0, desired.y-(low.y+high.y)*.5, desired.z-(low.z+high.z)*.5))
    for vertex in part.data.vertices:
        vertex.co += offset
    bind_rigid(part, bone)
    stats.append({"bone": bone, "vertices": len(part.data.vertices), "centering_offset": list(offset)})

for side in "LR":
    for digit in ("index", "middle", "ring", "pinky", "thumb", "wrist"):
        for segment in ((0,) if digit == "wrist" else (1, 2, 3)):
            bone = "hand."+side if digit == "wrist" else f"{digit}.{segment:02d}.{side}"
            owner = "forearm."+side if digit == "wrist" else ("hand."+side if segment == 1 else f"{digit}.{segment-1:02d}.{side}")
            center = rig.matrix_world @ rig.data.bones[bone].head_local
            radius = .029 if digit == "wrist" else (.015 if digit == "thumb" else .013)
            bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=radius, location=center)
            obj = bpy.context.object
            obj.name = "Rigid_Hinge_"+bone
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            obj.data.materials.append(hinge)
            for polygon in obj.data.polygons:
                polygon.use_smooth = True
            bind_rigid(obj, owner)

bm = bmesh.new()
bm.from_mesh(body.data)
bm.faces.ensure_lookup_table()
bmesh.ops.delete(bm, geom=[face for face in bm.faces if face.index in remove], context="FACES")
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
bm.to_mesh(body.data)
bm.free()
bpy.ops.object.select_all(action="DESELECT")
for obj in [body]+parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
body.name = "Threadborne_Doll"
body.data.update()
assert len(rig.data.bones) == 62
assert all(tuple(action.frame_range) == original_actions[action.name] for action in bpy.data.actions)
for image in bpy.data.images:
    if image.source == "FILE" and not image.packed_file:
        image.pack()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/"Shared_Hands_Repair.blend"), compress=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    # Imported attachment empties must accompany their bone-parented meshes.
    if obj.type != "MESH" or not obj.hide_render:
        obj.select_set(True)
bpy.context.view_layer.objects.active = rig
rig.data.pose_position = "POSE"
bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True,
    export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True,
    export_skins=True, export_def_bones=False, export_cameras=False, export_lights=False)
(REVIEW/"hand_repair_report.json").write_text(json.dumps({"parts": stats, "hinges":32,
    "bones":62, "actions":original_actions, "source":str(SOURCE)}, indent=2), encoding="utf-8")
print("SHARED_HANDS_REPAIRED",len(parts),"rigid pieces; 62 unchanged bones;",len(original_actions),"clips",flush=True)
