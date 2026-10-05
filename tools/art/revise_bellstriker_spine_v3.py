"""Full-spine swimming and upright boxing. Never overwrites v1/v2 sources.

Run Blender --background --python tools/art/revise_bellstriker_spine_v3.py.
--replace-generated is only for this script's untouched v3 output during review.
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v3.blend'
EXPORT = ROOT / 'Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v3.glb'
assert not DEST.exists() or '--replace-generated' in sys.argv, 'Preserve manual v3 edits.'
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v2.blend'))
scene = bpy.context.scene
scene.render.fps = 30
rig = bpy.data.objects['Bellstriker_Rig']
rig.animation_data_clear()
parts = [o for o in scene.objects if o.type == 'MESH']
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
rig.data = bpy.data.armatures.new('Bellstriker_FullSpine_v3')
rig.show_in_front = True
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')

def bone(name, head, tail, parent=None, connected=False):
    b = rig.data.edit_bones.new(name)
    b.head, b.tail = head, tail
    if parent:
        b.parent = rig.data.edit_bones[parent]
        b.use_connect = connected
    return b

bone('body', (0, 0, .90), (.36, 0, .96))
bone('thorax', (.36, 0, .96), (.62, 0, 1.07), 'body', True)
bone('neck', (.62, 0, 1.07), (.82, 0, 1.12), 'thorax', True)
bone('head', (.82, 0, 1.12), (1.13, 0, 1.12), 'neck', True)
tail_points = [(0, 0, .90), (-.35, 0, .93), (-.70, 0, .97),
               (-1.03, 0, .94), (-1.34, 0, .88), (-1.61, 0, .76), (-1.88, 0, .64)]
tail_names = ['abdomen', 'tail.01', 'tail.02', 'tail.03', 'tail.04', 'tail_fan']
for i, name in enumerate(tail_names):
    bone(name, tail_points[i], tail_points[i+1], 'body' if i == 0 else tail_names[i-1], i > 0)
claw_centers = {}
for side, sign in [('L', 1), ('R', -1)]:
    part = bpy.data.objects['Bellstriker_Claw_' + side]
    center = Vector(tuple((min(v.co[i] for v in part.data.vertices) + max(v.co[i] for v in part.data.vertices))/2 for i in range(3)))
    claw_centers[side] = center
    shoulder = Vector((.35, sign*.43, .96))
    # A mantis-like folded upper arm gives the boxer real extension range.
    elbow = Vector((.08, sign*.78, .53))
    bone('arm.'+side, shoulder, elbow, 'thorax')
    bone('forearm.'+side, elbow, center, 'arm.'+side, True)
    tip = max(v.co.x for v in part.data.vertices) + .04
    bone('claw.'+side, center, Vector((tip, center.y, center.z-.12)), 'forearm.'+side, True)
    bone('antenna.'+side, (.85, sign*.15, 1.2), (1.25, sign*.20, 1.46), 'head')
    bone('antenna_tip.'+side, (1.25, sign*.20, 1.46), (1.72, sign*.25, 1.62), 'antenna.'+side, True)
    for i, x in enumerate([.35, 0, -.35, -.70]):
        parent = 'body' if i < 2 else ('abdomen' if i == 2 else 'tail.01')
        hip, knee, ankle, toe = (x, sign*.40, .55), (x-.04, sign*.70, .29), (x+.06, sign*.96, .09), (x+.17, sign*1.45, .01)
        bone(f'leg.{i}.{side}', hip, knee, parent)
        bone(f'shin.{i}.{side}', knee, ankle, f'leg.{i}.{side}', True)
        bone(f'toe.{i}.{side}', ankle, toe, f'shin.{i}.{side}', True)
bpy.ops.object.mode_set(mode='OBJECT')

# Smooth longitudinal weights cover the entire abdomen and tail fan. No
# fixed body influence is left at the tail end; leg roots follow their segment.
stations = [(-1.75, 'tail_fan'), (-1.46, 'tail.04'), (-1.18, 'tail.03'),
            (-.86, 'tail.02'), (-.52, 'tail.01'), (-.18, 'abdomen'),
            (.16, 'body'), (.46, 'thorax'), (.68, 'neck'), (.96, 'head')]

def between(value, samples):
    if value <= samples[0][0]:
        return [(samples[0][1], 1.0)]
    if value >= samples[-1][0]:
        return [(samples[-1][1], 1.0)]
    for (a, an), (b, bn) in zip(samples, samples[1:]):
        if a <= value <= b:
            t = (value-a)/(b-a)
            t = t*t*(3-2*t)
            return [(an, 1-t), (bn, t)]

for part in parts:
    for group in list(part.vertex_groups):
        part.vertex_groups.remove(group)
    groups = {b.name: part.vertex_groups.new(name=b.name) for b in rig.data.bones}
    for vertex in part.data.vertices:
        x, y, z = vertex.co
        side = 'L' if y >= 0 else 'R'
        if part.name.startswith('Bellstriker_Claw_'):
            weights = [('claw.'+part.name[-1], 1.0)]
        elif x > .65 and z > 1.30:
            # High forward points include the crest/eye armour, not just feelers.
            # Keep them rigid with the focused head instead of peeling them away.
            weights = [('head', 1.0)]
        elif -.95 < x < .67 and z < .46 and abs(y) > .39:
            i = min(range(4), key=lambda index: abs(x-[.35, 0, -.35, -.70][index]))
            weights = between(abs(y), [(.4, f'leg.{i}.{side}'), (.74, f'shin.{i}.{side}'), (1.05, f'toe.{i}.{side}')])
        else:
            weights = between(x, stations)
        for name, weight in weights:
            if weight > 0:
                groups[name].add([vertex.index], weight, 'REPLACE')
    part.parent = rig
    for modifier in part.modifiers:
        if modifier.type == 'ARMATURE':
            modifier.object = rig
            modifier.use_deform_preserve_volume = False

# Explicit joint links hide the original fused mesh's open claw attachment.
# Each link is rigidly weighted, rather than stretching an armour shell.
blue = bpy.data.materials.new('Bellstriker_Joint_Navy')
blue.diffuse_color = (.035, .07, .14, 1)
blue.use_nodes = True
blue.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = blue.diffuse_color
blue.node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = .45
for side in ['L', 'R']:
    for name in ['arm.'+side, 'forearm.'+side]:
        b = rig.data.bones[name]
        center = (b.head_local + b.tail_local)/2
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1, location=center)
        link = bpy.context.object
        link.name = 'Bellstriker_Joint_' + name
        link.rotation_mode = 'QUATERNION'
        link.rotation_quaternion = (b.tail_local-b.head_local).to_track_quat('Z', 'Y')
        link.scale = (.095, .095, b.length*.65)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        link.data.materials.append(blue)
        for face in link.data.polygons:
            face.use_smooth = True
        link.vertex_groups.new(name=name).add(list(range(len(link.data.vertices))), 1.0, 'REPLACE')
        link.parent = rig
        link.modifiers.new('Articulated joint', 'ARMATURE').object = rig
        parts.append(link)

bpy.context.view_layer.objects.active = rig
rig.animation_data_create()

def smooth(t):
    t = max(0, min(1, t))
    return t*t*(3-2*t)

def rotate(name, pitch=0, yaw=0, roll=0):
    rest = rig.data.bones[name].matrix_local.to_quaternion()
    q = Quaternion((0, 1, 0), math.radians(pitch)) @ Quaternion((0, 0, 1), math.radians(yaw)) @ Quaternion((1, 0, 0), math.radians(roll))
    rig.pose.bones[name].rotation_quaternion = rest.inverted() @ q @ rest

def world_bone(name, head, tail):
    """Two-bone arm IK baked into connected arm/forearm pose matrices."""
    rest = rig.data.bones[name]
    rest_dir = (rest.tail_local-rest.head_local).normalized()
    q = rest_dir.rotation_difference((tail-head).normalized())
    rig.pose.bones[name].matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ rest.matrix_local.to_3x3().to_4x4()
    bpy.context.view_layer.update()

def arm_target(side, target, fist_pitch=0):
    upper, lower = rig.data.bones['arm.'+side], rig.data.bones['forearm.'+side]
    shoulder = rig.pose.bones['arm.'+side].head.copy()
    a, b = upper.length, lower.length
    vector = target-shoulder
    distance = max(abs(a-b)+.001, min(vector.length, (a+b)*.985))
    direction = vector.normalized()
    target = shoulder+direction*distance
    along = (a*a-b*b+distance*distance)/(2*distance)
    height = math.sqrt(max(0, a*a-along*along))
    pole = Vector((-.20, .40 if side == 'L' else -.40, -.8))
    bend = (pole-direction*direction.dot(pole)).normalized()
    elbow = shoulder+direction*along+bend*height
    world_bone('arm.'+side, shoulder, elbow)
    world_bone('forearm.'+side, elbow, target)
    rest = rig.data.bones['claw.'+side]
    q = Quaternion((0, 1, 0), math.radians(fist_pitch))
    rig.pose.bones['claw.'+side].matrix = Matrix.Translation(target) @ q.to_matrix().to_4x4() @ rest.matrix_local.to_3x3().to_4x4()
    bpy.context.view_layer.update()

def pose(kind, t, wet):
    for pb in rig.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = Quaternion()
        pb.scale = (1, 1, 1)
    swim = kind in ['swim', 'swim_idle', 'leap']
    boxing = wet and not swim and kind not in ['hurt', 'dead']
    phase = t*math.tau
    step = int(kind[-1]) if kind.startswith('charge_') else (['jab', 'cross', 'smash'].index(kind)+1 if kind in ['jab', 'cross', 'smash'] else 0)
    charge = smooth(t) if kind.startswith('charge_') else 0
    release = smooth(t/.65) if kind in ['jab', 'cross', 'smash'] else 0
    pitch = -90.0 if boxing else 0.0
    yaw = 0.0
    if kind in ['swim', 'swim_idle']:
        energy = 1.0 if kind == 'swim' else .38
        pitch = 2.0*math.sin(phase)*energy
        rig.pose.bones['body'].location.z = .022*math.sin(phase)
        for i, name in enumerate(tail_names):
            rotate(name, (4.5+i*.8)*math.sin(phase-i*.5)*energy)
        rotate('thorax', -1.4*math.sin(phase)*energy)
        rotate('neck', -1.0*math.sin(phase-.2)*energy)
        rotate('head', .8*math.sin(phase-.3)*energy)
    elif boxing:
        pitch += 1.0*math.sin(phase)
        for name, curl in zip(tail_names, [-4, -5, -6, -7, -5, -4]):
            rotate(name, curl + 1.0*math.sin(phase-tail_names.index(name)*.35))
        rotate('thorax', 12 + .8*math.sin(phase))
        rotate('neck', 10 + .6*math.sin(phase-.2))
        # Counter-rotate the head after the thorax/neck, so its eyes face forward.
        if step:
            load = charge if kind.startswith('charge_') else 1-release
            pitch -= (4 if step < 3 else 8)*load
            pitch += (7 if step < 3 else 17)*release
            yaw = (7 if step == 1 else -10 if step == 2 else 0)*(load-release)
        if kind == 'box_recover':
            pitch += 17*(1-smooth(t))
    elif kind == 'walk':
        rig.pose.bones['body'].location.z = .02*math.sin(phase*2)
    elif kind == 'hurt':
        pitch = 8*math.sin(t*math.pi)
    elif kind == 'dead':
        rotate('body', roll=60*t)
        rig.pose.bones['body'].location.z = -.22*t
    rotate('body', pitch, yaw, 60*t if kind == 'dead' else 0)
    if boxing:
        rotate('head', -pitch-22, -yaw)
    for side, sign in [('L', 1), ('R', -1)]:
        rotate('antenna.'+side, 1.5*math.sin(phase+.3), roll=sign*2*math.sin(phase))
        rotate('antenna_tip.'+side, 2*math.sin(phase-.4), roll=sign*3*math.sin(phase-.3))
        for i in range(4):
            if wet:
                rotate(f'leg.{i}.{side}', -12, roll=sign*24 + sign*2*math.sin(phase+i*.65))
                rotate(f'shin.{i}.{side}', 8, roll=-sign*28)
                rotate(f'toe.{i}.{side}', -5, roll=sign*10)
            elif kind == 'walk':
                rotate(f'leg.{i}.{side}', 12*math.sin(phase+i*1.7+sign*math.pi/2), roll=sign*5)
                rotate(f'shin.{i}.{side}', 8*math.sin(phase+i*1.7+sign*math.pi/2+.5))
                rotate(f'toe.{i}.{side}', -5*math.sin(phase+i*1.7+sign*math.pi/2))
    bpy.context.view_layer.update()
    if boxing:
        # Focus the head in rig/world space, independently of the torso's
        # boxing twist. Local yaw counter-rotation under a vertical parent
        # otherwise rolls the face instead of keeping it on the opponent.
        head = rig.pose.bones['head']
        rest = rig.data.bones['head']
        q = Quaternion((0, 1, 0), math.radians(.8*math.sin(phase)))
        head.matrix = Matrix.Translation(head.head) @ q.to_matrix().to_4x4() @ rest.matrix_local.to_3x3().to_4x4()
        bpy.context.view_layer.update()
    if not swim and kind not in ['walk', 'idle', 'hurt', 'dead']:
        for side, sign in [('L', 1), ('R', -1)]:
            guard = Vector((.70 if side == 'L' else .50, sign*.74, 1.48 if side == 'L' else 1.65)) if boxing else Vector((1.03, sign*.75, 1.02))
            target = guard.copy()
            fist_pitch = 0
            active = step == 3 or (side == ('L' if step == 1 else 'R'))
            if active and step < 3 and step:
                pull = Vector((-.13, 0, .035))
                extension = Vector((.67 if step == 1 else .82, -.06*sign, -.04))
                target += pull*charge if kind.startswith('charge_') else pull*(1-release)+extension*release
                fist_pitch = -5*charge + 8*release
            elif step == 3:
                overhead = Vector((.15 if boxing else .50, sign*.28, 2.52 if boxing else 1.96))
                finish = Vector((1.10 if boxing else 1.65, sign*.28, .83 if boxing else .48))
                if kind.startswith('charge_'):
                    target = guard.lerp(overhead, charge)
                    fist_pitch = -35*charge
                else:
                    control = Vector((1.48 if boxing else 1.72, sign*.28, 2.30 if boxing else 1.66))
                    target = overhead*(1-release)**2+control*(2*release*(1-release))+finish*release**2
                    fist_pitch = -35+65*release
            elif kind == 'box_recover':
                finish = Vector((1.10 if boxing else 1.65, sign*.28, .83 if boxing else .48))
                target = finish.lerp(guard, smooth(t))
                fist_pitch = 30*(1-smooth(t))
            elif kind == 'box_idle':
                target.z += .018*math.sin(phase+sign*.3)
            arm_target(side, target, fist_pitch)
    bpy.context.view_layer.update()

def animate(name, kind, count, wet):
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(1, count+1):
        pose(kind, (frame-1)/(count-1), wet)
        for pb in rig.pose.bones:
            for prop in ['location', 'rotation_quaternion', 'scale']:
                pb.keyframe_insert(prop, frame=frame, group=pb.name)
    print('V3_CLIP', name, count)

for name, count, wet in [('idle', 61, False), ('walk', 25, False), ('swim', 37, True), ('swim_idle', 91, True), ('box_idle', 61, True), ('leap', 25, True), ('hurt', 13, False), ('dead', 19, False)]:
    animate(name, name, count, wet)
for wet in [False, True]:
    prefix = 'water_' if wet else ''
    for step, count in [(1, 11), (2, 10), (3, 20)]:
        animate(prefix+f'charge_{step}', f'charge_{step}', count, wet)
    for name, count in [('jab', 7), ('cross', 7), ('smash', 10), ('box_recover', 28)]:
        animate(prefix+name, name, count, wet)

rig.animation_data.action = bpy.data.actions['box_idle']
scene.frame_start, scene.frame_end = 1, 61
scene.frame_set(1)
scene['boxing_notes'] = 'v3: complete connected six-segment abdomen/tail chain to tail fan; 4 articulated legs per side; two-bone arms with baked IK. Vertical 90-degree body, curled head and tail, forward guard. Jab/cross/two-hand overhead smash. v1/v2 untouched.'
bpy.ops.wm.save_as_mainfile(filepath=str(DEST), compress=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in [rig]+parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT), export_format='GLB', use_selection=True, export_animation_mode='ACTIONS', export_force_sampling=True, export_lights=False, export_cameras=False)
print('BELL_V3_READY', DEST, EXPORT, 'bones', len(rig.data.bones))
