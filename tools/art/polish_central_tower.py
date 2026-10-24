"""Polish v3 roof fascia/UVs in place in a NEW v4 source, protect all other art.

Run with Blender --background --python tools/art/polish_central_tower.py.
Existing texture pixels and all physical gameplay/layout resources are retained.
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
OUT = ROOT / "outputs/central-tower-model-v4"
WORK = ROOT / "work/central-tower-polish-2026-10-24"
TEMP = ROOT / "tmp/tower_polish/blender-temp"
for directory in (OUT, WORK, TEMP):
    directory.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(TEMP)
os.environ["TEMP"] = os.environ["TMP"] = str(TEMP)
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "outputs/central-tower-model-v3/CentralTower_Editable.blend"))
bpy.context.preferences.filepaths.save_version = 0
root = bpy.data.objects["CentralTower_ROOT"]
model = bpy.data.collections["CENTRAL_TOWER_MODEL"]
roof_collection = bpy.data.collections["04_Fixed_Blue_Roofs"]
facade = bpy.data.collections["02_Facade_Removable"]
normalization = json.loads((ROOT / "outputs/central-tower-model-v2/roof_joint_verification.json").read_text())
scales = Vector(normalization["normalization_scale"])
offset = Vector(normalization["raw_offset"])
inverse = root.matrix_world.inverted()

def raw_point(ob, vertex):
    p = inverse @ ob.matrix_world @ vertex.co
    return Vector(tuple(p[i] / scales[i] + offset[i] for i in range(3)))

def digest(ob):
    mesh = ob.data
    payload = [list(ob.matrix_world), [tuple(v.co) for v in mesh.vertices],
               [(tuple(p.vertices), p.material_index, p.use_smooth) for p in mesh.polygons],
               [tuple(uv.uv) for uv in mesh.uv_layers.active.data] if mesh.uv_layers else []]
    return hashlib.sha256(repr(payload).encode()).hexdigest()

model_objects = [o for o in model.all_objects if o is not None]
meshes = [o for o in model_objects if o.type == "MESH"]
roofs = [o for o in meshes if o in list(roof_collection.objects) or o.name.startswith("Roof_Tier")]
protected = {o.name: digest(o) for o in meshes if o not in roofs}
before_vertices = {o.name: len(o.data.vertices) for o in meshes}
before_faces = {o.name: len(o.data.polygons) for o in meshes}
specs = [(6.35, 3.45, 1.03), (16.65, 2.95, 1.30), (20.55, 2.95, 1.24), (25.45, 2.15, 1.25)]
roof_material = bpy.data.materials["blue_tiles"].copy()
roof_material.name = "blue_tiles_tower_v4"
for node in roof_material.node_tree.nodes:
    if node.type == "NORMAL_MAP":
        node.inputs["Strength"].default_value = .22
roof_material.diffuse_color = (.13, .28, .43, 1)
changes = []

for ob in roofs:
    mesh = ob.data
    points = [raw_point(ob,v) for v in mesh.vertices]
    blue_slots = {i for i,m in enumerate(mesh.materials) if m and m.name == "blue_tiles"}
    wood_slots = {i for i,m in enumerate(mesh.materials) if m and m.name == "walnut"}
    wood_vertices = {v for p in mesh.polygons if p.material_index in wood_slots for v in p.vertices}
    for index in blue_slots:
        mesh.materials[index] = roof_material
    smoothed = 0
    groups = []
    tier = int(ob.name.split("Tier")[1][:2]) if "Tier" in ob.name else None
    if tier:
        _, cx, rx = specs[tier-1]
        a = cx-.25
        # Each fascia cross-section is four vertices: two vertical pairs,
        # joined by a 0.12-unit width edge. Recover its actual center before
        # subtracting ripple, so the rail follows the clean eave curve exactly.
        adjacency = {v:set() for v in wood_vertices}
        for edge in mesh.edges:
            i,j = edge.vertices
            if i not in wood_vertices or j not in wood_vertices:
                continue
            d = points[i]-points[j]
            if (abs(d.x)<1e-5 and abs(d.y)<1e-5 and abs(abs(d.z)-.2)<1e-5) or (abs(d.z)<1e-5 and abs(d.xy.length-.12)<1e-5):
                adjacency[i].add(j)
                adjacency[j].add(i)
        visited = set()
        for start in wood_vertices:
            if start in visited:
                continue
            group, todo = set(), [start]
            while todo:
                v = todo.pop()
                if v in group:
                    continue
                group.add(v)
                todo.extend(adjacency[v]-group)
            visited.update(group)
            assert len(group)==4, (ob.name, "fascia ring", len(group))
            center = sum((points[v] for v in group),Vector())/4
            dx = max(0,(abs(center.x)-a)/rx)
            dy = max(0,(-center.y-2.18)/1.07,(center.y-2.25)/1.07)
            blend = max(0,min(1,(dx-dy)/.16+.5))
            ripple = .024*((1-blend)*math.cos(center.x/.23*math.tau)+blend*math.cos(center.y/.23*math.tau))
            local_delta = ob.matrix_world.inverted().to_3x3() @ root.matrix_world.to_3x3() @ Vector((0,0,-ripple*scales.z))
            for v in group:
                mesh.vertices[v].co += local_delta
            groups.append({"center":list(center),"removed_ripple":ripple})
            smoothed += len(group)
    uv_layer = mesh.uv_layers.active
    remapped = 0
    for face in mesh.polygons:
        if face.material_index not in blue_slots:
            continue
        # Keep a single projection per face across the hip. The v3 per-vertex
        # projection could switch axis halfway across one quad and twist UVs.
        center = sum((points[v] for v in face.vertices),Vector())/len(face.vertices)
        if tier:
            _,cx,rx = specs[tier-1]
            a = cx-.25
            side = max(0,(abs(center.x)-a)/rx)>max(0,(-center.y-2.18)/1.07,(center.y-2.25)/1.07)
        else:
            side = False
        for loop in face.loop_indices:
            p = points[mesh.loops[loop].vertex_index]
            if tier:
                dx = max(0,(abs(p.x)-a)/rx)
                dy = max(0,(-p.y-2.18)/1.07,(p.y-2.25)/1.07)
                along = p.y if side else p.x
                down = max(dx,dy)
            else:
                along = p.x
                down = abs(p.y)/2.62
            uv_layer.data[loop].uv = (along/1.15+.075,down*.75)
            remapped += 1
    mesh.update()
    changes.append({"mesh":ob.name,"fascia_vertices_smoothed":smoothed,"fascia_rings":len(groups),"uv_loops_remapped":remapped})

for name, value in protected.items():
    assert digest(bpy.data.objects[name])==value, ("Protected non-roof mesh changed",name)
for ob in meshes:
    assert len(ob.data.vertices)==before_vertices[ob.name] and len(ob.data.polygons)==before_faces[ob.name]
root["roof_revision"] = "v4: smooth timber fascia, coherent tile direction and hip UVs, restrained tile normals"
for collection in (model,roof_collection,facade):
    collection.hide_viewport = False
    collection.hide_render = False
for ob in model_objects:
    ob.hide_set(False)
    ob.hide_viewport = False
    ob.hide_render = False
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CentralTower_Editable.blend"))

# Export using the exact already-installed runtime images and existing paths.
for mat in bpy.data.materials:
    if not mat.use_nodes:
        continue
    key = "blue_tiles" if mat.name.startswith("blue_tiles") else mat.name.split(".")[0]
    if key not in ("blue_tiles","walnut","plaster","slate"):
        continue
    for node in mat.node_tree.nodes:
        if node.type != "TEX_IMAGE" or node.image is None:
            continue
        name = node.image.name
        filename = key+"_BaseColor_4K.png" if "BaseColor" in name else key+"_NormalGL_4K.png" if "NormalGL" in name else key+"_Roughness_4K.png" if "Roughness" in name else ""
        if not filename:
            continue
        node.image = bpy.data.images.load(str(ROOT / "Assets/BlueBiome/Art/Lakeside3D/Textures" / filename),check_existing=True)
        if "BaseColor" not in filename:
            node.image.colorspace_settings.name = "Non-Color"
bpy.ops.object.select_all(action="DESELECT")
for ob in model_objects:
    ob.select_set(True)
export_path = TEMP / "tower.glb"
bpy.ops.export_scene.gltf(filepath=str(export_path),export_format="GLB",use_selection=True,export_yup=True,export_texcoords=True,export_normals=True,export_tangents=True,export_materials="EXPORT",export_image_format="AUTO",export_extras=True,export_cameras=False,export_lights=False)

# Externalize images without touching their bytes; keep the game-side artifact
# small and preserve the shared texture resources used by existing buildings.
blob = export_path.read_bytes()
json_length = struct.unpack_from("<I",blob,12)[0]
doc = json.loads(blob[20:20+json_length])
binary = blob[28+json_length:]
image_views = set()
for im in doc["images"]:
    view_index = im.pop("bufferView")
    image_views.add(view_index)
    view = doc["bufferViews"][view_index]
    filename = im["name"]+(".jpg" if im["mimeType"]=="image/jpeg" else ".png")
    installed = ROOT / "Assets/BlueBiome/Art/Lakeside3D/Textures" / filename
    # Roughness channel packing can re-encode embedded PNGs. Reference the
    # existing installed maps directly instead of writing/replacing any image.
    assert installed.is_file(), ("Missing installed texture",filename)
    im["uri"] = "../Textures/"+filename
new_binary = bytearray()
new_views, remap = [], {}
for index,view in enumerate(doc["bufferViews"]):
    if index in image_views:
        continue
    while len(new_binary)%4:
        new_binary.append(0)
    remap[index] = len(new_views)
    v = dict(view)
    v["byteOffset"] = len(new_binary)
    new_binary.extend(binary[view.get("byteOffset",0):view.get("byteOffset",0)+view["byteLength"]])
    new_views.append(v)
def references(value):
    if isinstance(value,dict):
        for key,item in value.items():
            if key=="bufferView":
                value[key] = remap[item]
            else:
                references(item)
    elif isinstance(value,list):
        for item in value:
            references(item)
references(doc)
doc["bufferViews"] = new_views
doc["buffers"] = [{"byteLength":len(new_binary)}]
encoded = json.dumps(doc,separators=(",",":")).encode()
encoded += b" "*((-len(encoded))%4)
new_binary += b"\0"*((-len(new_binary))%4)
runtime = ROOT / "Assets/BlueBiome/Art/Lakeside3D/Models/central_tower_v4.glb"
runtime.write_bytes(struct.pack("<4sII",b"glTF",2,28+len(encoded)+len(new_binary))+struct.pack("<II",len(encoded),0x4E4F534A)+encoded+struct.pack("<II",len(new_binary),0x004E4942)+new_binary)
report = {"source":"outputs/central-tower-model-v3/CentralTower_Editable.blend","roof_changes":changes,"protected_non_roof_hashes":protected,"non_roof_geometry_uvs_unchanged":True,"vertex_and_face_counts_unchanged":True,"texture_bytes_unchanged":True,"runtime":str(runtime.relative_to(ROOT)),"runtime_sha256":hashlib.sha256(runtime.read_bytes()).hexdigest()}
(WORK / "source_verification.json").write_text(json.dumps(report,indent=2)+"\n")
print("TOWER_V4_BUILD_PASS",json.dumps({"roof_parts":len(changes),"protected_meshes":len(protected),"runtime_bytes":runtime.stat().st_size}),flush=True)
