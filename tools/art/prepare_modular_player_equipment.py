"""Fit Chase's six source archives to the existing doll; export reusable pieces.

Run with Blender 5.2 --background --python tools/art/prepare_modular_player_equipment.py.
Inputs and the previous equipped doll are preserved. Generated character artwork
stays local, following the existing public-repository treatment of this doll.
"""
from pathlib import Path
import hashlib
import json
import math
import re
import struct
import zipfile

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'Assets/Threadborne/Equipment/Base Gear'
OUT = ROOT / 'ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/ModularEquipment'
EXPORT = ROOT / 'Assets/Threadborne/Player/LocalDoll/Equipment'
SCRATCH = ROOT / 'tmp/modular-equipment-inputs'
for path in [OUT, EXPORT, SCRATCH]:
    path.mkdir(parents=True, exist_ok=True)

# Reopen the verified game export: its 48 clips are the actual runtime source.
# The old editable file predates fake-user retention of unassigned actions.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(EXPORT.parent/'threadborne_doll_equipped.glb'))
bpy.context.preferences.filepaths.save_version = 0
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
body = bpy.data.objects['Threadborne_Doll']
body.data.name = 'Threadborne_Doll'
rig.animation_data.action = None
for track in rig.animation_data.nla_tracks:
    track.mute = True
rig.data.pose_position = 'REST'
bpy.context.view_layer.update()
# The body and its animation rig are the reusable base; equipment is exported
# separately, so replacing one item does not instantiate another animated body.
for obj in list(bpy.data.objects):
    if obj not in [rig, body]:
        bpy.data.objects.remove(obj, do_unlink=True)
rest = {b.name: (rig.matrix_world @ b.matrix_local).copy() for b in rig.data.bones}
body_points = [body.matrix_world @ v.co for v in body.data.vertices]
body_tree = BVHTree.FromPolygons(body_points, [list(p.vertices) for p in body.data.polygons])
groups = {}
report = {'source_sha256': {}, 'pieces': {}, 'slot_groups': {
    'head_chest': ['base_cowl', 'base_tunic', 'base_pants'],
    'gloves': ['base_bracers'], 'boots': ['base_boots'],
    'weapon': ['base_sword', 'base_shield']}}


def imported(archive):
    path = SOURCE / archive
    report['source_sha256'][archive] = hashlib.sha256(path.read_bytes()).hexdigest()
    dest = SCRATCH / path.stem
    with zipfile.ZipFile(path) as z:
        for member in z.infolist():
            assert (dest / member.filename).resolve().is_relative_to(dest.resolve())
        z.extractall(dest)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(next(dest.rglob('*.fbx'))))
    added = set(bpy.data.objects) - before
    meshes = [o for o in added if o.type == 'MESH']
    assert len(meshes) == 1, (archive, [o.name for o in meshes])
    obj = meshes[0]
    world = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    obj.data.transform(world)
    for other in added - {obj}:
        bpy.data.objects.remove(other, do_unlink=True)
    # Imported paths may be relative to FBX; pack exact original textures.
    for image in bpy.data.images:
        if image.source == 'FILE' and not image.packed_file:
            image.pack()
    return obj


def transform(obj, fn):
    for vertex in obj.data.vertices:
        vertex.co = fn(vertex.co.copy())
    obj.data.update()


def skin(obj, name, weights, group):
    obj.name = name
    obj.vertex_groups.clear()
    for vertex in obj.data.vertices:
        entries = {n: w for n, w in weights(vertex.co).items() if w > 1e-7}
        assert entries and len(entries) <= 4
        total = sum(entries.values())
        for bone, weight in entries.items():
            assert bone in rig.data.bones, bone
            vg = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
            vg.add([vertex.index], weight / total, 'REPLACE')
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    mod = obj.modifiers.new('Shared game skeleton', 'ARMATURE')
    mod.object = rig
    groups.setdefault(group, []).append(obj)
    return obj


def clamp(value):
    return max(0.0, min(1.0, value))


def fit_surface(obj, clearance=.012):
    # Fit against the real rest surface without changing UVs or topology.
    for vertex in obj.data.vertices:
        point, normal, _, distance = body_tree.find_nearest(vertex.co)
        if point is not None and distance < .14 and (vertex.co-point).dot(normal) < clearance:
            vertex.co = point + normal*clearance
    obj.data.update()


def transferred_weights(allowed):
    candidates=[]
    for vertex, point in zip(body.data.vertices, body_points):
        entries={body.vertex_groups[g.group].name:g.weight for g in vertex.groups if body.vertex_groups[g.group].name in allowed}
        if sum(entries.values()) > .8:
            candidates.append((point,entries))
    tree=KDTree(len(candidates))
    for i,(point,_) in enumerate(candidates): tree.insert(point,i)
    tree.balance()

    def weights(p):
        result={}
        for point,i,distance in tree.find_n(p,12):
            influence=1/max(distance,.005)**3
            for bone,weight in candidates[i][1].items():
                result[bone]=result.get(bone,0)+weight*influence
        return dict(sorted(result.items(),key=lambda pair:pair[1],reverse=True)[:4])
    return weights


def torso_weights(p):
    if p.z < 1.02:
        thigh=clamp((1.02-p.z)/.22)*.45
        left=clamp(.5+p.x/.12)
        return {'pelvis':1-thigh,'thigh.L':thigh*left,'thigh.R':thigh*(1-left)}
    if p.z < 1.15:
        spine=clamp((p.z-1.02)/.13)
        return {'pelvis':1-spine,'spine':spine}
    chest=clamp((p.z-1.15)/.15)
    arm=clamp((abs(p.x)-.17)/.16) if p.z>1.34 else 0
    side='L' if p.x>=0 else 'R'
    return {'spine':(1-chest)*(1-arm),'chest':chest*(1-arm),'upper_arm.'+side:arm}


tunic = imported('Base Chest 3d.zip')
transform(tunic, lambda p: Vector((p.x*.86, p.y*.76, .845+p.z*.765+clamp((abs(p.x)-.10)/.17)*.11)))
fit_surface(tunic,.018)
skin(tunic, 'Base_Tunic', torso_weights, 'base_tunic')

cowl = imported('Base Gear Cowl 3d.zip')
transform(cowl, lambda p: Vector((p.x*.51, p.y*.36-.012, 1.405+p.z*.29)))
skin(cowl, 'Base_Cowl', lambda p: {'chest': 1}, 'base_cowl')

pants = imported('Base Gear Pants 3d.zip')
transform(pants, lambda p: Vector((p.x*.51, p.y*.52, .680+p.z*.40)))
fit_surface(pants,.015)


def pants_weights(p):
    pelvis=clamp((p.z-.91)/.14)
    left=clamp(.5+p.x/.12)
    return {'pelvis':pelvis,'thigh.L':(1-pelvis)*left,'thigh.R':(1-pelvis)*(1-left)}

skin(pants, 'Base_Pants', pants_weights, 'base_pants')

boot = imported('Base Boots 3d.zip')
boot_source = [v.co.copy() for v in boot.data.vertices]
for side, sign in [('L', 1), ('R', -1)]:
    obj = boot if side == 'L' else bpy.data.objects.new('Boot_R', boot.data.copy())
    if side == 'R':
        bpy.context.collection.objects.link(obj)
        # Copy source coordinates, not the already fitted left boot.
        for vertex, point in zip(obj.data.vertices, boot_source):
            vertex.co = point
    transform(obj, lambda p: Vector((sign*(.1349-p.y*.72), p.x*.64-.147+clamp((p.z-.3)/.55)*.06, p.z*.625)))
    fit_surface(obj,.012)
    if side == 'R':
        bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()

    skin(obj, 'Base_Boot.'+side, transferred_weights({'shin.'+side,'foot.'+side,'toe.'+side}), 'base_boots')

bracer = imported('Base Gear Gloves 3d.zip')
bracer_source = [v.co.copy() for v in bracer.data.vertices]
points = np.array([tuple(p) for p in bracer_source])
center = points.mean(0)
values, vectors = np.linalg.eigh(np.cov((points-center).T))
axis = Vector(vectors[:, np.argmax(values)])
if axis.x < 0:
    axis = -axis
rotation = axis.rotation_difference(Vector((1, 0, 0)))
aligned = np.array([tuple(rotation @ (p-Vector(center))) for p in bracer_source])
lo, hi = aligned.min(0), aligned.max(0)
for side, sign in [('L', 1), ('R', -1)]:
    obj = bracer if side == 'L' else bpy.data.objects.new('Bracer_R', bracer.data.copy())
    if side == 'R':
        bpy.context.collection.objects.link(obj)
    for vertex, point in zip(obj.data.vertices, aligned):
        vertex.co = Vector((sign*(.466+(point[0]-lo[0])/(hi[0]-lo[0])*.220),
            (point[1]-(lo[1]+hi[1])/2)*.32+.004,
            1.501+(point[2]-(lo[2]+hi[2])/2)*.32))
    fit_surface(obj,.012)
    if side == 'R':
        bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
    skin(obj, 'Base_Bracer.'+side, lambda p, side=side: {'forearm.'+side: 1}, 'base_bracers')

weapons = imported('Sword and Sheild (Base Weapon).zip')
# The two generated props are separated by empty space. No shared triangle is
# cut; fail rather than silently slicing an attached part of either prop.
assert not any(min(weapons.data.vertices[i].co.x for i in f.vertices)<-.19<max(weapons.data.vertices[i].co.x for i in f.vertices) for f in weapons.data.polygons)
weapon_source = weapons.data.copy()
for kind in ['sword', 'shield']:
    obj = weapons if kind == 'sword' else bpy.data.objects.new('Shield', weapon_source.copy())
    if kind == 'shield':
        bpy.context.collection.objects.link(obj)
    bm=bmesh.new();bm.from_mesh(obj.data)
    remove=[v for v in bm.verts if (v.co.x>=-.19 if kind=='sword' else v.co.x<-.19)]
    bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(obj.data);bm.free()
    if kind == 'sword':
        transform(obj, lambda p: Vector((-.790+(p.x+.335)*.90, -.015+(p.z-.80)*.90, 1.491-p.y*.90)))
        skin(obj, 'Threadborne_Sword', lambda p: {'hand.R': 1}, 'base_sword')
    else:
        transform(obj, lambda p: Vector((.610+(p.x-.12)*.85, .025+(p.z-.45)*.85, 1.670-p.y*.60)))
        skin(obj, 'Base_Shield', lambda p: {'forearm.L': 1}, 'base_shield')


def material(name, color, metallic=0):
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1);mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1);shader.inputs['Metallic'].default_value=metallic
    shader.inputs['Roughness'].default_value=.38 if metallic else .8
    return mat


rope=material('Base grapple braided cord',(.19,.085,.03))
metal=material('Base grapple needle',(.40,.42,.44),.7)


def tube(name, points, radius, mat):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=radius;curve.bevel_resolution=2
    spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
    for control,p in zip(spline.points,points):
        control.co=(*p,1)
    obj=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(obj);obj.data.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.object.convert(target='MESH')
    return skin(bpy.context.object,name,lambda p:{'forearm.L':1},'base_bracers')


for strand in range(3):
    points=[]
    for i in range(385):
        t=i/384;angle=t*math.tau*7;braid=angle*3+strand*math.tau/3
        x=.490+t*.16
        section=[math.hypot(v.co.y-.004,v.co.z-1.501) for v in bracer.data.vertices if abs(v.co.x-x)<.012]
        radius=(float(np.percentile(section,90)) if section else .095)+.006+math.cos(braid)*.002
        points.append(Vector((x+math.sin(braid)*.002,.004+math.cos(angle)*radius,1.501+math.sin(angle)*radius)))
    tube('Grapple_Coil_Strand_'+str(strand+1),points,.0028,rope)
# A visible needle stows along the outer, forward side of the shield-arm bracer.
tube('Grapple_Needle_Shaft',[Vector((.49,-.108,1.519)),Vector((.680,-.108,1.519))],.004,metal)
eye=[Vector((.488+math.cos(t*math.tau/32)*.012,-.108,1.519+math.sin(t*math.tau/32)*.008)) for t in range(33)]
tube('Grapple_Needle_Eye',eye,.0025,metal)
bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=.005,radius2=0,depth=.028,location=(.694,-.108,1.519),rotation=(0,math.pi/2,0))
tip=bpy.context.object;tip.data.materials.append(metal)
world=tip.matrix_world.copy();tip.matrix_world=Matrix.Identity(4);tip.data.transform(world)
skin(tip,'Grapple_Needle_Tip',lambda p:{'forearm.L':1},'base_bracers')
tube('Grapple_Needle_Tether',[Vector((.49,-.108,1.519)),Vector((.477,-.115,1.49)),Vector((.49,-.104,1.472))],.003,rope)

# Covered shell faces become reversible presentation masks. Closed boots must
# not draw the doll's bare toes through their leather during ankle flexion.
# Each original face belongs to exactly one region; no body art is discarded.
regions={name:[] for name in ['Threadborne_Doll','Doll_Covered_Gloves','Doll_Covered_Boots','Doll_Covered_HeadChest']}
for polygon in body.data.polygons:
    p=body.matrix_world@polygon.center
    if p.z<.625:
        region='Doll_Covered_Boots'
    elif .467<abs(p.x)<.683 and 1.34<p.z<1.66:
        region='Doll_Covered_Gloves'
    elif abs(p.x)<.20 and .83<p.z<1.40:
        region='Doll_Covered_HeadChest'
    else:
        region='Threadborne_Doll'
    regions[region].append(polygon.index)
template=body.data.copy()
body_objects=[]
for name,indices in regions.items():
    obj=body if name=='Threadborne_Doll' else body.copy()
    if obj!=body: bpy.context.collection.objects.link(obj)
    obj.data=template.copy();obj.name=name;obj.data.name=name
    keep=set(indices)
    bm=bmesh.new();bm.from_mesh(obj.data);bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index not in keep],context='FACES')
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.to_mesh(obj.data);bm.free()
    body_objects.append(obj)
report['body_regions']={name:len(indices) for name,indices in regions.items()}
assert sum(report['body_regions'].values())==len(template.polygons)

# Preserve all 48 source clips only on the body export. Gear contains skins but
# no duplicate animation clocks; every piece follows the one live skeleton.
rig.data.pose_position='POSE'
rig.animation_data.action=bpy.data.actions['idle_4']
rig.animation_data.action_slot=bpy.data.actions['idle_4'].slots[0]
for action in bpy.data.actions:
    action.use_fake_user=True
bpy.context.scene.frame_set(1)
for image in bpy.data.images:
    if image.source=='FILE' and not image.packed_file:
        image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Threadborne_Doll_Modular.blend'),compress=True)


def export(path, objects, animations=False):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [rig]+objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_animations=animations,export_animation_mode='ACTIONS',export_force_sampling=True,
        export_skins=True,export_def_bones=False,export_cameras=False,export_lights=False,
        export_materials='EXPORT',export_yup=True)
    configure_textures(path)


def configure_textures(path):
    # Seed the extracted images and their import policy before Godot's first
    # scan. Lossless disk compression leaves large 3D images uncompressed in
    # VRAM; use the same GPU compression as the existing doll textures.
    raw=path.read_bytes()
    json_length=struct.unpack_from('<I',raw,12)[0]
    document=json.loads(raw[20:20+json_length])
    binary_start=20+json_length+8
    for image in document.get('images',[]):
        view=document['bufferViews'][image['bufferView']]
        suffix='.jpg' if image['mimeType']=='image/jpeg' else '.png'
        image_path=path.parent/(path.stem+'_'+image['name']+suffix)
        assert image_path.resolve().is_relative_to(path.parent.resolve())
        offset=binary_start+view.get('byteOffset',0)
        image_path.write_bytes(raw[offset:offset+view['byteLength']])
        config_path=Path(str(image_path)+'.import')
        if config_path.exists():
            config=config_path.read_text()
            config=re.sub(r'^compress/mode=.*$', 'compress/mode=2', config, flags=re.M)
            config=re.sub(r'^detect_3d/compress_to=.*$', 'detect_3d/compress_to=0', config, flags=re.M)
        else:
            resource_path='res://'+image_path.relative_to(ROOT).as_posix()
            config='[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\nsource_file="'+resource_path+'"\n\n[params]\ncompress/mode=2\nmipmaps/generate=true\ndetect_3d/compress_to=0\n'
        config_path.write_text(config)


export(EXPORT.parent/'threadborne_doll_modular.glb',body_objects,True)
rig.animation_data.action=None
rig.data.pose_position='REST'
bpy.context.view_layer.update()
for name,objects in groups.items():
    export(EXPORT/(name+'.glb'),objects)
    report['pieces'][name]={'meshes':[o.name for o in objects],
        'vertices':sum(len(o.data.vertices) for o in objects),
        'maximum_weight_error':max(abs(sum(g.weight for g in v.groups)-1) for o in objects for v in o.data.vertices),
        'maximum_influences':max(len(v.groups) for o in objects for v in o.data.vertices)}

# Store measured anchors as bone-local coordinates in the same exported frame.
# Export rotates the skeleton root from Blender Z-up to Godot/glTF Y-up; bone
# local axes themselves are retained by the exporter.
anchors={'blade_base':('hand.R',Vector((-.790,-.105,1.491))),
    'blade_tip':('hand.R',Vector((-.790,-.735,1.491))),
    'grapple_origin':('forearm.L',Vector((.708,-.108,1.519)))}
report['anchors']={name:{'bone':bone,'point':list(rest[bone].inverted()@point),'world_blender':list(point)} for name,(bone,point) in anchors.items()}
loadout=ROOT/'Src/Equipment/Visuals/base_gear_loadout.tres'
text=loadout.read_text()
for name,entry in report['anchors'].items():
    text=re.sub(r'^'+name+r' = .*\n','',text,flags=re.M)
    line=name+' = Vector3('+', '.join(f'{v:.9f}' for v in entry['point'])+')\n'
    marker='item_id = &"base_bracers"\n' if name=='grapple_origin' else 'item_id = &"base_sword_shield"\n'
    text=text.replace(marker,marker+line)
loadout.write_text(text)
(OUT/'build_report.json').write_text(json.dumps(report,indent=2))
print('MODULAR_EQUIPMENT_EXPORT_COMPLETE',json.dumps(report),flush=True)
