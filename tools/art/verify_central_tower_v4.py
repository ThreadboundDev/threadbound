"""Read both installed GLBs, verify protected geometry and roof clearance."""
from pathlib import Path
import hashlib
import json
import math
import struct

ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "Assets/BlueBiome/Art/Lakeside3D/Models"
OUT = ROOT / "work/central-tower-polish-2026-10-24"

def glb(path):
    raw = path.read_bytes()
    magic,version,total = struct.unpack_from("<4sII",raw)
    assert magic==b"glTF" and version==2 and total==len(raw)
    length = struct.unpack_from("<I",raw,12)[0]
    return json.loads(raw[20:20+length]),raw[28+length:]

def values(doc,data,index):
    accessor = doc["accessors"][index]
    view = doc["bufferViews"][accessor["bufferView"]]
    components = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4}[accessor["type"]]
    code = {5126:"f",5125:"I",5123:"H",5121:"B"}[accessor["componentType"]]
    format_ = "<"+code*components
    stride = view.get("byteStride",struct.calcsize(format_))
    start = view.get("byteOffset",0)+accessor.get("byteOffset",0)
    return [struct.unpack_from(format_,data,start+i*stride) for i in range(accessor["count"])]

def canonical(mesh,doc,data):
    samples = []
    for primitive in mesh["primitives"]:
        pos = values(doc,data,primitive["attributes"]["POSITION"])
        uv = values(doc,data,primitive["attributes"]["TEXCOORD_0"])
        # Expanded triangles compare the rendered surface independent of GLB
        # vertex deduplication and primitive ordering. Preserve each corner's UV.
        indices = [i[0] for i in values(doc,data,primitive["indices"])]
        corners = [tuple(0.0 if abs(v)<.000005 else round(v,5) for v in pos[i]+uv[i]) for i in indices]
        for i in range(0,len(corners),3):
            samples.append(tuple(sorted(corners[i:i+3])))
    return sorted(samples)

old,old_data = glb(MODELS / "central_tower.glb")
new,new_data = glb(MODELS / "central_tower_v4.glb")
old_meshes = {m["name"]:m for m in old["meshes"]}
new_meshes = {m["name"]:m for m in new["meshes"]}
assert old_meshes.keys()==new_meshes.keys(), "Mesh identities must be preserved"
protected = []
roof_mesh_names = {new["meshes"][n["mesh"]]["name"] for n in new["nodes"]
                   if "mesh" in n and n.get("name","").startswith("Roof")}
for name,mesh in old_meshes.items():
    if name in roof_mesh_names:
        continue
    assert canonical(mesh,old,old_data)==canonical(new_meshes[name],new,new_data), ("Protected rendered geometry/UV differs",name)
    protected.append(name)
for mesh in new["meshes"]:
    for primitive in mesh["primitives"]:
        assert "TANGENT" in primitive["attributes"] and "TEXCOORD_0" in primitive["attributes"]
        assert all(math.isfinite(v) for p in values(new,new_data,primitive["attributes"]["POSITION"]) for v in p)
clearance = json.loads((ROOT / "outputs/central-tower-model-v3/roof_clearance_verification.json").read_text())
nodes = {n.get("name",""):n for n in new["nodes"]}
clearance_checks = []
for c in clearance["checks"]:
    node = nodes[c["fixed_side"]]
    mesh = new["meshes"][node["mesh"]]
    ranges = [new["accessors"][p["attributes"]["POSITION"]] for p in mesh["primitives"]]
    minimum = min(a["min"][0] for a in ranges) if c["side"]=="Right" else min(-a["max"][0] for a in ranges)
    assert minimum>=c["trim_abs_x"]-2e-5
    assert c["hidden_inner_return"] in nodes
    clearance_checks.append({"mesh":c["fixed_side"],"minimum_abs_x":minimum,"required_abs_x":c["trim_abs_x"]})
old_images = {im["uri"] for im in old["images"]}
assert {im["uri"] for im in new["images"]}==old_images
image_hashes = {uri:hashlib.sha256((MODELS / uri).read_bytes()).hexdigest() for uri in old_images}
def bounds(doc):
    accessors = [doc["accessors"][p["attributes"]["POSITION"]] for m in doc["meshes"] for p in m["primitives"]]
    return [[min(a["min"][axis] for a in accessors) for axis in range(3)],
            [max(a["max"][axis] for a in accessors) for axis in range(3)]]
before,after = bounds(old),bounds(new)
assert all(abs(a-b)<1e-5 for ba,aa in zip(before,after) for a,b in zip(ba,aa)), (before,after)
material = next(m for m in new["materials"] if m["name"]=="blue_tiles_tower_v4")
assert abs(material["normalTexture"]["scale"]-.22)<1e-5
report = {"passed":True,"protected_rendered_meshes":protected,"protected_triangle_positions_and_uvs_unchanged":True,
          "all_mesh_identities_preserved":True,"finite_positions_uv_tangents_present":True,"roof_clearance":clearance_checks,
          "source_bounds":before,"new_bounds":after,"texture_sha256":image_hashes,"tile_normal_strength":.22}
(OUT / "export_verification.json").write_text(json.dumps(report,indent=2)+"\n")
print("TOWER_V4_EXPORT_PASS",json.dumps({"protected_meshes":len(protected),"clearance_checks":len(clearance_checks),"same_bounds":True,"same_textures":True}))
