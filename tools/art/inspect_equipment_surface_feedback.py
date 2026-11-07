"""Read-only surface review for the November 7 23:25 feedback.

Run in Blender background mode. Measurements and native renders go to LocalOnly;
no runtime asset or editable source is saved/replaced.
"""
from collections import defaultdict
from pathlib import Path
import hashlib
import json
import math
import struct
import re
import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT/'Assets/Threadborne/Player/LocalDoll'
OUT = ROOT/'LocalOnly/Equipment/FeedbackReview2026_11_07_2325'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').touch()
records = {}
hashes = {}
bpy.ops.wm.read_factory_settings(use_empty=True)


def load(path):
    hashes[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects = set(bpy.context.scene.objects)-before
    for obj in objects:
        obj.hide_render = True
        if obj.type == 'ARMATURE':
            obj.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    rigs = {obj for obj in objects if obj.type=='ARMATURE'}
    # Importer-created bone display shapes can also be MESH objects. They are
    # not equipment geometry and must never enter measurements or renders.
    return {obj for obj in objects if obj.type!='MESH' or obj.find_armature() in rigs}


def shin_sections(obj):
    sections = []
    points = [obj.matrix_world@v.co for v in obj.data.vertices]
    for height in (.36,.38,.40,.415,.43,.45,.47,.49):
        near = [p for p in points if p.x>.02 and abs(p.z-height)<.006]
        if near:
            low = [min(p[i] for p in near) for i in range(3)]
            high = [max(p[i] for p in near) for i in range(3)]
            sections.append({'height':height,'vertices':len(near),'width':high[0]-low[0],
                             'depth':high[1]-low[1],'center_y':(high[1]+low[1])*.5})
    return sections


def surface_stats(obj):
    # Weld glTF UV splits only in memory. Open edges after this step represent
    # geometric boundaries, rather than per-corner texture coordinate seams.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    boundaries = [edge for edge in bm.edges if edge.is_boundary]
    per_bone = defaultdict(int)
    deform = bm.verts.layers.deform.active
    for edge in boundaries:
        for vertex in edge.verts:
            if deform and vertex[deform]:
                owner = max(vertex[deform].items(),key=lambda pair:pair[1])[0]
                per_bone[obj.vertex_groups[owner].name] += 1
    result = {'welded_vertices':len(bm.verts),'faces':len(bm.faces),
              'open_edges':len(boundaries),
              'open_edge_length_m':sum(edge.calc_length() for edge in boundaries),
              'open_edges_touching_finger_bones':sum(value for name,value in per_bone.items()
                  if name.startswith(('thumb.','index.','middle.','ring.','pinky.')))//2,
              'boundary_endpoints_per_owner':dict(per_bone)}
    bm.free()
    return result


master_objects = load(ASSETS/'threadborne_doll_equipped.glb')
actions = {name:bpy.data.actions[name] for name in ('idle_4','idle_2')}
current = {}
for key in ('base_gloves','blue_gloves','base_boots','blue_boots','base_head_chest','blue_head_chest'):
    objects = load(ASSETS/'Equipment/FittedSets'/(key+'.glb'))
    current[key] = objects
    rig = next(obj for obj in objects if obj.type=='ARMATURE')
    meshes = [obj for obj in objects if obj.type=='MESH']
    if key.endswith('gloves'):
        hand = next(obj for obj in meshes if obj.name.startswith('Shared_Wooden_Hands'))
        records[key] = {'hand_surface':surface_stats(hand)}
        bracer = next(obj for obj in meshes if obj.name.endswith('Bracers'))
        records[key]['bracer_surface'] = surface_stats(bracer)
    else:
        obj = next(obj for obj in meshes if not obj.name.startswith('Shared_'))
        # Near-section bboxes characterize the transition away from the cut;
        # a different radius alone is not evidence of an open hole.
        records[key] = {'shin_sections':shin_sections(obj)}

before = ROOT/'LocalOnly/Equipment/FeedbackReview2026_11_07/BeforeAssets/FittedSets/base_gloves.glb'
old_objects = load(before)
old_hand = next(obj for obj in old_objects if obj.type=='MESH' and obj.name.startswith('Shared_Wooden_Hands'))
records['before_hand_surface'] = surface_stats(old_hand)
for key in ('base_boots','blue_boots','base_head_chest','blue_head_chest'):
    objects = load(before.parent/(key+'.glb'))
    obj = next(obj for obj in objects if obj.type=='MESH' and not obj.name.startswith('Shared_'))
    records['before_'+key] = {'shin_sections':shin_sections(obj)}

# Inspect the actual AVI payload, not only its manifest. Decode each JPEG with
# Blender and compare it with its corresponding recorded frame file.
report_dir = ROOT/'LocalOnly/Feedback/reports/2026-11-07T23-25-10_25380_149270_2'
feedback = json.loads((report_dir/'report.json').read_text(encoding='utf-8'))
avi = (report_dir/'recording.avi').read_bytes()
frames = []


def chunks(start,end):
    cursor = start
    while cursor+8<=end:
        label = avi[cursor:cursor+4]
        size = struct.unpack_from('<I',avi,cursor+4)[0]
        assert cursor+8+size<=len(avi),'Truncated AVI chunk'
        if label in (b'LIST',b'RIFF'):
            chunks(cursor+12,cursor+8+size)
        elif label.endswith(b'dc'):
            frames.append(avi[cursor+8:cursor+8+size])
        cursor += 8+size+(size%2)


assert avi[:4]==b'RIFF' and avi[8:12]==b'AVI '
chunks(12,len(avi))
manifest = feedback['attachments']['recording']['frames']
assert len(manifest)==169
# AVI is constant-rate: the recorder repeats captured JPEGs to preserve timing.
captured = [(report_dir/entry['file']).read_bytes() for entry in manifest]
# A constant-rate sample can omit a capture just after the final output slot.
# Require every AVI payload to be an intact source JPEG in chronological order;
# record which captures were omitted instead of assuming one packet per capture.
lookup = {hashlib.sha256(frame).digest():index for index,frame in enumerate(captured)}
mapped = [lookup.get(hashlib.sha256(frame).digest()) for frame in frames]
assert all(index is not None for index in mapped),'Unknown AVI JPEG payload'
assert all(a<=b for a,b in zip(mapped,mapped[1:])),'Out-of-order AVI payload'
for encoded,entry in zip(captured,manifest):
    assert re.fullmatch(r'frame_\d{4}\.jpg',entry['file'])
    file = report_dir/entry['file']
    assert encoded==file.read_bytes(),entry['file']
    decoded = bpy.data.images.load(str(file),check_existing=False)
    assert tuple(decoded.size)==(960,540) and len(decoded.pixels)>0
    assert math.isfinite(decoded.pixels[0])
    bpy.data.images.remove(decoded)
records['recording_validation'] = {'avi_frames':len(frames),'jpeg_frames_decoded':len(manifest),
    'extra_avi_timing_frames':len(frames)-len(captured),'payloads_match_frame_files':True,
    'captures_not_in_avi':sorted(set(range(len(captured)))-set(mapped)),
    'duration_s':feedback['attachments']['recording']['duration_seconds']}

# Plain native material views establish whether edges exist without the game
# outline. This is a temporary inspection scene; the source meshes stay intact.
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.cycles.use_denoising = True
scene.render.resolution_x = scene.render.resolution_y = 640
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.world = bpy.data.worlds.new('Surface inspection studio')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.12,.12,.12,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .7
camera = bpy.data.objects.new('Surface inspection camera',bpy.data.cameras.new('Camera'))
scene.collection.objects.link(camera)
camera.data.type = 'ORTHO'
scene.camera = camera
light = bpy.data.objects.new('Surface inspection key',bpy.data.lights.new('Key','AREA'))
scene.collection.objects.link(light)
light.data.energy = 200
light.data.size = 2
light.location = (1,-2,3)
light.rotation_euler = (Vector((.5,0,1.2))-light.location).to_track_quat('-Z','Y').to_euler()


def render(label,objects,target,scale,direction):
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':
            obj.hide_render = obj not in objects
    camera.location = target+Vector(direction).normalized()*3
    camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale = scale
    scene.render.filepath = str(OUT/(label+'.png'))
    bpy.ops.render.render(write_still=True)


for key in ('base_gloves','blue_gloves'):
    objects = current[key]
    rig = next(obj for obj in objects if obj.type=='ARMATURE')
    bpy.context.view_layer.update()
    wrist = rig.matrix_world@rig.data.bones['hand.L'].head_local
    render(key+'_rest_no_outline',objects,wrist+Vector((.075,0,0)),.39,(.4,-1,.55))
    render(key+'_wrist_side_no_outline',objects,wrist,.24,(0,-1,.12))
    rig.data.pose_position = 'POSE'
    rig.animation_data_create()
    rig.animation_data.action = actions['idle_2']
    rig.animation_data.action_slot = actions['idle_2'].slots[0]
    first,last = actions['idle_2'].frame_range
    frame = first+.35*(last-first)
    scene.frame_set(int(frame),subframe=frame-int(frame))
    wrist = rig.matrix_world@rig.pose.bones['hand.L'].head
    render(key+'_idle2_no_outline',objects,wrist,.34,(.4,-1,.55))
    rig.data.pose_position = 'REST'

render('base_pants_blue_boots_no_outline',current['base_head_chest']|current['blue_boots'],
       Vector((.132,0,.43)),.34,(.35,-1,.08))
for path,expected in hashes.items():
    assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==expected,path
records['source_sha256_unchanged'] = hashes
(OUT/'surface_diagnostics.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('SURFACE_REVIEW_COMPLETE',json.dumps({key:value for key,value in records.items() if 'surface' in key or key.endswith('gloves')}),flush=True)
