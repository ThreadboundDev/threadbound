"""Split the existing basin's front stone into an always-foreground assembly.

Run in Blender background. Preserve v4 runtime buffers/UVs/textures exactly;
only index membership and a new sibling node change. Also deliver editable v5.
"""
from pathlib import Path
import copy
import hashlib
import json
import struct
import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "outputs/central-tower-model-v5"
WORK = ROOT / "work/lakeside-entry-focus-2026-10-26"
OUT.mkdir(parents=True, exist_ok=True)
WORK.mkdir(parents=True, exist_ok=True)
(OUT / ".gdignore").touch()
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "outputs/central-tower-model-v4/CentralTower_Editable.blend"))
bpy.context.preferences.filepaths.save_version = 0
root = bpy.data.objects["CentralTower_ROOT"]
model = bpy.data.collections["CENTRAL_TOWER_MODEL"]
base = bpy.data.objects["05_Open_Bottom_Basin__slate"]
normalization = json.loads((ROOT / "outputs/central-tower-model-v2/roof_joint_verification.json").read_text())
scales = Vector(normalization["normalization_scale"])
offset = Vector(normalization["raw_offset"])
inverse = root.matrix_world.inverted()

def raw_point(vertex):
    p = inverse @ base.matrix_world @ vertex.co
    return Vector(tuple(p[i] / scales[i] + offset[i] for i in range(3)))

selected = {face.index for face in base.data.polygons
            if all(raw_point(base.data.vertices[i]).y <= -3.35 + 0.0001 for i in face.vertices)}
assert selected and len(selected) < len(base.data.polygons)
front = base.copy()
front.data = base.data.copy()
front.name = "Entry_Foreground_Always"
base.users_collection[0].objects.link(front)
front["render_layer"] = "Always foreground, including during cutaway; stone occludes approaching swimmers."
for ob, keep in [(front, selected), (base, set(range(len(base.data.polygons))) - selected)]:
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[face for face in bm.faces if face.index not in keep], context="FACES")
    bm.to_mesh(ob.data)
    bm.free()
    ob.data.update()
root["entry_revision"] = "v5: original front basin stone split as always-foreground occluder; no added collision."
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CentralTower_Editable.blend"))

# Partition triangles in the already-approved GLB, avoiding re-export changes to
# protected roofs, deck heights, materials, normals or image resources.
source = ROOT / "Assets/BlueBiome/Art/Lakeside3D/Models/central_tower_v4.glb"
blob = source.read_bytes()
length = struct.unpack_from("<I", blob, 12)[0]
doc = json.loads(blob[20:20+length])
binary = bytearray(blob[28+length:])
old_bytes = bytes(binary)

def values(index):
    accessor = doc["accessors"][index]
    view = doc["bufferViews"][accessor["bufferView"]]
    count = {"SCALAR":1,"VEC3":3}[accessor["type"]]
    code = {5126:"f",5125:"I",5123:"H",5121:"B"}[accessor["componentType"]]
    fmt = "<"+code*count
    start = view.get("byteOffset",0)+accessor.get("byteOffset",0)
    stride = view.get("byteStride",struct.calcsize(fmt))
    return [struct.unpack_from(fmt,binary,start+i*stride) for i in range(accessor["count"])]

def indices_accessor(indices):
    while len(binary)%4:
        binary.append(0)
    view = len(doc["bufferViews"])
    doc["bufferViews"].append({"buffer":0,"byteOffset":len(binary),"byteLength":4*len(indices),"target":34963})
    binary.extend(struct.pack("<"+"I"*len(indices),*indices))
    index = len(doc["accessors"])
    doc["accessors"].append({"bufferView":view,"componentType":5125,"count":len(indices),"type":"SCALAR","min":[min(indices)],"max":[max(indices)]})
    return index

mesh_index = next(i for i,m in enumerate(doc["meshes"]) if m["name"] == "05_Open_Bottom_Basin_slate")
basin = doc["meshes"][mesh_index]
foreground = {"name":"Entry_Foreground_Stone", "primitives":[]}
cut = (3.35+offset.y)*scales.y
counts = []
for primitive in basin["primitives"]:
    positions = values(primitive["attributes"]["POSITION"])
    indices = [x[0] for x in values(primitive["indices"])]
    near, far = [], []
    for i in range(0,len(indices),3):
        triangle = indices[i:i+3]
        (near if all(positions[v][2] >= cut-0.0001 for v in triangle) else far).extend(triangle)
    assert near and far and len(near)+len(far)==len(indices)
    new = copy.deepcopy(primitive)
    new["indices"] = indices_accessor(near)
    primitive["indices"] = indices_accessor(far)
    foreground["primitives"].append(new)
    counts.append({"front_triangles":len(near)//3,"rear_triangles":len(far)//3})
new_mesh = len(doc["meshes"])
doc["meshes"].append(foreground)
source_node = next(i for i,n in enumerate(doc["nodes"]) if n.get("mesh") == mesh_index)
new_node = copy.deepcopy(doc["nodes"][source_node])
new_node["name"] = "Entry_Foreground_Always"
new_node["mesh"] = new_mesh
new_index = len(doc["nodes"])
doc["nodes"].append(new_node)
parent = next(n for n in doc["nodes"] if source_node in n.get("children",[]))
parent["children"].append(new_index)
assert binary[:len(old_bytes)] == old_bytes
doc["buffers"][0]["byteLength"] = len(binary)
encoded = json.dumps(doc,separators=(",",":")).encode()
encoded += b" "*((-len(encoded))%4)
binary += b"\0"*((-len(binary))%4)
runtime = ROOT / "Assets/BlueBiome/Art/Lakeside3D/Models/central_tower_v5.glb"
runtime.write_bytes(struct.pack("<4sII",b"glTF",2,28+len(encoded)+len(binary))+struct.pack("<II",len(encoded),0x4E4F534A)+encoded+struct.pack("<II",len(binary),0x004E4942)+binary)
report = {"source":str(source.relative_to(ROOT)),"runtime":str(runtime.relative_to(ROOT)),"runtime_sha256":hashlib.sha256(runtime.read_bytes()).hexdigest(),"front_depth_cut":cut,"triangle_partition":counts,"editable_front_faces":len(selected),"original_runtime_buffer_bytes_preserved":True,"new_geometry_or_collision":False,"texture_uris_unchanged":True}
(WORK / "tower_rim_source.json").write_text(json.dumps(report,indent=2)+"\n")
print("TOWER_ENTRY_SPLIT "+json.dumps(report),flush=True)
