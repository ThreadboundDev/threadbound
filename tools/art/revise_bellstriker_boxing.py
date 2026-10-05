"""Add swim and amphibious boxing clips; preserve the v1 Blender workspace."""
from pathlib import Path
import math
import sys
import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v2.blend'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Preserve manual v2 animation edits.'
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/BlueBiome/Enemies/Bellstriker_Rigged_v1.blend'))
rig = bpy.data.objects['Bellstriker_Rig']
scene = bpy.context.scene
scene.render.fps = 30
mesh = bpy.data.objects['Bellstriker_Shell']
# Generated geometry is fused, not joint-ready. Separate whole claw faces
# before posing: otherwise shared club/body triangles stretch into long sheets.
original_data = mesh.data.copy()
def region(face):
    x,y,z = face.calc_center_median()
    club = ((x-.95)/.85)**2 + ((abs(y)-.90)/.65)**2 + ((z-.70)/.90)**2
    return ('L' if y >= 0 else 'R') if x > .25 and abs(y) > .35 and club < 1.65 else 'body'
parts = []
for name in ('body','L','R'):
    part = mesh if name == 'body' else mesh.copy()
    if part != mesh:
        scene.collection.objects.link(part)
        part.name = 'Bellstriker_Claw_'+name
    part.data = original_data.copy()
    edit = bmesh.new()
    edit.from_mesh(part.data)
    bmesh.ops.delete(edit, geom=[f for f in edit.faces if region(f) != name], context='FACES')
    bmesh.ops.delete(edit, geom=[v for v in edit.verts if not v.link_faces], context='VERTS')
    edit.to_mesh(part.data)
    edit.free()
    if name != 'body':
        for group in list(part.vertex_groups):
            part.vertex_groups.remove(group)
        part.vertex_groups.new(name='claw.'+name).add(list(range(len(part.data.vertices))), 1.0, 'REPLACE')
    else:
        for vertex in part.data.vertices:
            if any(part.vertex_groups[g.group].name.startswith('claw.') for g in vertex.groups):
                for group in part.vertex_groups:
                    group.remove([vertex.index])
                part.vertex_groups['body'].add([vertex.index],1.0,'REPLACE')
    parts.append(part)

def smooth(t):
    t = max(0, min(1, t))
    return t*t*(3-2*t)

def pose(kind, t, wet):
    for bone in rig.pose.bones:
        bone.rotation_mode = 'XYZ'
        bone.location = (0,0,0)
        bone.rotation_euler = (0,0,0)
        bone.scale = (1,1,1)
    body = rig.pose.bones['body']
    tail = rig.pose.bones['tail']
    swim = kind in ('swim', 'swim_idle')
    boxing = wet and not swim
    body.location.y = .025*math.sin(t*math.tau)
    body.rotation_euler.z = math.radians(52) if boxing else 0
    tail.rotation_euler.z = .12*math.sin(t*math.tau) if swim else .03*math.sin(t*math.tau)
    if boxing:
        rig.pose.bones['head'].rotation_euler.z = math.radians(-47)
    if kind == 'swim':
        # Tail/body undulation provides thrust; no alternating walk gait.
        body.rotation_euler.z = .035*math.sin(t*math.tau)
        tail.rotation_euler.x = .14*math.sin(t*math.tau)
    for side, sign in [('L',1), ('R',-1)]:
        claw = rig.pose.bones[f'claw.{side}']
        claw.rotation_euler.z = math.radians(12) if boxing else 0
        claw.location.x = -.06 if boxing else 0
        rig.pose.bones[f'antenna.{side}'].rotation_euler.x = sign*.04*math.sin(t*math.tau)
        for index in range(3):
            leg = rig.pose.bones[f'leg.{index}.{side}']
            if wet:
                leg.rotation_euler.x = -sign*.40
                leg.rotation_euler.z = -.18
            elif kind == 'walk':
                leg.rotation_euler.x = .18*math.sin(t*math.tau+index*2+sign*math.pi/2)
                leg.rotation_euler.z = .14*math.cos(t*math.tau+index*2+sign*math.pi/2)
        if kind.startswith('charge_'):
            step = int(kind[-1])
            active = step == 3 or side == ('L' if step == 1 else 'R')
            if active:
                claw.rotation_euler.z += math.radians(24 if step < 3 else 40)*smooth(t)
                claw.location.x -= .16*smooth(t)
                if step == 3:
                    claw.location.y += .10*smooth(t)
            body.rotation_euler.x = (.06 if step == 1 else -.09)*smooth(t) if step < 3 else 0
            body.rotation_euler.z -= math.radians(5 if step < 3 else 12)*smooth(t)
        elif kind in ('jab', 'cross', 'smash'):
            step = ('jab','cross','smash').index(kind)+1
            active = step == 3 or side == ('L' if step == 1 else 'R')
            progress = smooth(t/.55)
            if active:
                claw.rotation_euler.z += math.radians((24 if step < 3 else 40)*(1-progress)-(12 if step < 3 else 25)*progress)
                claw.location.x += -.16 + (.52 if step < 3 else .65)*progress
                claw.location.y += .10*(1-progress) if step == 3 else 0
            body.rotation_euler.x = (.06 if step == 1 else -.09)*(1-2*progress) if step < 3 else 0
            body.rotation_euler.z += math.radians((-5 if step < 3 else -12)+(12 if step < 3 else 25)*progress)
        elif kind == 'box_recover':
            claw.location.x += .49*(1-smooth(t))
            claw.rotation_euler.z -= math.radians(25)*(1-smooth(t))
            body.rotation_euler.z += math.radians(13)*(1-smooth(t))
            rig.pose.bones['head'].rotation_euler.x = .04*math.sin(t*math.tau*2)*(1-t)
    if boxing:
        # Raise the thorax, but keep the head and fists aimed forward. Translate
        # punches in world-forward space rather than along the tilted body.
        angle = body.rotation_euler.z
        rig.pose.bones['head'].rotation_euler.z = -angle + math.radians(5)
        for side in ('L','R'):
            claw = rig.pose.bones[f'claw.{side}']
            claw.rotation_euler.z -= angle
            x,y = claw.location.x,claw.location.y
            claw.location.x = x*math.cos(angle)+y*math.sin(angle)
            claw.location.y = -x*math.sin(angle)+y*math.cos(angle)

def animate(name, kind, count, wet):
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(1,count+1):
        pose(kind, (frame-1)/(count-1), wet)
        for bone in rig.pose.bones:
            for prop in ('location', 'rotation_euler', 'scale'):
                bone.keyframe_insert(prop, frame=frame, group=bone.name)
    print('BOX_CLIP', name)

for name, kind, count, wet in [('swim','swim',31,True),('swim_idle','swim_idle',61,True),('walk','walk',19,False),('box_idle','box_idle',31,True)]:
    animate(name,kind,count,wet)
for wet in (False,True):
    prefix = 'water_' if wet else ''
    for step, frames in [(1,11),(2,10),(3,20)]:
        animate(prefix+f'charge_{step}', f'charge_{step}', frames, wet)
    for name, count in [('jab',7),('cross',7),('smash',10),('box_recover',28)]:
        animate(prefix+name,name,count,wet)

rig.animation_data.action = bpy.data.actions['swim_idle']
scene.frame_start = 1
scene.frame_end = 61
scene.frame_set(1)
scene['boxing_notes'] = 'v2: tucked-leg tail-driven swimming; walk on land; raised front (52deg) underwater boxing stance. Left jab, right cross, double-claw smash. Model weights remain a prototype. v1 retained.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in [rig]+parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(ROOT/'Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v2.glb'), export_format='GLB', use_selection=True, export_animation_mode='ACTIONS', export_force_sampling=True, export_lights=False, export_cameras=False)
print('BELL_BOXING_READY', DEST)
