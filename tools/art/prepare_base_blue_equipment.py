"""Fit the downloaded Base and Blue outfits to the existing game rig.

Run from Blender with --background --factory-startup --python-exit-code 1
--python tools/art/prepare_base_blue_equipment.py -- <archive directory>.
The source downloads, previous equipment, and player rig are preserved.
"""

import bpy
import bmesh
from collections import defaultdict
from pathlib import Path
import hashlib
import json
import math
import re
import struct
import sys
import zipfile
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree

ROOT = Path(__file__).resolve().parents[2]
ARCHIVES = Path(sys.argv[sys.argv.index("--") + 1])
SCRATCH = ROOT / "tmp/base_blue_fit"
OUT = ROOT / "Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets"
REPORT = ROOT / "LocalOnly/Equipment/BaseBlue"
for folder in (SCRATCH, OUT, REPORT):
    folder.mkdir(parents=True, exist_ok=True)
(REPORT / ".gdignore").touch()

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(OUT.parents[1] / "threadborne_doll_equipped.glb"))
rig = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
body = bpy.data.objects["Threadborne_Doll"]
rig.animation_data_clear()
rig.data.pose_position = "REST"
for obj in list(bpy.context.scene.objects):
    if obj not in (rig, body):
        bpy.data.objects.remove(obj, do_unlink=True)
bpy.context.view_layer.update()
rest = {bone.name: rig.matrix_world @ bone.matrix_local for bone in rig.data.bones}
ELBOW = abs(rest["forearm.L"].translation.x)
WRIST = abs(rest["hand.L"].translation.x)
ARM_HEIGHT = rest["forearm.L"].translation.z
CUFF = .415
HAND_JOIN = WRIST + .009
report = {"sources": {}, "slots": {}, "anchors": {}, "cut_planes": {"elbows": [-ELBOW, ELBOW], "boot_cuffs": CUFF}}

body_points = [body.matrix_world @ v.co for v in body.data.vertices]
body_weights = [
    {body.vertex_groups[group.group].name: group.weight for group in v.groups}
    for v in body.data.vertices
]
body_tree = KDTree(len(body_points))
for index, point in enumerate(body_points):
    body_tree.insert(point, index)
body_tree.balance()


def imported(key, archive_name):
    archive = ARCHIVES / archive_name
    report["sources"][key] = {"file": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest()}
    directory = SCRATCH / ("input_" + key)
    with zipfile.ZipFile(archive) as package:
        for member in package.infolist():
            if not (directory / member.filename).resolve().is_relative_to(directory.resolve()):
                raise ValueError(f"Unexpected archive path: {member.filename}")
        package.extractall(directory)
    before = set(bpy.context.scene.objects)
    fbx = next(directory.glob("*.fbx"))
    bpy.ops.import_scene.fbx(filepath=str(fbx))
    objects = set(bpy.context.scene.objects) - before
    obj, = [item for item in objects if item.type == "MESH"]
    world = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    obj.data.transform(world)
    obj.name = key
    for item in objects - {obj}:
        bpy.data.objects.remove(item, do_unlink=True)
    for material in obj.data.materials:
        if material and material.use_nodes:
            for node in material.node_tree.nodes:
                if node.type == "NORMAL_MAP" and not node.inputs["Color"].is_linked:
                    material.node_tree.nodes.remove(node)
                    break
    return obj


def segment(value, anchors):
    for (a, b), (c, d) in zip(anchors, anchors[1:]):
        if value <= c or c == anchors[-1][0]:
            return b + (value-a)*(d-b)/(c-a)


def bounds(points):
    points = list(points)
    return [Vector([fn(v[i] for v in points) for i in range(3)]) for fn in (min,max)]


def smooth(value):
    value = min(1.0, max(0.0, value))
    return value*value*(3-2*value)


def tag_hanging_cloth(obj, set_name):
    """Preserve the attachment of detached leather and ribbon islands."""
    if set_name != "blue":
        return
    parents = list(range(len(obj.data.vertices)))

    def root(index):
        while index != parents[index]:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    for edge in obj.data.edges:
        a, b = edge.vertices
        parents[root(a)] = root(b)
    components = defaultdict(list)
    for vertex in obj.data.vertices:
        components[root(vertex.index)].append(vertex)
    waist = obj.vertex_groups.new(name="Fit_Waist")
    shoulder = obj.vertex_groups.new(name="Fit_ShoulderRibbon")
    for vertices in components.values():
        low, high = bounds(v.co for v in vertices)
        if low.y > .022 and .41 < low.z < .48 and .78 < high.z < .84:
            shoulder.add([v.index for v in vertices], 1, "REPLACE")
        elif .34 < low.z < .54 and .57 < high.z < .65 and max(abs(low.x),abs(high.x)) < .18:
            # The front sash, hip panels and waist ribbon have no knee joint.
            waist.add([v.index for v in vertices], 1, "REPLACE")


def align(obj, set_name):
    # Measured from the imported, normalized meshes. Both remaps end at the
    # same rest landmarks. The shirt, pants and boot silhouettes stay distinct.
    blue = set_name == "blue"
    elbow = .239 if blue else .225
    wrist = .382 if blue else .3725
    x_anchors = [(0,0),(.09,.1767),(elbow,ELBOW),(wrist,WRIST),(.49976,.94954)]
    z_anchors = [
        (0,0),(.081 if blue else .092,.1729),
        (.1755 if blue else .198,CUFF),(.322 if blue else .342,.665),
        (.532 if blue else .548,1.045),(.772 if blue else .765,ARM_HEIGHT),
        (.842 if blue else .826,1.65),(.988 if blue else .975,1.94 if blue else 1.886),
    ]
    for v in obj.data.vertices:
        x, y, z = v.co
        # Feet and cuffs translate as units rather than distorting across x.
        if z < .322:
            foot_center = .084 if blue else .086
            side = 1 if x >= 0 else -1
            low_x = .1349 + (abs(x)-foot_center)*1.68
            blend = smooth((z-.175)/.147)
            new_x = side*((1-blend)*low_x + blend*segment(abs(x),x_anchors))
        else:
            new_x = math.copysign(segment(abs(x),x_anchors),x)
        y_center = .008
        if abs(x) > elbow and z > .69:
            y_center = .015 if blue else .013
        v.co = (new_x, (y-y_center)*1.76, segment(z,z_anchors))
    obj.data.update()


def bisect(mesh, point, normal):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    geom = list(bm.verts) + list(bm.edges) + list(bm.faces)
    bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-6, plane_co=point, plane_no=normal)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def region_copy(source, name, include, cap_planes=()):
    result = source.copy()
    result.data = source.data.copy()
    bpy.context.collection.objects.link(result)
    result.name = name
    result.data.name = name
    bm = bmesh.new()
    bm.from_mesh(result.data)
    remove = [face for face in bm.faces if not include(face.calc_center_median())]
    bmesh.ops.delete(bm, geom=remove, context="FACES")
    bmesh.ops.delete(bm, geom=[vert for vert in bm.verts if not vert.link_faces], context="VERTS")
    for axis, value in cap_planes:
        boundary = [edge for edge in bm.edges if edge.is_boundary and all(abs(v.co[axis]-value)<2e-5 for v in edge.verts)]
        if boundary:
            bmesh.ops.holes_fill(bm, edges=boundary, sides=0)
    bm.to_mesh(result.data)
    bm.free()
    result.data.update()
    assert result.data.polygons, name
    return result


def reference_seam(obj, axis, value, filter_point):
    points = [v.co for v in obj.data.vertices if abs(v.co[axis]-value)<2e-5 and filter_point(v.co)]
    low, high = bounds(points)
    return low, high


def align_seams(obj, seams):
    # Use identical seam extents on both sets, fading the adjustment away
    # from the cut. Weight rules below are also common on each cut plane.
    for axis, value, filter_point, center, half, width in seams:
        low, high = reference_seam(obj, axis, value, filter_point)
        for vertex in obj.data.vertices:
            point = vertex.co
            influence = 1-smooth(abs(point[axis]-value)/width)
            if influence <= 0 or not filter_point(point):
                continue
            for i in range(3):
                if i != axis and high[i]-low[i] > 1e-5:
                    coordinate = 2*(point[i]-low[i])/(high[i]-low[i])-1
                    desired = center[i]+half[i]*coordinate
                    point[i] += influence*(desired-point[i])
    obj.data.update()


def inherited(point):
    weights = defaultdict(float)
    for _, index, distance in body_tree.find_n(point, 8):
        factor = 1/max(.008,distance)**3
        for bone, weight in body_weights[index].items():
            weights[bone] += factor*weight
    return dict(sorted(weights.items(), key=lambda entry: entry[1], reverse=True)[:4])


def outfit_weights(point, hints):
    side = "L" if point.x >= 0 else "R"
    if point.z > 1.65:
        return {"head": 1}
    if "Fit_Waist" in hints:
        return {"pelvis": 1}
    if "Fit_ShoulderRibbon" in hints:
        blend = smooth((point.z-.94)/.55)
        return {"pelvis": 1-blend, "chest": blend}
    if abs(point.x) > .278 and point.z > 1.21:
        mix = smooth((abs(point.x)-ELBOW+.055)/.11)
        return {f"upper_arm.{side}": 1-mix, f"forearm.{side}": mix}
    if point.z < .99:
        shin = 1-smooth((point.z-.585)/.16)
        foot = 1-smooth((point.z-.130)/.134)
        toe = (1-smooth((point.y+.173)/.09))*.73
        middle = 1-smooth(abs(point.x)/.085)
        pelvis = max(smooth((point.z-.87)/.12), middle*smooth((point.z-.73)/.16))
        return {
            f"thigh.{side}": (1-shin)*(1-pelvis), f"shin.{side}": shin*(1-foot),
            f"foot.{side}": foot*(1-toe), f"toe.{side}": foot*toe, "pelvis": pelvis,
        }
    return inherited(point)


def bind(obj, weights):
    hints = [{obj.vertex_groups[group.group].name for group in vertex.groups}
             for vertex in obj.data.vertices]
    obj.vertex_groups.clear()
    for vertex in obj.data.vertices:
        group_weights = {bone: value for bone,value in weights(vertex.co,hints[vertex.index]).items() if value > 1e-6}
        total = sum(group_weights.values())
        if not total:
            raise ValueError(f"Unweighted vertex in {obj.name}")
        for bone, value in group_weights.items():
            group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
            group.add([vertex.index], value/total, "REPLACE")
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    modifier = obj.modifiers.new("Game skeleton", "ARMATURE")
    modifier.object = rig
    return obj


def hands_from_master():
    mesh = body.copy()
    mesh.data = body.data.copy()
    bpy.context.collection.objects.link(mesh)
    matrix = mesh.matrix_world.copy()
    mesh.parent = None
    mesh.matrix_world = Matrix.Identity(4)
    mesh.data.transform(matrix)
    for modifier in list(mesh.modifiers):
        mesh.modifiers.remove(modifier)
    for side in (-1,1):
        bisect(mesh.data, (side*HAND_JOIN,0,0), (1,0,0))
    hands = region_copy(mesh, "Shared_Wooden_Hands", lambda p: abs(p.x)>HAND_JOIN,
                        [(0,-HAND_JOIN),(0,HAND_JOIN)])
    hands.parent = rig
    hands.matrix_parent_inverse = rig.matrix_world.inverted()
    modifier = hands.modifiers.new("Game skeleton", "ARMATURE")
    modifier.object = rig
    bpy.data.objects.remove(mesh,do_unlink=True)
    return hands


def grapple_assets(key, source):
    blue = key == "blue"
    # The Blue source is exported with its reel already facing outward. The
    # Base source lies flat, so its face is turned out from the left forearm.
    if blue:
        split = -.161
        bisect(source.data,(split,0,0),(1,0,0))
        static = region_copy(source, "Blue_Grapple_Reel", lambda p: p.x<split, [(0,split)])
        moving = region_copy(source, "Grapple_Needle_BlueHook", lambda p: p.x>split, [(0,split)])
        def fitted(p):
            return Vector((.608+p.x*.170,-.089+p.y*.155,ARM_HEIGHT+(p.z-.151)*.194))
        anchor = fitted(Vector((-.177,-.075,.154)))
    else:
        split = -.189
        bisect(source.data,(0,split,0),(0,1,0))
        static = region_copy(source, "Base_Grapple_Coil", lambda p: p.y>split, [(1,split)])
        moving = region_copy(source, "Grapple_Needle_Base", lambda p: p.y<split, [(1,split)])
        def fitted(p):
            return Vector((.565+p.x*.204,-.044-p.z*.187,ARM_HEIGHT+(p.y-.009)*.139))
        anchor = fitted(Vector((-.374,-.215,.124)))
    for obj in (static,moving):
        for vert in obj.data.vertices:
            vert.co = fitted(vert.co)
        bpy.context.view_layer.objects.active = obj
        reduce = obj.modifiers.new("Game prop reduction", "DECIMATE")
        reduce.ratio = .55
        bpy.ops.object.modifier_apply(modifier=reduce.name)
        bind(obj, lambda _p, _hints: {"forearm.L": 1})
    local = rest["forearm.L"].inverted()@anchor
    report["anchors"][key] = list(local)
    return [static,moving]


def texture_policy(path):
    raw = path.read_bytes()
    json_size = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20+json_size])
    for image in doc.get("images", []):
        view = doc["bufferViews"][image["bufferView"]]
        suffix = ".jpg" if image["mimeType"] == "image/jpeg" else ".png"
        image_path = path.parent / (path.stem + "_" + image["name"] + suffix)
        assert image_path.resolve().is_relative_to(path.parent.resolve())
        offset = 28 + json_size + view.get("byteOffset",0)
        image_path.write_bytes(raw[offset:offset+view["byteLength"]])
        config = Path(str(image_path)+".import")
        if config.exists():
            text = config.read_text(encoding="utf-8")
            text = re.sub(r"^compress/mode=.*$", "compress/mode=2", text, flags=re.M)
            text = re.sub(r"^detect_3d/compress_to=.*$", "detect_3d/compress_to=0", text, flags=re.M)
            text = re.sub(r"^process/size_limit=.*$", "process/size_limit=2048", text, flags=re.M)
            if "process/size_limit=" not in text:
                text = text.rstrip() + "\nprocess/size_limit=2048\n"
        else:
            resource_path = "res://" + image_path.relative_to(ROOT).as_posix()
            text = ('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
                    f'[deps]\nsource_file="{resource_path}"\n\n'
                    '[params]\ncompress/mode=2\nmipmaps/generate=true\nprocess/size_limit=2048\ndetect_3d/compress_to=0\n')
        config.write_text(text,encoding="utf-8")


def export(key, slot, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [rig]+objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    file = OUT / f"{key}_{slot}.glb"
    bpy.ops.export_scene.gltf(filepath=str(file),export_format="GLB",use_selection=True,
                             export_animations=False,export_skins=True,export_def_bones=False,
                             export_cameras=False,export_lights=False,export_yup=True)
    texture_policy(file)
    for obj in objects:
        obj.data.calc_loop_triangles()
    report["slots"][f"{key}_{slot}"] = {"meshes":[obj.name for obj in objects],
                                       "triangles":sum(len(obj.data.loop_triangles) for obj in objects)}


seams = [(0,side*ELBOW,lambda p: p.z>1.30,Vector((0,-.008,ARM_HEIGHT)),Vector((0,.052,.053)),.052)
         for side in (-1,1)]
seams += [(2,CUFF,lambda p, side=side: side*p.x>0,Vector((side*.132,.001,0)),Vector((.066,.062,0)),.062)
          for side in (-1,1)]
groups = {}
hands = hands_from_master()
for key, outfit_archive, grapple_archive in (
    ("base","base gear model.zip","lasso rope 3d model.zip"),
    ("blue","Blue gear.zip","fantasy weapon 3d model.zip"),
):
    outfit = imported(key, outfit_archive)
    tag_hanging_cloth(outfit,key)
    align(outfit,key)
    for axis,value in [(0,-HAND_JOIN),(0,-ELBOW),(0,ELBOW),(0,HAND_JOIN),(2,CUFF)]:
        direction = Vector([float(i == axis) for i in range(3)])
        bisect(outfit.data,value*direction,direction)
    align_seams(outfit,seams)
    gloves = bind(region_copy(outfit,f"{key}_Bracers",lambda p: ELBOW<abs(p.x)<HAND_JOIN,
                              [(0,-ELBOW),(0,ELBOW),(0,-HAND_JOIN),(0,HAND_JOIN)]),outfit_weights)
    boots = bind(region_copy(outfit,f"{key}_Boots",lambda p: p.z<CUFF,[(2,CUFF)]),outfit_weights)
    head_chest = bind(region_copy(outfit,f"{key}_HeadChest",lambda p: abs(p.x)<ELBOW and p.z>=CUFF,
                                   [(0,-ELBOW),(0,ELBOW),(2,CUFF)]),outfit_weights)
    grapple = imported(key+"_grapple",grapple_archive)
    groups[key] = {"gloves":[gloves,hands]+grapple_assets(key,grapple), "boots":[boots], "head_chest":[head_chest]}
    bpy.data.objects.remove(outfit,do_unlink=True)
    bpy.data.objects.remove(grapple,do_unlink=True)
    for slot, objects in groups[key].items():
        export(key,slot,objects)

# Render the actual pieces as icons, with the empty arm area cropped out.
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 20
scene.cycles.use_denoising = True
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 320
scene.world = bpy.data.worlds.new("Gear icon studio")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.8,.8,.8,1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = .62
scene.view_settings.view_transform = "AgX"
camera = bpy.data.objects.new("Gear preview",bpy.data.cameras.new("Gear preview"))
scene.collection.objects.link(camera)
camera.data.type = "ORTHO"
scene.camera = camera
lamp = bpy.data.objects.new("Gear key",bpy.data.lights.new("Gear key","AREA"))
lamp.data.energy = 150
lamp.data.size = 1.7
scene.collection.objects.link(lamp)
lamp.location = (-1.1,-1.4,2.7)
lamp.rotation_euler = (Vector((0,0,.9))-lamp.location).to_track_quat("-Z","Y").to_euler()


def render(name, visible, target, scale, direction, directory):
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.hide_render = obj not in visible
    camera.location = target + Vector(direction).normalized()*3
    camera.rotation_euler = (target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.ortho_scale = scale
    scene.render.filepath = str(directory / (name+".png"))
    bpy.ops.render.render(write_still=True)


for key, slots in groups.items():
    gloves = slots["gloves"]
    render(key+"_gloves_icon",gloves[2:],Vector((.57,-.047,ARM_HEIGHT)),.25,(.19,-1,.29),OUT)
    render(key+"_boots_icon",slots["boots"],Vector((0,-.055,.206)),.55,(.40,-1,.24),OUT)
    render(key+"_head_chest_icon",slots["head_chest"],Vector((0,-.025,1.35)),1.30,(.22,-1,.075),OUT)
    scene.render.resolution_x = scene.render.resolution_y = 850
    render(key+"_fitted_rest",[obj for objs in slots.values() for obj in objs],
           Vector((0,0,.97)),2.18,(.34,-1,.08),REPORT)
    scene.render.resolution_x = scene.render.resolution_y = 320

for obj in bpy.context.scene.objects:
    if obj.type == "MESH":
        obj.hide_render = obj == body
        obj.hide_set(obj == body or obj.name.startswith(("blue_", "Blue_", "Grapple_Needle_Blue")))
for image in bpy.data.images:
    if image.source == "FILE" and not image.packed_file:
        image.pack()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(REPORT/"BaseBlue_Fitted.blend"),compress=True)
(REPORT/"fit_report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print("FITTED_BASE_BLUE",json.dumps(report),flush=True)
