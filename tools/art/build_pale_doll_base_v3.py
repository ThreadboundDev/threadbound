"""Build an isolated reference-informed doll around the existing player rig.

This never writes a production asset. Run using Blender 5.2 in background mode.
"""
from pathlib import Path
import bpy
import hashlib
import json
import math
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/pale-doll-base-v3'
OUT = ROOT / 'ArtSource/Player/Blender/PaleDollStudy'
SOURCE = ROOT / 'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'
WORK.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)
(WORK / 'temp').mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
rest_before = {b.name: [list(row) for row in b.matrix_local] for b in rig.data.bones}


def action_digest():
    result = {}
    for action in bpy.data.actions:
        curves = []
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for fc in bag.fcurves:
                        curves.append((fc.data_path, fc.array_index, [
                            (list(k.co), list(k.handle_left), list(k.handle_right), k.interpolation)
                            for k in fc.keyframe_points]))
        result[action.name] = hashlib.sha256(json.dumps(curves, sort_keys=True).encode()).hexdigest()
    return result


actions_before = action_digest()
(WORK / 'source_inspection.json').write_text(json.dumps({
    'rig': rig.name,
    'matrix_world': [list(row) for row in rig.matrix_world],
    'bones': {b.name: {'head': list(b.head_local), 'tail': list(b.tail_local),
        'parent': b.parent.name if b.parent else None,
        'matrix': [list(row) for row in b.matrix_local]} for b in rig.data.bones},
    'meshes': [{'name': o.name, 'vertices': len(o.data.vertices),
        'materials': [m.name if m else None for m in o.data.materials]}
        for o in bpy.data.objects if o.type == 'MESH'],
    'actions': {a.name: {'frames': list(a.frame_range)} for a in bpy.data.actions},
}, indent=2))
for obj in list(bpy.data.objects):
    if obj != rig:
        bpy.data.objects.remove(obj, do_unlink=True)
for meshes in [bpy.data.meshes, bpy.data.materials, bpy.data.images]:
    for block in list(meshes):
        if block.users == 0:
            meshes.remove(block)
rig.data.pose_position = 'REST'
parts = []
bindings = {}


def material(name, color, roughness=.65, wear=False):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    if wear:
        geometry = nodes.new('ShaderNodeAttribute')
        geometry.attribute_name = 'DollRest'
        mapping = nodes.new('ShaderNodeVectorMath')
        mapping.operation = 'MULTIPLY'
        mapping.inputs[1].default_value = (1, 1, .25)
        mat.node_tree.links.new(geometry.outputs['Vector'], mapping.inputs[0])
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 90
        noise.inputs['Detail'].default_value = 2
        mat.node_tree.links.new(mapping.outputs['Vector'], noise.inputs['Vector'])
        ramp = nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].position = .48
        ramp.color_ramp.elements[0].color = (*color, 1)
        ramp.color_ramp.elements[1].position = .73
        ramp.color_ramp.elements[1].color = (.26, .14, .065, 1)
        ramp.color_ramp.elements.new(.67).color = (.74, .63, .43, 1)
        mat.node_tree.links.new(noise.outputs['Fac'], ramp.inputs[0])
        mat.node_tree.links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .16
        bump.inputs['Distance'].default_value = .001
        mat.node_tree.links.new(noise.outputs['Fac'], bump.inputs['Height'])
        mat.node_tree.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    return mat


ivory = material('Doll | warm worn ivory lacquer', (.76, .63, .44), wear=True)
wood = material('Doll | muted exposed hardwood', (.16, .070, .025), .73)
dark = material('Doll | recessed joinery', (.035, .022, .013), .9)
eye = material('Doll | black eye socket interior', (.006, .004, .003), .95)


def finish(obj, name, bone, mat, smooth=True):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if smooth:
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    rest = obj.data.attributes.new('DollRest', 'FLOAT_VECTOR', 'POINT')
    for vertex, value in zip(obj.data.vertices, rest.data):
        value.vector = obj.matrix_world @ vertex.co
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
    mod = obj.modifiers.new('Existing player skeleton | rigid weights', 'ARMATURE')
    mod.object = rig
    obj.parent = rig
    parts.append(obj)
    bindings[name] = bone
    return obj


def sphere(name, center, scale, bone, mat=ivory, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=center)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, bone, mat)


def cylinder(name, center, radius, depth, axis, bone, mat=wood):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=depth, location=center)
    obj = bpy.context.object
    obj.rotation_euler = Vector(axis).to_track_quat('Z', 'Y').to_euler()
    bevel = obj.modifiers.new('Crafted edge bevel', 'BEVEL')
    bevel.width = min(.002, radius * .09)
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return finish(obj, name, bone, mat)


def spindle(name, start, end, radius, thickness, bone, mat=ivory):
    start, end = Vector(start), Vector(end)
    axis = (end - start).normalized()
    depth = Vector((0, 1, 0))
    if abs(axis.dot(depth)) > .9:
        depth = Vector((1, 0, 0))
    depth = (depth - axis * axis.dot(depth)).normalized()
    wide = axis.cross(depth).normalized()
    profile = [(0, .34), (.025, .57), (.08, .82), (.18, .97), (.34, 1), (.55, .94), (.76, .79), (.94, .62), (.985, .44), (1, .30)]
    sides = 16
    vertices = []
    for t, size in profile:
        center = start.lerp(end, t)
        for j in range(sides):
            a = math.tau * j / sides
            vertices.append(center + wide * (math.cos(a) * radius * size) + depth * (math.sin(a) * thickness * size))
    faces = []
    for row in range(len(profile) - 1):
        for j in range(sides):
            faces.append((row*sides+j, row*sides+(j+1)%sides, (row+1)*sides+(j+1)%sides, (row+1)*sides+j))
    faces += [tuple(reversed(range(sides))), tuple((len(profile)-1)*sides+j for j in range(sides))]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, name, bone, mat)


def body_rings(name, rings, bone, mat=ivory):
    vertices = []
    sides = 24
    for z, width, depth in rings:
        for i in range(sides):
            a = math.tau * i / sides
            # Mildly squared sections give broad carved faces instead of muscles.
            x = math.copysign(abs(math.cos(a))**.8, math.cos(a)) * width
            y = math.copysign(abs(math.sin(a))**.8, math.sin(a)) * depth
            vertices.append((x, y, z))
    faces = []
    for r in range(len(rings)-1):
        for j in range(sides):
            faces.append((r*sides+j, r*sides+(j+1)%sides, (r+1)*sides+(j+1)%sides, (r+1)*sides+j))
    faces += [tuple(reversed(range(sides))), tuple((len(rings)-1)*sides+j for j in range(sides))]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, name, bone, mat)


def tube(name, points, radius, bone, mat=wood):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    spline = curve.splines.new('POLY')
    spline.points.add(len(points)-1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    return finish(obj, name, bone, mat)


# Chase's correction: subtly masculine, straight-waisted, compact hips.
# Keep joint centers and limb lengths fixed so existing animation still fits.
body_rings('Doll | pelvis', [(.91,.053,.048),(.925,.073,.056),(.96,.093,.063),(1.02,.113,.068),(1.10,.123,.069)], 'pelvis')
sphere('Doll | waist joint', (0,0,1.135), (.085,.050,.073), 'spine', wood)
torso = body_rings('Doll | torso shell', [(1.105,.123,.068),(1.17,.129,.071),(1.255,.143,.075),(1.31,.149,.076),(1.41,.165,.079),(1.46,.166,.078),(1.49,.157,.066)], 'spine')
# Blend this single shell over the original spine/chest bones without changing the rig.
chest_group = torso.vertex_groups.new(name='chest')
spine_group = torso.vertex_groups['spine']
for vertex in torso.data.vertices:
    chest_weight = max(0.0, min(1.0, (vertex.co.z - 1.235) / .09))
    if chest_weight:
        chest_group.add([vertex.index], chest_weight, 'REPLACE')
        spine_group.add([vertex.index], 1.0-chest_weight, 'REPLACE')
sphere('Doll | neck joint', (0,0,1.525), (.039,.035,.057), 'neck', wood)
body_rings('Doll | neck shell', [(1.49,.070,.042),(1.505,.056,.040),(1.545,.037,.033),(1.58,.036,.032)], 'neck')
sphere('Doll | neck upper joint', (0,0,1.605), (.036,.034,.035), 'head', wood)

# Blank oval head. Eye openings belong to a later mask or head study.
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, location=(0,0,1.716))
head_obj = bpy.context.object
head_obj.scale = (.096,.079,.145)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
for vertex in head_obj.data.vertices:
    if vertex.co.z < 0:
        vertex.co.x *= 1 + vertex.co.z * 1.8
finish(head_obj, 'Doll | integrated oval head', 'head', ivory)
points = []
for i in range(41):
    z = 1.588 + i * .266/40
    t = (z-1.716)/.145
    points.append((0, -.079*math.sqrt(max(0,1-t*t))-.001, z))
tube('Doll | head assembly seam', points, .00075, 'head', dark)
for i,z in enumerate([1.610,1.635,1.660,1.685,1.710,1.735,1.760,1.785,1.810,1.835]):
    y = -.079*math.sqrt(max(0,1-((z-1.716)/.145)**2))-.0015
    tube('Doll | face stitch %02d'%i, [(-.004,y,z-.001),(.004,y,z+.001)], .0011, 'head', wood)


# Dark stitches are individually weighted to each rigid torso section.
for section, bone, z0, z1, depth in [
    ('chest', 'chest', 1.33, 1.48, .078),
    ('abdomen', 'spine', 1.115, 1.235, .072),
    ('mid torso', 'spine', 1.235, 1.33, .075),
    ('pelvis', 'pelvis', .93, 1.095, .067),
]:
    tube('Doll | '+section+' seam', [(0,-depth-.001,z0),(0,-depth-.001,z1)], .00085, bone, dark)
    for i in range(5):
        z=z0+(z1-z0)*(i+.5)/5
        tube('Doll | %s stitch %02d'%(section,i), [(-.005,-depth-.002,z),(.005,-depth-.002,z)], .0011, bone, wood)

for side,sign in [('L',1),('R',-1)]:
    bones = rig.data.bones
    shoulder = bones['upper_arm.'+side].head_local.copy()
    elbow = bones['forearm.'+side].head_local.copy()
    wrist = bones['hand.'+side].head_local.copy()
    hip = bones['thigh.'+side].head_local.copy()
    knee = bones['shin.'+side].head_local.copy()
    ankle = bones['foot.'+side].head_local.copy()
    sphere('Doll | shoulder '+side, shoulder, (.056,.053,.056), 'upper_arm.'+side, dark)
    cylinder('Doll | shoulder inset '+side, shoulder+Vector((0,-.047,0)), .039,.015,(0,1,0),'upper_arm.'+side,wood)
    sphere('Doll | shoulder cap '+side, shoulder+Vector((sign*.030,0,.037)), (.075,.049,.032), 'upper_arm.'+side)
    spindle('Doll | upper arm '+side, shoulder.lerp(elbow,.12), shoulder.lerp(elbow,.89), .056,.047,'upper_arm.'+side)
    sphere('Doll | elbow pivot '+side, elbow, (.040,.040,.040), 'forearm.'+side, dark)
    cylinder('Doll | elbow front cap '+side, elbow+Vector((0,-.040,0)), .033,.012,(0,1,0),'forearm.'+side)
    cylinder('Doll | elbow peg '+side, elbow+Vector((0,-.048,0)), .010,.005,(0,1,0),'forearm.'+side,ivory)
    spindle('Doll | forearm '+side, elbow.lerp(wrist,.10), elbow.lerp(wrist,.91), .052,.044,'forearm.'+side)
    sphere('Doll | wrist pivot '+side, wrist, (.025,.025,.025), 'hand.'+side, wood)
    sphere('Doll | palm '+side, (sign*.816,.011,1.456), (.046,.052,.026), 'hand.'+side)
    for digit in ['thumb','index','middle','ring','pinky']:
        for segment in range(1,4):
            name = f'{digit}.{segment:02d}.{side}'
            bone = bones[name]
            radius = (.013 if digit == 'thumb' else .011) * (1-.08*(segment-1))
            a,b = bone.head_local, bone.tail_local
            sphere('Doll | knuckle '+name, a, (radius,radius,radius), name, wood,16,8)
            spindle('Doll | finger '+name, a.lerp(b,.12), a.lerp(b,.96), radius*.95,radius*.80,name)
    sphere('Doll | hip pivot '+side, hip, (.056,.058,.060), 'thigh.'+side, wood)
    spindle('Doll | thigh '+side, hip.lerp(knee,.09), hip.lerp(knee,.92), .074,.068,'thigh.'+side)
    sphere('Doll | knee pivot '+side, knee, (.051,.050,.049), 'shin.'+side, dark)
    cylinder('Doll | knee outer cap '+side,knee+Vector((sign*.049,0,0)),.040,.014,(1,0,0),'shin.'+side)
    cylinder('Doll | knee peg '+side,knee+Vector((sign*.059,0,0)),.012,.005,(1,0,0),'shin.'+side,ivory)
    sphere('Doll | kneecap '+side,knee+Vector((0,-.035,0)),(.040,.024,.037),'shin.'+side)
    spindle('Doll | shin '+side,knee.lerp(ankle,.11),knee.lerp(ankle,.92),.062,.054,'shin.'+side)
    sphere('Doll | ankle pivot '+side,ankle,(.031,.032,.032),'foot.'+side,wood)
    sphere('Doll | heel '+side,(sign*.14,.008,.060),(.058,.063,.060),'foot.'+side)
    spindle('Doll | foot instep '+side,(sign*.14,0,.065),(sign*.14,-.118,.050),.055,.038,'foot.'+side)
    sphere('Doll | forefoot '+side,(sign*.14,-.161,.041),(.067,.070,.037),'toe.'+side)
    for t in range(5):
        x = sign*(.097 + t*.022)
        y = -.221 + .006*abs(t-1)
        r = .015 if t < 2 else .014
        sphere('Doll | toe %s %d'%(side,t+1), (x,y,.024), (r,.023,.021), 'toe.'+side)
        cylinder('Doll | toe joint %s %d'%(side,t+1), (x,y+.009,.042), r*.68,.0018,(0,0,1),'toe.'+side,wood)


# Rotate the hand surfaces at rest so their palms face the front drawing.
# The pre-existing finger joints are unchanged; their exact grip fit requires review.
for side,sign in [('L',1),('R',-1)]:
    wrist=rig.data.bones['hand.'+side].head_local.copy()
    turn=Matrix.Rotation(-math.pi/2, 4, 'X')
    for obj in parts:
        if (obj.name.startswith('Doll | palm '+side) or
            obj.name.startswith('Doll | finger ') and obj.name.endswith('.'+side) or
            obj.name.startswith('Doll | knuckle ') and obj.name.endswith('.'+side)):
            inv=obj.matrix_world.inverted()
            for v in obj.data.vertices:
                v.co=inv @ (wrist + (turn.to_3x3() @ (obj.matrix_world @ v.co-wrist)))
            # Keep the posed hand coherent until its individual finger pivots are rebuilt.
            obj.vertex_groups.clear()
            vg=obj.vertex_groups.new(name='hand.'+side)
            vg.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
            bindings[obj.name]='hand.'+side
            rest=obj.data.attributes.get('DollRest')
            for v, val in zip(obj.data.vertices,rest.data):
                val.vector=obj.matrix_world @ v.co

# Check the unchanged source rig and the normalized body weights.
validation = []
def check(name, passed, detail=''):
    validation.append({'name':name,'passed':bool(passed),'detail':detail})
    if not passed:
        raise RuntimeError(name + ': ' + detail)

check('all 62 source bones retained', len(rig.data.bones)==62)
check('rest transforms unchanged',rest_before=={b.name:[list(row) for row in b.matrix_local] for b in rig.data.bones})
check('all 48 source actions unchanged',actions_before==action_digest())
check('all component bindings target existing bones',all(n in rig.data.bones for n in bindings.values()))
check('body weights are normalized',all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for o in parts for v in o.data.vertices))
check('blank head has no eye interiors',sum(o.name.startswith('Doll | eye interior') for o in parts)==0)
check('all 30 finger segments present',sum(o.name.startswith('Doll | finger') for o in parts)==30)
check('all geometry finite',all(math.isfinite(c) for o in parts for v in o.data.vertices for c in v.co))

scene = bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=16
scene.cycles.use_denoising=True
scene.render.resolution_x=1100
scene.render.resolution_y=1100
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.fps=24
scene.world=bpy.data.worlds.new('Study | gray studio')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.18,.21,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.55
floor_mat=material('Study | floor',(.075,.09,.11),.85)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.003))
floor=bpy.context.object
floor.name='Study | floor'
floor.data.materials.append(floor_mat)
for name,loc,power,size in [('key',(-3,-4,5),500,4),('fill',(3,-1,3),250,3),('rim',(1,3,4),450,3)]:
    data=bpy.data.lights.new('Study | '+name,'AREA')
    data.energy=power
    data.shape='DISK'
    data.size=size
    obj=bpy.data.objects.new(data.name,data)
    scene.collection.objects.link(obj)
    obj.location=loc
    obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat('-Z','Y').to_euler()
cam_data=bpy.data.cameras.new('Study | orthographic camera')
camera=bpy.data.objects.new(cam_data.name,cam_data)
scene.collection.objects.link(camera)
scene.camera=camera
cam_data.type='ORTHO'
cam_data.ortho_scale=2.05
scene.view_settings.view_transform='AgX'


def set_action(name, fraction):
    action=bpy.data.actions[name]
    rig.animation_data.action=action
    if action.slots:
        rig.animation_data.action_slot=action.slots[0]
    start,end=action.frame_range
    f=start+(end-start)*fraction
    scene.frame_set(int(f),subframe=f-int(f))
    bpy.context.view_layer.update()


def render(filename, angle='three_quarter'):
    positions=[]
    graph=bpy.context.evaluated_depsgraph_get()
    for o in parts:
        evaluated=o.evaluated_get(graph)
        positions += [evaluated.matrix_world @ Vector(c) for c in evaluated.bound_box]
    center=Vector(tuple((min(p[i] for p in positions)+max(p[i] for p in positions))/2 for i in range(3)))
    direction={'front':Vector((0,-6,0)), 'side':Vector((6,0,0)), 'back':Vector((0,6,0)), 'three_quarter':Vector((3,-6,1.5))}[angle]
    camera.location=center+direction
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(WORK/filename)
    bpy.ops.render.render(write_still=True)


for angle in ['front','side','back','three_quarter']:
    render('body_rest_'+angle+'.png',angle)
rig.data.pose_position='POSE'
samples=[('idle_4',.15),('run_1',.25),('attack_1',.50),('crouch_1',.85),('jump_1',.45),('grapple_swinging_1',.50)]
for name,fraction in samples:
    set_action(name,fraction)
    check('finite sampled pose: '+name,all(math.isfinite(v) for b in rig.pose.bones for row in b.matrix for v in row))
    check('rigid lengths: '+name,all(abs((b.matrix.to_3x3()@Vector((0,b.bone.length,0))).length-b.bone.length)<1e-4 for b in rig.pose.bones if b.bone.length>1e-5))
    render('pose_'+name+'.png')

set_action('idle_4',.15)
scene.frame_start=0
scene.frame_end=80
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
native=OUT/'Threadborne_Pale_Doll_Base_v3_final.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True)

# The editable file keeps semantic parts; only the export joins compatible surfaces.
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join()
body=bpy.context.object
body.name='Threadborne_Pale_Doll_Base_v3'
import sys
sys.path.insert(0, str(ROOT / 'tools/art'))
from bake_pale_doll_base_color import bake_base_color
bake_base_color(body)
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
export=OUT/'Threadborne_Pale_Doll_Base_v3_final.glb'
bpy.ops.export_scene.gltf(filepath=str(export),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False,export_materials='EXPORT')
check('source actions still unchanged after export',actions_before==action_digest())
report={
    'source':str(SOURCE.relative_to(ROOT)),
    'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'native':str(native.relative_to(ROOT)),
    'export':str(export.relative_to(ROOT)),
    'bones':len(rig.data.bones),'actions':list(actions_before),
    'revision':'v3: blank head and reference-informed mannequin shells',
    'rigid_parts':len(bindings),'bindings':bindings,
    'export_vertices':len(body.data.vertices),
    'export_triangles':sum(len(p.vertices)-2 for p in body.data.polygons),
    'checks':validation,
    'limitations':['Unclothed body study, not fitted modular clothing.','The GLB contains a baked color atlas; procedural bump remains native-only.','Source animations retained, but hands are rigidly bound as units; independent finger posing and equipment grip require a future rig and weighting pass.','No production player, equipment resource or gameplay scene is replaced.'],
}
(WORK/'body_test_report.json').write_text(json.dumps(report,indent=2))
print('DOLL_BODY_STUDY_COMPLETE',len(validation),'checks',report['export_triangles'],'triangles',flush=True)
