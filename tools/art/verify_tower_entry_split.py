"""Verify v5 is an exact triangle partition of v4, with no art/scale drift."""
from pathlib import Path
from collections import Counter
import json
import struct

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "Assets/BlueBiome/Art/Lakeside3D/Models"

def glb(path):
    blob = path.read_bytes()
    length = struct.unpack_from("<I",blob,12)[0]
    return json.loads(blob[20:20+length]),blob[28+length:]

def indices(doc,binary,index):
    accessor = doc["accessors"][index]
    view = doc["bufferViews"][accessor["bufferView"]]
    code = {5121:"B",5123:"H",5125:"I"}[accessor["componentType"]]
    start = view.get("byteOffset",0)+accessor.get("byteOffset",0)
    return struct.unpack_from("<"+code*accessor["count"],binary,start)

def triangles(values):
    return Counter(tuple(values[i:i+3]) for i in range(0,len(values),3))

old,old_binary = glb(FOLDER/"central_tower_v4.glb")
new,new_binary = glb(FOLDER/"central_tower_v5.glb")
assert new_binary[:len(old_binary)] == old_binary, "Original runtime data must be byte-exact"
for section in ["images","textures","samplers","materials"]:
    assert old[section] == new[section], section+" changed"
old_meshes = {m["name"]:m for m in old["meshes"]}
new_meshes = {m["name"]:m for m in new["meshes"]}
basin = "05_Open_Bottom_Basin_slate"
protected = []
for name, mesh in old_meshes.items():
    if name != basin:
        assert mesh == new_meshes[name], name+" changed"
        protected.append(name)
front = new_meshes["Entry_Foreground_Stone"]
counts = []
for original,rear,near in zip(old_meshes[basin]["primitives"],new_meshes[basin]["primitives"],front["primitives"],strict=True):
    assert {k:v for k,v in original.items() if k!="indices"} == {k:v for k,v in rear.items() if k!="indices"} == {k:v for k,v in near.items() if k!="indices"}
    complete = triangles(indices(old,old_binary,original["indices"]))
    far = triangles(indices(new,new_binary,rear["indices"]))
    close = triangles(indices(new,new_binary,near["indices"]))
    assert complete == far+close, "Split must retain every original triangle once"
    assert not far.keys() & close.keys(), "Split triangles must not overlap"
    counts.append({"original":sum(complete.values()),"rear":sum(far.values()),"front":sum(close.values())})
original_node = next(i for i,n in enumerate(old["nodes"]) if n.get("name")=="05_Open_Bottom_Basin__slate")
front_node = next(i for i,n in enumerate(new["nodes"]) if n.get("name")=="Entry_Foreground_Always")
assert any(original_node in n.get("children",[]) and front_node in n.get("children",[]) for n in new["nodes"])
report = {"passed":True,"protected_meshes":protected,"protected_mesh_count":len(protected),"original_data_bytes_preserved":len(old_binary),"triangle_partition":counts,"textures_materials_unchanged":True}
(ROOT/"work/lakeside-entry-focus-2026-10-26/tower_rim_geometry.json").write_text(json.dumps(report,indent=2)+"\n")
print("TOWER_RIM_GEOMETRY "+json.dumps(report))
