"""Render matched, deterministic generation references from the actual game doll.

Blender 5.2 --background --python tools/art/render_doll_generation_reference.py
Writes only the separate local reference package; never saves over game art.
"""
from pathlib import Path
import hashlib
import json
import struct
import zipfile

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/'ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/ModularEquipment/Threadborne_Doll_Modular.blend'
OUT = ROOT/'ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/GenerationReferences_2026_11_03'
OUT.mkdir(parents=True, exist_ok=True)
source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
rig.data.pose_position = 'REST'
rig.animation_data.action = None
for track in rig.animation_data.nla_tracks:
    track.mute = True
for pose_bone in rig.pose.bones:
    pose_bone.matrix_basis.identity()
bpy.context.view_layer.update()

body = [o for o in scene.objects if o.type == 'MESH' and
    (o.name == 'Threadborne_Doll' or o.name.startswith('Doll_Covered_'))]
garment_names = ['Base_Cowl', 'Base_Tunic', 'Base_Pants', 'Base_Bracer.L',
    'Base_Bracer.R', 'Base_Boot.L', 'Base_Boot.R']
clothes = [bpy.data.objects[name] for name in garment_names]
assert len(body) == 4 and len(rig.data.bones) == 62
assert len(bpy.data.actions) == 48
for obj in list(scene.objects):
    if obj.type in {'LIGHT','CAMERA'}:
        bpy.data.objects.remove(obj, do_unlink=True)


def geometry_hash(objects):
    digest = hashlib.sha256()
    for obj in sorted(objects, key=lambda o:o.name):
        digest.update(obj.name.encode('utf-8'))
        for vertex in obj.data.vertices:
            digest.update(struct.pack('<3f',*vertex.co))
        for polygon in obj.data.polygons:
            digest.update(struct.pack('<'+'I'*len(polygon.vertices),*polygon.vertices))
    return digest.hexdigest()


body_hash = geometry_hash(body)
clothes_hash = geometry_hash(clothes)
body_points = [o.matrix_world @ v.co for o in body for v in o.data.vertices]
low = Vector(tuple(min(p[i] for p in body_points) for i in range(3)))
high = Vector(tuple(max(p[i] for p in body_points) for i in range(3)))
center = (low+high)/2
# One camera scale and center for all four images. No per-image fitting/cropping.
ortho_scale = max(high.x-low.x,high.z-low.z)*1.16
resolution = 2048

scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.cycles.max_bounces = 4
scene.render.resolution_x = resolution
scene.render.resolution_y = resolution
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGB'
scene.render.image_settings.color_depth = '8'
scene.render.film_transparent = False
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.view_settings.exposure = -1.1
scene.view_settings.gamma = 1
world = bpy.data.worlds.new('Reference white studio')
world.use_nodes = True
nodes = world.node_tree.nodes
nodes.clear()
ambient = nodes.new('ShaderNodeBackground')
ambient.inputs['Color'].default_value = (.78,.78,.78,1)
ambient.inputs['Strength'].default_value = .55
background = nodes.new('ShaderNodeBackground')
background.inputs['Color'].default_value = (1,1,1,1)
background.inputs['Strength'].default_value = 2**1.1
path = nodes.new('ShaderNodeLightPath')
mix = nodes.new('ShaderNodeMixShader')
output = nodes.new('ShaderNodeOutputWorld')
links = world.node_tree.links
links.new(path.outputs['Is Camera Ray'],mix.inputs[0])
links.new(ambient.outputs[0],mix.inputs[1])
links.new(background.outputs[0],mix.inputs[2])
links.new(mix.outputs[0],output.inputs[0])
scene.world = world
for label,position,power,size in [
    ('front',(0,-4,3.6),360,4),('back',(0,4,3.6),360,4),
    ('left',(-4,0,2),140,3),('right',(4,0,2),140,3)]:
    data = bpy.data.lights.new('Reference softbox '+label,'AREA')
    data.energy = power
    data.shape = 'DISK'
    data.size = size
    light = bpy.data.objects.new(data.name,data)
    scene.collection.objects.link(light)
    light.location = position
    light.rotation_euler = (center-light.location).to_track_quat('-Z','Y').to_euler()
camera_data = bpy.data.cameras.new('Matched orthographic camera')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = ortho_scale
camera = bpy.data.objects.new(camera_data.name,camera_data)
scene.collection.objects.link(camera)
scene.camera = camera


def set_variant(clothed):
    for obj in scene.objects:
        if obj.type != 'MESH':
            continue
        visible = obj in body or (clothed and obj in clothes)
        if clothed and obj in body and obj.name.startswith('Doll_Covered_'):
            visible = False
        obj.hide_render = not visible
        obj.hide_set(not visible)


def set_view(direction):
    camera.location = center+Vector((0,direction*6,0))
    camera.rotation_euler = (center-camera.location).to_track_quat('-Z','Y').to_euler()


manifest = {'source':str(SOURCE.relative_to(ROOT)),'source_sha256':source_hash,
    'body_geometry_sha256':body_hash,'garment_geometry_sha256':clothes_hash,
    'bones':62,'actions_retained':48,'pose':'unaltered skeleton REST (T-pose)',
    'resolution':[resolution,resolution],'camera':'orthographic',
    'ortho_scale':ortho_scale,'camera_target':list(center),
    'body_bounds':{'min':list(low),'max':list(high)},
    'joint_positions_blender':{b.name:list(rig.matrix_world @ b.head_local) for b in rig.data.bones},
    'views':[], 'excluded_accessories':'sword, shield, grapple coil and needle'}
for clothed,prefix in [(False,'master_bare'),(True,'base_outfit')]:
    set_variant(clothed)
    for label,direction in [('front',-1),('back',1)]:
        set_view(direction)
        filename=prefix+'_'+label+'.png'
        scene.render.filepath=str(OUT/filename)
        bpy.ops.render.render(write_still=True)
        assert geometry_hash(body)==body_hash
        assert geometry_hash(clothes)==clothes_hash
        manifest['views'].append({'file':filename,'variant':prefix,'view':label,
            'camera_position':list(camera.location),'ortho_scale':camera.data.ortho_scale,
            'body_geometry_sha256':geometry_hash(body),
            'sha256':hashlib.sha256((OUT/filename).read_bytes()).hexdigest()})
        print('REFERENCE_RENDERED',filename,flush=True)
set_variant(True)
set_view(-1)
scene['reference_use'] = 'Use the bare pair as the canonical body; the outfit pair describes the current starter clothing.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Threadborne_Reference_Master.blend'),compress=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_hash
manifest['source_unchanged']=True
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
prompt = '''Use the supplied front and back master references as the same character in the same strict T-pose.
Preserve the exact blank oval stitched head, pale worn lacquer, carved limb shapes, body proportions, joint locations, hands and fingers.
Create the requested clothing style on this existing doll. Change clothing only. Keep full-body orthographic front/back views at matching scale on white.
Keep elbow and knee interfaces aligned with the master; boots end at mid-shin for the starter outfit. Keep hands clear, with no weapons.
Treat the two dressed views as one coherent outfit. Do not redesign the doll or substitute a new skeleton or mechanical joint construction.
'''
(OUT/'outfit_reference_prompt.txt').write_text(prompt,encoding='utf-8')
readme = '''# Threadborne master T-pose references — November 3, 2026

These are direct renders of the current game doll and current fitted base clothing.
The actual 3D body, skeleton and garment geometry are unchanged. No generative redraw is used.

## Files
- master_bare_front.png + master_bare_back.png: canonical doll identity, proportions and joints.
- base_outfit_front.png + base_outfit_back.png: the current starter outfit on that exact doll.
- manifest.json: source/geometry hashes, all 62 joint positions and shared camera settings.
- outfit_reference_prompt.txt: identity-preserving wording for future outfit reference work.
- Threadborne_Reference_Master.blend: separate editable reference scene, defaulting to the clothed front view.

For a full starter-character Tripo job, use the TWO base_outfit images as views of one object.
Use the bare pair as the master design/fit guide. Do not mix bare and clothed images as four views of a single clothed generation.
The prompt is for preparing future outfit reference images; the Tripo image-to-3D input is the matched dressed image pair.
All four images have the same orthographic scale, pose, center, lighting and 2048x2048 canvas. The back is rendered from behind, not mirrored from the front.
Sword, shield and grapple hardware are omitted so they do not fuse into hands or clothes during generation.

These references make the input consistent. Independently generated meshes may still drift; fit each result to this same 62-bone master and compare joint positions before cutting interchangeable sections.
The clothed images show the current outfit as an authoring reference, not a claim that animated clipping is resolved or that replacement equipment is approved.

Artwork and the editable reference scene stay local under the current public-repository policy. The ZIP contains the four PNGs, manifest and prompt, not the large Blender source.
'''
(OUT/'README.md').write_text(readme,encoding='utf-8')
files=['master_bare_front.png','master_bare_back.png','base_outfit_front.png',
    'base_outfit_back.png','manifest.json','outfit_reference_prompt.txt','README.md']
with zipfile.ZipFile(OUT/'Threadborne_TPose_Front_Back_References.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for filename in files:
        archive.write(OUT/filename,filename)
with zipfile.ZipFile(OUT/'Threadborne_TPose_Front_Back_References.zip') as archive:
    assert archive.testzip() is None
    assert all(archive.read(name)==(OUT/name).read_bytes() for name in files)
print('DOLL_REFERENCE_COMPLETE',json.dumps({'views':4,'body_identity_preserved':True,
    'source_unchanged':True,'bones':62,'actions':48,'out':str(OUT)}),flush=True)
