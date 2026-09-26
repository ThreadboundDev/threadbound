"""Build the Hanging Bell water bulb in background Blender; no live file edits.

blender --background --factory-startup --python tools/art/build_water_bulb.py
Pass -- --preview-only to render the hero without the animation frames.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'ArtSource/BlueBiome/Blender/WaterBulb'
FRAMES = OUT / 'frames'
OUT.mkdir(parents=True, exist_ok=True)
FRAMES.mkdir(exist_ok=True)
TAU = math.tau
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x = 600
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.fps = 24
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.film_transparent = True
scene.render.use_file_extension = True
scene.render.image_settings.color_depth = '8'
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'Medium High Contrast'
scene.world.color = (.18, .18, .18)
scene.frame_start = 1
scene.frame_end = 72
bpy.context.preferences.filepaths.save_version = 0

def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result

MODEL = collection('BULB | separate editable parts')
STUDIO = collection('STUDIO | excluded from model export')

def move_to(obj, target=MODEL):
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    target.objects.link(obj)
    return obj

def empty(name, location=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    MODEL.objects.link(obj)
    obj.location = location
    obj.parent = parent
    return obj

root = empty('WaterBulb_ROOT')
root['design'] = 'Hanging Bell A — Trapped Flowing Water'
root['states'] = 'RUSH 1–24 (loop); POP 25–36; SPENT 37–42; REFILL 43–72'
root['gameplay'] = 'Melee recoil; dash carry + lift; remote pop without launch'
water_root = empty('WATER_AND_MEMBRANE', parent=root)
flower_root = empty('FLOWER_calyx_and_petals', (0, 0, 1.05), root)
flow_root = empty('FLOW_rushing_current', parent=water_root)
droplet_root = empty('POP_released_water', parent=root)

def material(name, color, roughness=.45, metallic=0.0, alpha=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, alpha)
    p = mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    p.inputs['Alpha'].default_value = alpha
    if alpha < 1:
        mat.surface_render_method = 'DITHERED'
    return mat

green = material('Stem | blue green', (.035, .23, .135), .48)
green_light = material('Calyx | living green', (.14, .39, .13), .45)
pink = material('Petals | muted blossom pink', (.66, .19, .34), .43)
pink_edge = material('Petal ridges | light rose', (.83, .37, .49), .4)
water = material('Water | cyan body', (.025, .43, .57), .30, .03)
wp = water.node_tree.nodes.get('Principled BSDF')
wp.inputs['Coat Weight'].default_value = .35
wp.inputs['Coat Roughness'].default_value = .16
shell = material('Membrane | thin clear cyan', (.12, .64, .74), .16, .0, .09)
shell.node_tree.nodes.get('Principled BSDF').inputs['Coat Weight'].default_value = .5
foam = material('Current | pale turquoise', (.14, .61, .70), .32)
deep_flow = material('Current | deep blue', (.018, .25, .38), .32)
glint = material('Membrane | small surface glints', (.72, .95, .95), .18)
navy = material('Contour | deep blue', (.012, .065, .095), .65)

def mesh_obj(name, vertices, faces, mat, parent=root):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    MODEL.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj

def sphere(name, center, scale, mat, parent=root, segments=48, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=center)
    obj = move_to(bpy.context.object)
    obj.name = name
    obj.scale = scale
    obj.parent = parent
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj

def curve(name, coords, radius, mat, parent=root):
    data = bpy.data.curves.new(name, 'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 16
    data.bevel_depth = radius
    data.bevel_resolution = 3
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(coords)-1)
    for point, co in zip(spline.bezier_points, coords):
        point.co = co
        point.handle_left_type = 'AUTO'
        point.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new(name, data)
    MODEL.objects.link(obj)
    obj.parent = parent
    data.materials.append(mat)
    return obj

stem_points = [(0, .06, 1.05), (-.1, .07, 1.49), (-.53, .09, 1.83), (-1.1, .09, 1.94), (-1.43, .10, 2.12), (-1.5, .11, 2.33)]
stem = curve('STEM | quiet arch', stem_points, .074, green)
curve('Stem highlight ridge', [(x-.015, y-.068, z+.018) for x,y,z in stem_points], .017, green_light)
curve('Stem curled tendril', [(-.53,.04,1.83),(-.92,.0,1.65),(-1.02,-.02,1.43),(-.89,-.04,1.34),(-.78,-.04,1.43),(-.86,-.04,1.49)], .027, green)
sphere('CALYX | crown', (0, 0, .005), (.29,.23,.18), green_light, flower_root)

def petal(name, angle, length, width, mat, green_sepal=False):
    vertices=[]
    faces=[]
    count=24
    across=8
    for i in range(count+1):
        t=i/count
        radius=.15+length*math.sin(t*math.pi/2)
        z=-.01-(.55 if not green_sepal else .23)*t
        z+=(.39 if not green_sepal else .0)*t**6
        span=width*math.sin(math.pi*t)**.52 + .003
        for j in range(across+1):
            u=2*j/across-1
            tangent=span*u
            raised=.085*(1-u*u)*math.sin(math.pi*t)
            vertices.append((math.cos(angle)*radius-math.sin(angle)*tangent,
                             math.sin(angle)*radius+math.cos(angle)*tangent,
                             z+raised))
    for i in range(count):
        for j in range(across):
            a=i*(across+1)+j
            faces.append((a,a+1,a+across+2,a+across+1))
    obj=mesh_obj(name,vertices,faces,mat,flower_root)
    solid=obj.modifiers.new('Thin living petal', 'SOLIDIFY')
    solid.thickness=.025
    bevel=obj.modifiers.new('Soft petal rim', 'BEVEL')
    bevel.width=.016
    bevel.segments=2
    return obj

petals=[]
for i in range(5):
    angle=-math.pi/2+i*TAU/5
    petals.append(petal('PETAL_%02d | pink bell skirt'%i,angle,.96,.24,pink))
    petal('SEPAL_%02d | green crown'%i,angle,.58,.16,green_light,True)
    # A slender central ridge makes each petal's volume legible at game scale.
    points=[]
    for j in range(8):
        t=j/9
        r=.15+.96*math.sin(t*math.pi/2)
        z=-.01-.55*t+.39*t**6+.085*math.sin(math.pi*t)+.015
        points.append((math.cos(angle)*r,math.sin(angle)*r,z))
    curve('Petal vein %02d'%i,points,.009,pink_edge,flower_root)

body=sphere('WATER | contained volume',(0,0,-.01),(.91,.60,.98),water,water_root)
membrane=sphere('MEMBRANE | elastic shell',(0,0,0),(.95,.70,1.02),shell,water_root)

# Current ribbons are actual geometry on an inner ellipsoidal surface. Their
# rotations carry visible foam past the same fixed flower, rather than wobbling
# the entire prop. Detached arcs and travelling bubbles imply a fast vortex.
def ribbon(name, radius, phase, arc, width, mat, tilt):
    verts=[]
    faces=[]
    for i in range(81):
        t=i/80
        a=phase+arc*t
        taper=max(.03, math.sin(math.pi*t)**.8)
        for side in [-1,1]:
            r=radius*(1+.04*math.sin(a*2.5+phase))+side*width*taper
            x=r*math.cos(a)
            z=r*math.sin(a)
            y=-.64*math.sqrt(max(.02,1-(x/.95)**2-(z/1.02)**2))-.055
            verts.append((x,y,z))
        if i:
            k=i*2
            faces.append((k-2,k-1,k+1,k))
    obj=mesh_obj(name,verts,faces,mat,flow_root)
    obj.rotation_euler[1]=tilt
    return obj

currents=[]
for i,(r,ph,arc,w,mat) in enumerate([
    (.76,.25,3.9,.032,foam),(.57,2.4,3.7,.024,foam),
    (.34,4.8,3.6,.020,foam),(.83,4.3,1.8,.022,deep_flow)]):
    currents.append(ribbon('FLOW ribbon %02d'%i,r,ph,arc,w,mat,0))

bubbles=[]
for i in range(10):
    r=.37+.042*i
    angle=i*2.39996
    size=.021+(i%3)*.009
    obj=sphere('FLOW bubble %02d'%i,(0,0,0),(size,size,size*1.15),glint,flow_root,16,8)
    bubbles.append((obj,r,angle))

# Highlight patches stay fixed to the membrane while the current rushes past.
curve('MEMBRANE | long glint',[(.49,-.54,.69),(.60,-.57,.57),(.65,-.57,.43)],.023,glint,water_root)
curve('MEMBRANE | low glint',[(-.65,-.50,-.44),(-.57,-.53,-.61),(-.42,-.53,-.75)],.012,foam,water_root)
refill_stream=curve('REFILL | winding inlet',[(0,-.22,1.13),(-.05,-.32,.98),(.06,-.43,.81),(-.04,-.50,.63)],.024,foam,water_root)

# An orthographic outline is a separate removable render layer, not a solid
# cage around the water. It is excluded from the glTF export below.
outline=curve('RENDER_ONLY | membrane contour',[(.952*math.cos(i*TAU/64),-.705,1.023*math.sin(i*TAU/64)) for i in range(65)],.009,navy,water_root)
outline['render_only']=True

droplets=[]
for i in range(9):
    angle=i*TAU/9+.12
    obj=sphere('POP droplet %02d'%i,(0,0,0),(.001,.001,.001),foam,droplet_root,20,12)
    droplets.append((obj,angle))

def keyed(obj, path, value, frame):
    setattr(obj,path,value)
    obj.keyframe_insert(data_path=path,frame=frame)

for frame in range(1,74):
    # A 24-frame seamless current loop; same current speed resumes during refill.
    phase=(frame-1)/24*TAU
    for i,obj in enumerate(currents):
        keyed(obj,'rotation_euler',(0,phase*(1 if i%2==0 else 2),0),frame)
    for obj,r,a in bubbles:
        a+=phase*2
        x=r*math.cos(a); z=r*math.sin(a)
        y=-.64*math.sqrt(max(.02,1-(x/.95)**2-(z/1.02)**2))-.074
        keyed(obj,'location',(x,y,z),frame)
    if frame<=24:
        scale=(1+.009*math.sin(phase*2),1,1-.006*math.sin(phase*2))
        zoffset=0
    elif frame<=28:
        t=(frame-24)/4
        scale=(1+.13*t,1+.08*t,1-.07*t)
        zoffset=0
    elif frame<=32:
        t=(frame-28)/4
        s=max(.001,1-t)
        scale=(1.13*s,1.08*s,.93*s)
        zoffset=(1-s)*.98
    elif frame<=42:
        scale=(.001,.001,.001); zoffset=.98
    else:
        t=min(1,(frame-42)/30)
        s=.03+.97*(t*t*(3-2*t))
        scale=(s,s,s); zoffset=(1-s)*.98
    keyed(water_root,'scale',scale,frame)
    keyed(water_root,'location',(0,0,zoffset),frame)
    stream_scale=1.0 if 43<=frame<=68 else .001
    keyed(refill_stream,'scale',(stream_scale,stream_scale,stream_scale),frame)
    # Tiny ready-state pressure twitch; visible snap only during release.
    twitch=.008*math.sin(phase*2) if frame<=24 else 0
    snap=.16*math.sin((frame-25)/11*math.pi) if 25<=frame<=36 else 0
    keyed(flower_root,'rotation_euler',(0,twitch+snap,0),frame)
    for i,(obj,a) in enumerate(droplets):
        t=(frame-28)/12
        if 0<=t<=1:
            radius=.45+1.25*t
            pos=(math.cos(a)*radius,-.15+math.sin(i)*.20,math.sin(a)*radius-.9*t*t)
            size=.10*(1-.75*t)
            keyed(obj,'location',pos,frame)
            keyed(obj,'scale',(size*.62,size*.62,size*1.7),frame)
            keyed(obj,'rotation_euler',(0,math.pi/2-a,0),frame)
        else:
            keyed(obj,'scale',(.001,.001,.001),frame)

for f,name in [(1,'RUSH_LOOP_START'),(24,'RUSH_LOOP_END'),(25,'POP_START'),(36,'POP_END'),(37,'SPENT'),(43,'REFILL_START'),(72,'REFILL_END')]:
    scene.timeline_markers.new(name,frame=f)

def area(name, pos, energy, size, color):
    data=bpy.data.lights.new(name,'AREA'); data.energy=energy; data.shape='DISK'; data.size=size; data.color=color
    obj=bpy.data.objects.new(name,data); STUDIO.objects.link(obj); obj.location=pos
    obj.rotation_euler=(Vector((0,0,.5))-obj.location).to_track_quat('-Z','Y').to_euler()

area('Key | neutral',(-3,-4,5),430,4,(.90,.96,1))
area('Fill | soft',(3,-2,1),150,3,(.72,.90,1))
area('Rim | restrained',(1,2,3),300,3,(.67,.85,1))
cam_data=bpy.data.cameras.new('Orthographic_Game_Camera')
cam=bpy.data.objects.new('Orthographic_Game_Camera',cam_data)
STUDIO.objects.link(cam)
cam.location=(-.15,-10,.67)
cam.rotation_euler=(Vector((-.15,0,.67))-cam.location).to_track_quat('-Z','Y').to_euler()
cam_data.type='ORTHO'; cam_data.ortho_scale=4.5
scene.camera=cam
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'WaterBulb_HangingBell_v1.blend'))

# glTF provides a portable editable model with transform animation. Complex
# material rendering should still be judged in the Blender source/renders.
bpy.ops.object.select_all(action='DESELECT')
for obj in list(MODEL.objects):
    if obj.type=='CURVE' and not obj.get('render_only'):
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        bpy.ops.object.convert(target='MESH')
for obj in MODEL.objects:
    obj.select_set(not bool(obj.get('render_only')))
bpy.context.view_layer.objects.active=root
bpy.ops.export_scene.gltf(filepath=str(OUT/'WaterBulb_HangingBell_v1.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='SCENE',export_anim_scene_split_object=False,export_nla_strips_merged_animation_name='Bulb_Lifecycle',export_frame_range=True,export_force_sampling=True)

manifest={'asset':'Hanging Bell A','fps':24,'canvas':[600,800],
          'states':{'rush':[1,24],'pop':[25,36],'spent':[37,42],'refill':[43,72]},
          'notes':'3D authored animation; no fluid simulation. Orthographic contour is render-only. glTF uses one timeline; split per marker ranges in engine.'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
if '--export-only' in sys.argv:
    print('WATER_BULB_EXPORT_COMPLETE',flush=True)
    sys.exit(0)
scene.frame_set(1)
scene.render.filepath=str(OUT/'water_bulb_hero.png')
bpy.ops.render.render(write_still=True)
print('WATER_BULB_HERO_READY',flush=True)
if '--preview-only' not in sys.argv:
    scene.render.resolution_percentage=60
    scene.cycles.samples=12
    for frame in range(1,73):
        scene.frame_set(frame)
        scene.render.filepath=str(FRAMES/('%03d.png'%frame))
        bpy.ops.render.render(write_still=True)
        print('WATER_BULB_FRAME',frame,flush=True)
print('WATER_BULB_COMPLETE',flush=True)
