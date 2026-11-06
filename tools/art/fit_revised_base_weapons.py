"""Fit the revised combined weapon download, then fit the forearm shield straps."""

from pathlib import Path
import hashlib
import json
import runpy
import re
import sys
import tempfile
import zipfile

import bpy
import bmesh
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE = Path(sys.argv[sys.argv.index("--")+1])
LOCAL = ROOT / "LocalOnly/Equipment/Shield"
OUTPUT = ROOT / "Assets/Threadborne/Player/LocalDoll/Equipment"
SCRATCH = ROOT / "tmp/revised_base_weapons"
SCRATCH.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(SCRATCH)
LOCAL.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(ARCHIVE) as package:
    for item in package.infolist():
        assert (SCRATCH/item.filename).resolve().is_relative_to(SCRATCH.resolve())
    package.extractall(SCRATCH)

bpy.ops.wm.open_mainfile(filepath=str(ROOT / "LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend"))
rig = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
before = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=str(next(SCRATCH.glob("*.fbx"))))
source = next(obj for obj in set(bpy.data.objects)-before if obj.type == "MESH")
source.data.transform(source.matrix_world)
source.parent = None
source.matrix_world = Matrix.Identity(4)
assert not any(min(source.data.vertices[i].co.x for i in face.vertices)<-.19<
               max(source.data.vertices[i].co.x for i in face.vertices) for face in source.data.polygons)
pieces = []
for kind in ("sword","shield"):
    obj = bpy.data.objects.new("Threadborne_Sword" if kind == "sword" else "Shield_Revised_Front", source.data.copy())
    bpy.context.scene.collection.objects.link(obj)
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    remove = [v for v in mesh.verts if (v.co.x>=-.19 if kind == "sword" else v.co.x<-.19)]
    bmesh.ops.delete(mesh, geom=remove, context="VERTS")
    if kind == "shield":
        bmesh.ops.bisect_plane(mesh, geom=list(mesh.verts)+list(mesh.edges)+list(mesh.faces),
                              plane_co=(0,.041,0), plane_no=(0,1,0), clear_outer=True)
    mesh.to_mesh(obj.data)
    mesh.free()
    for vertex in obj.data.vertices:
        x,y,z = vertex.co
        if kind == "sword":
            vertex.co = (-.790+(x+.326)*.90, -.015+(z-.827)*.90, 1.491-y*.90)
        else:
            vertex.co = (.606-(z-.466)*.82, .024+(x-.133)*.82, 1.598-(y-.041)*.70)
    obj.data.update()
    pieces.append(obj)
    if kind == "sword":
        tip_y = min(v.co.y for v in obj.data.vertices)
        tip_points = [v.co for v in obj.data.vertices if v.co.y < tip_y+.006]
        tip = sum(tip_points,Vector())/len(tip_points)
        rest = rig.matrix_world @ rig.data.bones["hand.R"].matrix_local
        anchors = {"blade_base": rest.inverted() @ Vector((-.790,-.170,1.491)),
                   "blade_tip": rest.inverted() @ tip}
        loadout = ROOT / "Src/Equipment/Visuals/base_gear_loadout.tres"
        text = loadout.read_text(encoding="utf-8")
        for name, point in anchors.items():
            text = re.sub(r"^"+name+r" = .*", name+" = Vector3("+", ".join(f"{v:.9f}" for v in point)+")",
                          text, flags=re.M)
        loadout.write_text(text,encoding="utf-8")
        for image in bpy.data.images:
            if image.source == "FILE" and max(image.size)>2048:
                ratio = 2048/max(image.size)
                image.scale(round(image.size[0]*ratio),round(image.size[1]*ratio))
        obj.vertex_groups.new(name="hand.R").add(list(range(len(obj.data.vertices))), 1, "REPLACE")
        obj.parent = rig
        obj.matrix_parent_inverse = rig.matrix_world.inverted()
        obj.modifiers.new("Sword follows right hand", "ARMATURE").object = rig
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        rig.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(OUTPUT / "base_sword.glb"), export_format="GLB",
                                 use_selection=True, export_animations=False, export_skins=True)

bpy.data.objects.remove(source, do_unlink=True)
for image in bpy.data.images:
    if image.source == "FILE" and not image.packed_file:
        image.pack()
front_file = LOCAL / "Revised_Weapon_Front.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(front_file), compress=True)
(LOCAL / "revised_weapon_source.json").write_text(json.dumps({
    "source": ARCHIVE.name, "sha256": hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(),
    "grip_source_height": .827, "shield_rear_cut": .041,
},indent=2),encoding="utf-8")
sys.argv = [__file__, "--front", str(front_file)]
runpy.run_path(str(ROOT / "tools/art/fit_threadborne_shield_straps.py"), run_name="__main__")
