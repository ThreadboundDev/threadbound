"""Fit the rebuilt shield to the current bracers and export only the shield."""

import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / "LocalOnly/Equipment"
SOURCE = ROOT / "ArtSource/Player/Blender/shield_revision/Threadborne_Sword_Shield_Rear_Fix.blend"
OUTPUT = ROOT / "Assets/Threadborne/Player/LocalDoll/Equipment/base_shield.glb"
REVIEW = LOCAL / "Shield"
BACK_PLANE = 1.598
REVIEW.mkdir(parents=True, exist_ok=True)
(REVIEW / ".gdignore").touch()

bpy.ops.wm.open_mainfile(filepath=str(LOCAL / "BaseBlue/BaseBlue_Fitted.blend"))
scene = bpy.context.scene
rig = next(obj for obj in scene.objects if obj.type == "ARMATURE")
rig.data.pose_position = "REST"
shield = []
prefixes = ("Shield_Original_Front", "Shield_Back_Board_", "Shield_Back_Brass_Rim", "Shield_Ornament_Rear_Cap")
with bpy.data.libraries.load(str(SOURCE)) as (library, imported):
    imported.objects = [name for name in library.objects if name.startswith(prefixes)]
assert any(obj.name.startswith("Shield_Original_Front") for obj in imported.objects)
for obj in imported.objects:
    scene.collection.objects.link(obj)
    source_matrix = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    obj.data = obj.data.copy()
    for vertex in obj.data.vertices:
        x, y, z = source_matrix @ vertex.co
        vertex.co = (.606 + .92*(y-.14), .024 + .92*(z+.030), BACK_PLANE + .60*x)
    shield.append(obj)

if "--front" in sys.argv:
    front_source = Path(sys.argv[sys.argv.index("--front")+1])
    for old_part in list(shield):
        if old_part.name.startswith(("Shield_Original_Front", "Shield_Back_Brass_Rim", "Shield_Ornament_Rear_Cap")):
            shield.remove(old_part)
            bpy.data.objects.remove(old_part, do_unlink=True)
    with bpy.data.libraries.load(str(front_source)) as (library, revised):
        revised.objects = ["Shield_Revised_Front"]
    front = revised.objects[0]
    scene.collection.objects.link(front)
    front.parent = None
    front.matrix_world = Matrix.Identity(4)
    front.name = "Shield_Original_Front"
    shield.append(front)


def material(name, color, roughness, metallic=0):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    result.diffuse_color = (*color, 1)
    return result


leather = material("Shield strap warm leather", (.105, .048, .022), .80)
wood = material("Shield dark rear boards", (.060, .040, .026), .83)
brass = material("Shield strap aged brass", (.34, .177, .056), .40, .7)
for obj in shield:
    if not obj.name.startswith("Shield_Original_Front"):
        obj.data.materials.clear()
        obj.data.materials.append(wood if obj.name.startswith("Shield_Back_Board") else brass)


def block(name, position, dimensions, surface):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.scale = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(surface)
    bevel = obj.modifiers.new("Rounded edges", "BEVEL")
    bevel.width = .0015
    bevel.segments = 2
    shield.append(obj)


bracers = [bpy.data.objects[name] for name in ("base_Bracers", "blue_Bracers")]
grapples = [bpy.data.objects[name] for name in (
    "Base_Grapple_Coil", "Grapple_Needle_Base", "Blue_Grapple_Reel", "Grapple_Needle_BlueHook",
)]


def lower_wrap(points):
    # Expand the cross section by the leather's clearance, then trace its
    # lower convex boundary from one side of the arm to the other.
    offsets = [(.009*math.cos(i*math.tau/16), .009*math.sin(i*math.tau/16)) for i in range(16)]
    outline = sorted({(p.y+dy,p.z+dz) for p in points for dy,dz in offsets})
    lower = []
    for point in outline:
        while len(lower) >= 2:
            a,b = lower[-2:]
            if (b[0]-a[0])*(point[1]-a[1]) > (b[1]-a[1])*(point[0]-a[0]):
                break
            lower.pop()
        lower.append(point)
    return [(lower[0][0],BACK_PLANE-.006), *lower, (lower[-1][0],BACK_PLANE-.006)]


for label, x, width in (("elbow", .527, .024), ("wrist", .655, .020)):
    points = [obj.matrix_world @ v.co for obj in bracers+grapples for v in obj.data.vertices
              if abs((obj.matrix_world @ v.co).x-x) < width*.65]
    high_z = max(p.z for p in points)
    path = lower_wrap(points)
    verts = [(x+offset, y, z) for y, z in path for offset in (-width/2, width/2)]
    faces = [(2*i, 2*i+1, 2*i+3, 2*i+2) for i in range(len(path)-1)]
    mesh = bpy.data.meshes.new(f"Shield_{label}_strap")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    strap = bpy.data.objects.new(mesh.name, mesh)
    scene.collection.objects.link(strap)
    mesh.materials.append(leather)
    thickness = strap.modifiers.new("Leather thickness", "SOLIDIFY")
    thickness.thickness = .004
    shield.append(strap)
    for y in (path[0][0], path[-1][0]):
        block(f"Shield_{label}_anchor", (x, y, BACK_PLANE-.008), (width+.006, .021, .008), brass)
    pad_top = BACK_PLANE-.004
    block(f"Shield_{label}_forearm_pad", (x, .004, (high_z+pad_top)/2),
          (width+.008, .055, pad_top-high_z), leather)
    buckle_y, buckle_z = min(path,key=lambda point: point[1])
    block(f"Shield_{label}_fastener", (x, buckle_y, buckle_z-.003), (width+.004, .020, .006), brass)

bpy.ops.object.select_all(action="DESELECT")
for obj in shield:
    obj.hide_set(False)
    obj.hide_render = False
    matrix = obj.matrix_world.copy()
    obj.parent = rig
    obj.matrix_world = matrix
    obj.vertex_groups.new(name="forearm.L").add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    obj.modifiers.new("Shield follows left forearm", "ARMATURE").object = rig
    obj.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True,
                         export_animations=False, export_skins=True, export_apply=True)

camera = scene.camera
target = Vector((.61, .015, 1.54))
for label, direction in (("rear", (.2, .65, -1)), ("side", (.08, 1, -.22))):
    camera.location = target + Vector(direction).normalized()*2
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = .65
    scene.render.resolution_x = 850
    scene.render.resolution_y = 670
    for obj in scene.objects:
        if obj.type == "MESH":
            obj.hide_render = obj not in shield and obj.name not in ("base_Bracers", "Shared_Wooden_Hands")
    scene.render.filepath = str(REVIEW / f"shield_{label}.png")
    bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW / "Threadborne_Forearm_Shield.blend"), compress=True)
print("FOREARM_SHIELD_EXPORTED", len(shield), "parts")
