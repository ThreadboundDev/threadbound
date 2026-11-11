"""Local fit experiment using the existing game-ready rig and clips."""
from pathlib import Path
from math import pi
import json
import bpy
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree

root = Path.cwd()
out = root / 'LocalOnly/OG_Material_Review'
scene = bpy.context.scene
target = next(o for o in scene.objects if o.type == 'MESH')
target.name = 'OG cloth review — weight transfer'
old = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(root / 'Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb'))
imported = set(bpy.data.objects) - old
rig = next(o for o in imported if o.type == 'ARMATURE')
donor = next(o for o in imported if o.name == 'Threadborne_Doll')
rig.data.pose_position = 'REST'
rig.animation_data.action = None
for track in rig.animation_data.nla_tracks:
    track.mute = True
bpy.context.view_layer.update()
positions = [donor.matrix_world @ v.co for v in donor.data.vertices]
weights = [{donor.vertex_groups[g.group].name:g.weight for g in v.groups if g.weight > 0.00001}
           for v in donor.data.vertices]
tree = KDTree(len(positions))
for i, p in enumerate(positions):
    tree.insert(p,i)
tree.balance()
matrix = target.matrix_world.copy()
original = [matrix @ v.co for v in target.data.vertices]
normals = [(matrix.to_3x3() @ v.normal).normalized() for v in target.data.vertices]
target.matrix_world = Matrix.Identity(4)
for name, values in [('review_rest_position',original),('review_rest_normal',normals)]:
    attr = target.data.attributes.new(name,'FLOAT_VECTOR','POINT')
    attr.data.foreach_set('vector',[coordinate for value in values for coordinate in value])
nodes = target.data.materials[0].node_tree.nodes
links = target.data.materials[0].node_tree.links
for attribute, socket in [('review_rest_position','Position'),('review_rest_normal','Normal')]:
    attr = nodes.new('ShaderNodeAttribute')
    attr.attribute_name = attribute
    for link in list(links):
        if link.from_node.type == 'NEW_GEOMETRY' and link.from_socket.name == socket and link.to_node.bl_idname == 'ShaderNodeSeparateXYZ':
            links.new(attr.outputs['Vector'], link.to_socket)

groups = {}
for vertex, source in zip(target.data.vertices, original):
    p = source * 1.94
    if abs(source.x) > .15 and source.z > .67:
        p.x *= .958
    if abs(source.x) > .367 and source.z > .68:
        wrist = Vector((p.x, 0, 1.495))
        angle = pi/2 * min(1, (abs(source.x)-.367)/.022)
        p = wrist + Matrix.Rotation(angle,3,'X') @ (p-wrist)
    vertex.co = p
    blend = {}
    side = 'L' if source.x >= 0 else 'R'
    if source.z > .84:
        blend['head'] = 1.0
    elif source.z < .205:
        # Keep the stiff boot shaft and toe box coherent across the ankle bend.
        shin = min(1.0,max(0.0,(source.z-.089)/.055))
        blend = {'foot.'+side:1-shin,'shin.'+side:shin}
    else:
        for _, index, distance in tree.find_n(p,8):
            factor = 1/max(distance,.006)**3
            for bone, weight in weights[index].items():
                other_leg = source.z < .49 and bone.endswith('.'+('R' if side=='L' else 'L'))
                if bone in rig.data.bones and not other_leg:
                    blend[bone] = blend.get(bone,0) + factor*weight
    chosen = sorted((entry for entry in blend.items() if entry[1] > 0), key=lambda entry: -entry[1])[:4]
    total = sum(w for _,w in chosen)
    assert total > 0
    for bone, weight in chosen:
        if bone not in groups:
            groups[bone] = target.vertex_groups.new(name=bone)
        groups[bone].add([vertex.index],weight/total,'REPLACE')
target.data.update()
target.parent = rig
target.matrix_parent_inverse = rig.matrix_world.inverted()
modifier = target.modifiers.new('Current game skeleton — trial weights','ARMATURE')
modifier.object = rig
for o in imported:
    if o != rig:
        o.hide_render = True
        o.hide_set(True)
rig.data.pose_position = 'POSE'
camera = bpy.data.objects['Review — level side']
camera.location = (-5,0,1.07)
camera.rotation_euler = (Vector((0,0,1.07))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale = 2.8
scene.camera = camera
scene.render.use_freestyle = False
scene.render.film_transparent = True
scene.render.resolution_x,scene.render.resolution_y = 900,1200
scene.cycles.samples = 8
scene.render.use_persistent_data = True
clips = {'idle':'idle_4','run':'run_1','jump':'jump_1'}

def set_clip(name):
    action = bpy.data.actions[clips[name]]
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    return action

def sample_pose(frame):
    scene.frame_set(frame)
    pelvis = rig.pose.bones['pelvis']
    camera.location.z = 1.07 + max(0.0, pelvis.head.z - pelvis.bone.head_local.z)

set_clip('idle')
sample_pose(12)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'OG_Motion_Trial.blend'))
if '--bake' not in __import__('sys').argv:
    for clip, sample in [('idle',12),('run',6),('jump',10)]:
        set_clip(clip)
        sample_pose(sample)
        scene.render.filepath = str(out/f'Trial_{clip}.png')
        bpy.ops.render.render(write_still=True)
else:
    frames = out/'motion_frames'
    frames.mkdir(exist_ok=True)
    manifest = []
    for clip in clips:
        action = set_clip(clip)
        end = round(action.frame_range.y)
        for i, frame in enumerate(range(0,end+1,2)):
            sample_pose(frame)
            path = frames/f'{clip}_{i:03}.png'
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)
            manifest.append({'clip':clip,'frame':frame,'file':path.name,'duration_ms':round(2000/scene.render.fps)})
    (out/'motion_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
