"""Blender: downloaded adult CC0 sentinels, static village and local Fab boss.

Run prepare_polished_assets.py first. --golem / --sentinels / --village select a pass.
Private Fab derivatives are deliberately excluded from the public repository.
"""
import bpy
import json
import math
from pathlib import Path
import sys
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/third-person-study-2026-10-28'
TEMP = WORK / 'temp/polish'
OUT = WORK / 'project/assets'
REPORT = []


def load(path):
    before = set(bpy.data.objects)
    if path.suffix == '.fbx':
        bpy.ops.import_scene.fbx(filepath=str(path))
    else:
        bpy.ops.import_scene.gltf(filepath=str(path))
    return list(set(bpy.data.objects) - before)


def small_images():
    for i, image in enumerate(bpy.data.images):
        if image.source != 'FILE':
            continue
        try:
            _ = image.pixels[0]
        except (IndexError, RuntimeError):
            continue
        if max(image.size) > 1024:
            ratio = 1024 / max(image.size)
            image.scale(round(image.size[0]*ratio), round(image.size[1]*ratio))
        image.filepath_raw = str(TEMP / f'map_{i}.png')
        image.file_format = 'PNG'
        image.save()
        if image.packed_file:
            image.unpack(method='REMOVE')
        image.pack()


def export(path, clips=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    small_images()
    bpy.context.scene.frame_set(1)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB',
                             export_animations=clips, export_animation_mode='NLA_TRACKS',
                             export_force_sampling=True, export_apply=False)
    REPORT.append(dict(file=path.relative_to(OUT).as_posix(), bytes=path.stat().st_size,
                       rigs=[dict(name=o.name, bones=len(o.data.bones)) for o in bpy.context.scene.objects if o.type=='ARMATURE']))
    print('EXPORTED', path, flush=True)


def nla(rig, action, name):
    rig.animation_data.action = None
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, action)


def golem():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objects = load(TEMP / 'golem/Mesh/StoneGolem.fbx')
    rig = next(o for o in objects if o.type == 'ARMATURE')
    rig.name = 'Downloaded_Golem_Rig'
    # Normalize FBX centimetre bones and compensating mesh transforms before baking.
    # Godot's static mesh AABBs otherwise disagree with the evaluated skin by 100x.
    for ob in objects:
        if ob.type == 'MESH':
            matrix = ob.matrix_world.copy()
            ob.parent = None
            ob.matrix_world = matrix
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for ob in objects:
        if ob.type != 'MESH': continue
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        ob.parent = rig
        ob.matrix_parent_inverse = Matrix.Identity(4)
    scene = bpy.context.scene
    scene.render.fps = 30
    for category in ['Body', 'Armor', 'Weapon']:
        mat = bpy.data.materials.new('Golem / '+category)
        mat.use_nodes = True
        shader = mat.node_tree.nodes.get('Principled BSDF')
        for suffix, socket in [('Albedo_Skin1', 'Base Color'), ('Roughness', 'Roughness'), ('Metallic', 'Metallic')]:
            image = bpy.data.images.load(str(TEMP / f'golem/Textures/T_StoneGolem_{category}_{suffix}.tga'), check_existing=True)
            if suffix != 'Albedo_Skin1': image.colorspace_settings.name = 'Non-Color'
            node = mat.node_tree.nodes.new('ShaderNodeTexImage')
            node.image = image
            mat.node_tree.links.new(node.outputs['Color'], shader.inputs[socket])
        for ob in objects:
            if ob.type == 'MESH':
                for i, old in enumerate(ob.data.materials):
                    if category.lower() in old.name.lower(): ob.data.materials[i] = mat
    clips = ['idle1', 'walkF', 'jogF', 'attack1', 'attack2', 'attack3', 'attack4', 'attack5', 'gethit1', 'death1']
    for name in clips:
        imported = load(TEMP / f'golem/Animations/StoneGolem@{name}.fbx')
        other = next(o for o in imported if o.type == 'ARMATURE')
        start, end = map(int, other.animation_data.action.frame_range)
        action = bpy.data.actions.new(name)
        rig.animation_data_create()
        # Mute completed strips while baking the next clip.
        for track in rig.animation_data.nla_tracks: track.mute = True
        rig.animation_data.action = action
        for frame in range(start, end+1):
            scene.frame_set(frame)
            bpy.context.view_layer.update()
            transform = rig.matrix_world.inverted() @ other.matrix_world
            poses = {}
            for pb in other.pose.bones:
                value = transform @ pb.matrix
                poses[pb.name] = Matrix.LocRotScale(value.translation, value.to_quaternion(), Vector((1,1,1)))
            for pb in rig.pose.bones:
                kwargs = dict(parent_matrix=poses[pb.parent.name], parent_matrix_local=pb.parent.bone.matrix_local) if pb.parent else {}
                pb.matrix_basis = pb.bone.convert_local_to_pose(poses[pb.name], pb.bone.matrix_local, invert=True, **kwargs)
                pb.rotation_mode = 'QUATERNION'
                for prop in ['location', 'rotation_quaternion', 'scale']: pb.keyframe_insert(prop, frame=frame, group=pb.name)
        for ob in imported: bpy.data.objects.remove(ob, do_unlink=True)
        nla(rig, action, name)
        print('BAKED GOLEM', name, end-start+1, flush=True)
    for track in rig.animation_data.nla_tracks: track.mute = False
    export(OUT / 'local_licensed/armored_golem.glb')


def sentinel(gender, weapon, destination):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source = next((TEMP / 'outfits').rglob(f'{gender}_Ranger.gltf'))
    objects = load(source)
    rig = next(o for o in objects if o.type == 'ARMATURE')
    rig.name = 'Woven_Sentinel_Rig'
    rig.animation_data_clear()
    rig.animation_data_create()
    # A full-size head retained from the already assembled CC0 worker.
    blend = ROOT / 'work/cc0-house-villager-2026-10-28/CC0_House_WorkingVillager_Comparison.blend'
    with bpy.data.libraries.load(str(blend), link=False) as (available, chosen):
        chosen.objects = [n for n in available.objects if n.startswith('CC0 base / head and neck')]
    for ob in chosen.objects:
        bpy.context.scene.collection.objects.link(ob)
        ob.parent = rig
        ob.matrix_parent_inverse = Matrix.Identity(4)
        ob.matrix_basis = Matrix.Identity(4)
        for mod in ob.modifiers:
            if mod.type == 'ARMATURE': mod.object = rig
        for mat in ob.data.materials:
            if mat and mat.use_nodes:
                shader = mat.node_tree.nodes.get('Principled BSDF')
                for link in list(shader.inputs['Base Color'].links): mat.node_tree.links.remove(link)
                shader.inputs['Base Color'].default_value = (.09, .16, .18, 1)
                shader.inputs['Roughness'].default_value = 1
    # A downloaded weapon, rigidly skinned to the real animated hand.
    source_weapon = next((TEMP / 'weapons').rglob(weapon+'.gltf'))
    imported = load(source_weapon)
    meshes = [o for o in imported if o.type == 'MESH']
    hand = rig.data.bones['hand_r']
    for ob in meshes:
        verts = [ob.matrix_world @ v.co for v in ob.data.vertices]
        low, high = min(v.z for v in verts), max(v.z for v in verts)
        scale = (1.2 if weapon.startswith('sword') else 1.65)/(high-low)
        grip = low + (high-low)*(0.15 if weapon.startswith('sword') else .40)
        for vertex, co in zip(ob.data.vertices, verts):
            vertex.co = Vector((co.x*scale, co.y*scale, (co.z-grip)*scale)) + hand.head_local
        ob.parent = rig
        ob.matrix_parent_inverse = Matrix.Identity(4)
        ob.matrix_basis = Matrix.Identity(4)
        group = ob.vertex_groups.new(name='hand_r')
        group.add(list(range(len(ob.data.vertices))), 1, 'REPLACE')
        mod = ob.modifiers.new('Animated hand attachment', 'ARMATURE')
        mod.object = rig
        ob.name = 'Downloaded_'+weapon
    for ob in imported:
        if ob.type != 'MESH': bpy.data.objects.remove(ob, do_unlink=True)
    scene = bpy.context.scene
    scene.render.fps = 30
    choices = [('ual1', ['Idle_Loop', 'Sword_Idle', 'Walk_Loop', 'Jog_Fwd_Loop', 'Hit_Chest', 'Death01']),
               ('ual2', ['Sword_Regular_A', 'Sword_Regular_B', 'Sword_Regular_C', 'Sword_Heavy_Combo', 'Sword_Dash', 'Sword_Block'])]
    for folder, names in choices:
        imported = load(next((TEMP / folder).rglob('*.glb')))
        donor = next(o for o in imported if o.type == 'ARMATURE')
        axes = {b.name: b.matrix_local.to_quaternion().inverted() @ donor.data.bones[b.name].matrix_local.to_quaternion() for b in rig.data.bones}
        for name in names:
            source_action = next(a for a in bpy.data.actions if a.name == name or a.name.startswith(name+'.'))
            donor.animation_data.action = source_action
            if source_action.slots: donor.animation_data.action_slot = source_action.slots[0]
            for track in donor.animation_data.nla_tracks: track.mute = True
            start, end = map(int, source_action.frame_range)
            for track in rig.animation_data.nla_tracks: track.mute = True
            action = bpy.data.actions.new('Sentinel_'+name)
            rig.animation_data_create()
            rig.animation_data.action = action
            for frame in range(start, end+1):
                scene.frame_set(frame)
                bpy.context.view_layer.update()
                poses = {p.name: p.matrix_basis.copy() for p in donor.pose.bones}
                for pb in rig.pose.bones:
                    axis = axes[pb.name]
                    pb.matrix_basis = (axis @ poses[pb.name].to_quaternion() @ axis.inverted()).to_matrix().to_4x4()
                    if pb.name == 'pelvis': pb.location = axis @ poses[pb.name].translation
                    pb.rotation_mode = 'QUATERNION'
                    for prop in ['location', 'rotation_quaternion']: pb.keyframe_insert(prop, frame=frame-start+1, group=pb.name)
            nla(rig, action, name)
        for ob in imported: bpy.data.objects.remove(ob, do_unlink=True)
    for track in rig.animation_data.nla_tracks: track.mute = False
    export(OUT / 'enemies' / destination)


def village():
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'work/cc0-house-villager-2026-10-28/CC0_House_WorkingVillager_Comparison.blend'))
    scene = bpy.context.scene
    for ob in list(scene.objects):
        if ob.type != 'MESH' or any(m.type == 'ARMATURE' for m in ob.modifiers) or ob.name.startswith(('Preview', 'Work ', 'Authored / apron', 'Authored / canvas', 'Authored / patch')):
            bpy.data.objects.remove(ob, do_unlink=True)
    for ob in scene.objects: ob.animation_data_clear()
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = next(o for o in scene.objects if o.type == 'MESH')
    bpy.ops.object.join()
    bpy.context.object.name = 'Downloaded_Modular_Cottage'
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    export(OUT / 'village/cottage.glb', False)


def props():
    for stem in ['Barrel', 'Barrel_Apples', 'Bench', 'Bucket_Wooden_1', 'Crate_Wooden',
                 'Lantern_Wall', 'Stall_Cart_Empty', 'Stall_Empty', 'WeaponStand',
                 'Dummy', 'Rope_1', 'Banner_1', 'Anvil_Log', 'Stool', 'Chest_Wood', 'Pot_1']:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        load(next((TEMP / 'props').rglob(stem+'.gltf')))
        export(OUT / 'village' / (stem.lower()+'.glb'), False)


def stylized():
    selections = {'AP2_Rock10_LOD0':'rock_a', 'AP2_Rock3_LOD0':'rock_b', 'AP2_Rock8_LOD0':'rock_c',
                  'AP4_A1_StoneWall1':'ruin_wall', 'AP4_A2_Stone2':'ruin_block',
                  'AP4_A3_Door1':'ruin_arch', 'AP4_A3_StoneRing1':'ruin_ring',
                  'F1_Tree1':'tree_a', 'F1_Tree3':'tree_b', 'F1_BushMid':'bush',
                  'F1_MidGrass':'grass', 'F1_Flower2Patch':'flowers'}
    sources = list((TEMP / 'stylized').rglob('*.png'))
    for stem, name in selections.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        load(next((TEMP / 'stylized').rglob(stem+'.fbx')))
        # These source FBXs contain UVs but no assigned material slots.
        for ob in bpy.context.scene.objects:
            if ob.type == 'MESH' and not ob.data.materials:
                label = 'Bark' if stem.startswith('F1_Tree') and ob.name.startswith('F1_Tree') else 'Source'
                ob.data.materials.append(bpy.data.materials.new(label+' / '+ob.name))
        for mat in bpy.data.materials:
            mat.use_nodes = True
            shader = mat.node_tree.nodes.get('Principled BSDF')
            shader.inputs['Roughness'].default_value = .92
            shader.inputs['Metallic'].default_value = 0
            if stem.startswith('AP2'):
                base = next(p for p in sources if p.name == 'AP2_Rocks_BaseColor_V2.png')
            elif stem.startswith('AP4'):
                atlas = '1' if '_A1_' in stem else ('2' if '_A2_' in stem else '3')
                base = next(p for p in sources if p.name == f'AP4_Atlas_{atlas}_BaseColor.png')
            else:
                lower = mat.name.lower()
                if 'bark' in lower or 'trunk' in lower:
                    base = next(p for p in sources if p.name == 'bark1_baseColor.png')
                else:
                    base = next(p for p in sources if p.name == ('F1_Leaves_Map1.png' if stem.startswith('F1_Tree') else 'F1_Foliage_Map1.png'))
                    mat.name = 'Leaf cutout / '+mat.name
                    mat.surface_render_method = 'DITHERED'
                    mat.use_backface_culling = False
            for link in list(shader.inputs['Base Color'].links): mat.node_tree.links.remove(link)
            node = mat.node_tree.nodes.new('ShaderNodeTexImage')
            node.image = bpy.data.images.load(str(base),check_existing=True)
            mat.node_tree.links.new(node.outputs['Color'], shader.inputs['Base Color'])
            if mat.name.startswith('Leaf cutout'):
                if stem.startswith('F1_Tree'):
                    # The supplied leaf map is a monochrome opacity mask, not albedo.
                    for link in list(shader.inputs['Base Color'].links): mat.node_tree.links.remove(link)
                    shader.inputs['Base Color'].default_value = (.12,.24,.085,1)
                    mat.node_tree.links.new(node.outputs['Color'],shader.inputs['Alpha'])
                else:
                    mat.node_tree.links.new(node.outputs['Alpha'], shader.inputs['Alpha'])
            print('MATERIAL',stem,mat.name,base.name,flush=True)
        path = OUT / 'local_licensed' / (name+'.glb')
        export(path,False)
        # Use alpha cutout for foliage, avoiding blended leaf sorting artifacts.
        import struct
        data=path.read_bytes();length=struct.unpack_from('<I',data,12)[0]
        doc=json.loads(data[20:20+length]);tail=data[20+length:]
        for mat in doc.get('materials',[]):
            if mat.get('name','').startswith('Leaf cutout'):
                mat.update(alphaMode='MASK',alphaCutoff=.4,doubleSided=True)
        encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
        path.write_bytes(struct.pack('<III',0x46546C67,2,20+len(encoded)+len(tail))+struct.pack('<II',len(encoded),0x4E4F534A)+encoded+tail)


if '--golem' in sys.argv: golem()
elif '--sentinels' in sys.argv:
    sentinel('Male', 'sword_C', 'woven_swordsman.glb')
    sentinel('Female', 'spear_A', 'woven_pikewarden.glb')
elif '--village' in sys.argv: village()
elif '--props' in sys.argv: props()
elif '--stylized' in sys.argv: stylized()
else: raise SystemExit('Choose --golem, --sentinels or --village')
(TEMP / ('export_'+sys.argv[-1].lstrip('-')+'.json')).write_text(json.dumps(REPORT, indent=2)+'\n', encoding='utf-8')
