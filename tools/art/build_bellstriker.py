"""Prepare the supplied Bellstriker for a first playable enemy prototype."""
from pathlib import Path
import math
import shutil
import sys
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'ArtSource/BlueBiome/Enemies'
GAME = ROOT / 'Assets/BlueBiome/Enemies/Models'
ART.mkdir(parents=True, exist_ok=True)
GAME.mkdir(parents=True, exist_ok=True)
DEST = ART / 'Bellstriker_Rigged_v1.blend'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Preserve existing manual Bellstriker edits. Replacement is only for an untouched generated prototype.'
source = ART / 'Bellstriker_HighRes_Source.glb'
if not source.exists():
    shutil.copy2('C:/Users/chase/Downloads/hitem3d.glb', source)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
mesh.name = 'Bellstriker_Shell'
mesh.parent = None
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
modifier = mesh.modifiers.new('Game mesh reduction', 'DECIMATE')
modifier.ratio = .025
bpy.ops.object.modifier_apply(modifier=modifier.name)
# glTF imports in quaternion mode; switch before setting Euler rotation.
# Source claws point -X. Rotate them onto the +X claw/head bone pivots.
mesh.rotation_mode = 'XYZ'
mesh.rotation_euler.z = math.pi
mesh.scale = (2, 2, 2)
mesh.location.z = .632126
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for polygon in mesh.data.polygons:
    polygon.use_smooth = True
for image in bpy.data.images:
    if max(image.size) > 2048:
        image.scale(2048, 2048)
    image.pack()
for material in mesh.data.materials:
    material.use_backface_culling = False
print('GAME_MESH_TRIANGLES', len(mesh.data.polygons))

arm = bpy.data.armatures.new('Bellstriker_Skeleton')
rig = bpy.data.objects.new('Bellstriker_Rig', arm)
bpy.context.scene.collection.objects.link(rig)
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
pivots = {'body': (0,0,.9), 'head': (.8,0,1.05),
          'claw.L': (.55,.6,.85), 'claw.R': (.55,-.6,.85),
          'tail': (-.5,0,1.0), 'antenna.L': (.85,.15,1.2), 'antenna.R': (.85,-.15,1.2)}
for side, sign in [('L',1), ('R',-1)]:
    for index, x in enumerate([.25,-.15,-.55]):
        pivots[f'leg.{index}.{side}'] = (x,.42*sign,.55)
for name, position in pivots.items():
    bone = arm.edit_bones.new(name)
    bone.head = position
    bone.tail = Vector(position)+Vector((0,0,.35))
    if name != 'body':
        bone.parent = arm.edit_bones['body']
bpy.ops.object.mode_set(mode='OBJECT')
groups = {n: mesh.vertex_groups.new(name=n) for n in pivots}
for vertex in mesh.data.vertices:
    x,y,z = vertex.co
    name = 'body'
    weight = 0.0
    side = 'L' if y >= 0 else 'R'
    if x > .55 and abs(y) > .30 and z < .98:
        name = f'claw.{side}'
        weight = min(1.0, max(0.0, (x-.48)/.28))
    elif z < .45 and abs(y) > .26:
        index = min(range(3), key=lambda i: abs(x-[.25,-.15,-.55][i]))
        name = f'leg.{index}.{side}'
        weight = .85
    elif x < -.5:
        name = 'tail'
        weight = min(.85, (-x-.5)/.6)
    elif z > 1.36:
        name = f'antenna.{side}'
        weight = .8
    elif x > .55:
        name = 'head'
        weight = .6
    groups[name].add([vertex.index], weight if name != 'body' else 1.0, 'REPLACE')
    if name != 'body' and weight < 1.0:
        groups['body'].add([vertex.index], 1-weight, 'REPLACE')
mesh.parent = rig
modifier = mesh.modifiers.new('Bellstriker armature', 'ARMATURE')
modifier.object = rig
rig.show_in_front = True
rig.animation_data_create()
scene = bpy.context.scene
scene.render.fps = 30

def animate(name, count, kind):
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(1,count+1):
        t = (frame-1)/(count-1)
        for bone in rig.pose.bones:
            bone.rotation_mode = 'XYZ'
            bone.location = (0,0,0)
            bone.rotation_euler = (0,0,0)
            bone.scale = (1,1,1)
        body = rig.pose.bones['body']
        body.location.y = .025*math.sin(t*math.tau)
        rig.pose.bones['tail'].rotation_euler.z = .04*math.sin(t*math.tau)
        for side, sign in [('L',1),('R',-1)]:
            claw = rig.pose.bones[f'claw.{side}']
            claw.rotation_euler.z = .025*math.sin(t*math.tau+sign*.4)
            rig.pose.bones[f'antenna.{side}'].rotation_euler.x = sign*.06*math.sin(t*math.tau)
            if kind == 'pursue':
                body.location.y += .035*math.sin(t*math.tau*2)
                for index in range(3):
                    leg = rig.pose.bones[f'leg.{index}.{side}']
                    leg.rotation_euler.x = .18*math.sin(t*math.tau+index*2+sign*math.pi/2)
                    leg.rotation_euler.z = .14*math.cos(t*math.tau+index*2+sign*math.pi/2)
            elif kind == 'charge':
                claw.rotation_euler.z = math.radians(35 if side=='R' else 15)*t
                claw.location.x = -.15*t
                body.rotation_euler.z = math.radians(-6)*t
                body.location.y -= .06*t
            elif kind == 'strike':
                impact = min(1,t/.25)
                claw.rotation_euler.z = math.radians(35*(1-impact)-18*impact) if side=='R' else math.radians(15-23*impact)
                claw.location.x = -.15+.45*impact
                body.rotation_euler.z = math.radians(-6+16*impact)
            elif kind == 'recover':
                claw.rotation_euler.z = math.radians(-18 if side=='R' else -8)*(1-t)
                claw.location.x = .3*(1-t)
                body.rotation_euler.z = math.radians(10)*(1-t)
                rig.pose.bones['head'].rotation_euler.x = .06*math.sin(t*math.tau*2)*(1-t)
            elif kind == 'leap':
                claw.rotation_euler.z = math.radians(15)*math.sin(t*math.pi)
                rig.pose.bones['tail'].rotation_euler.z = -.2*math.sin(t*math.pi)
                for index in range(3):
                    rig.pose.bones[f'leg.{index}.{side}'].rotation_euler.x = sign*.25*math.sin(t*math.pi)
            elif kind == 'hurt':
                body.rotation_euler.z = -.1*math.sin(t*math.pi)
                claw.rotation_euler.z = .12*math.sin(t*math.pi)
            elif kind == 'dead':
                body.rotation_euler.x = .65*t
                body.location.y = -.25*t
        for bone in rig.pose.bones:
            for prop in ('location','rotation_euler','scale'):
                bone.keyframe_insert(prop, frame=frame, group=bone.name)
    print('CLIP',name,count)

for name, count in [('idle',61),('pursue',19),('charge',22),('strike',7),('recover',25),('leap',25),('hurt',10),('dead',19)]:
    animate(name,count,name)
rig.animation_data.action = bpy.data.actions['idle']
scene.frame_start = 1
scene.frame_end = 61
scene.frame_set(1)
scene['prototype_notes'] = 'Bellstriker: supplied high-res source preserved; 50k-triangle textured game mesh. First-pass weighted body/head/claw/tail/legs/antenna rig. Refine vertex weights and clips in this source. Forward is +X, feet at Z=0.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = rig
export = GAME / 'Bellstriker_Rigged_v1.glb'
bpy.ops.export_scene.gltf(filepath=str(export), export_format='GLB', use_selection=True,
                         export_animation_mode='ACTIONS', export_force_sampling=True,
                         export_lights=False, export_cameras=False)
print('BELLSTRIKER_ASSET_READY', DEST, export)
