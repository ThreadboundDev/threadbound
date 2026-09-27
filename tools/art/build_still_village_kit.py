"""Build the twelve approved Still Village pieces and orthographic game renders.

Run with background Blender --factory-startup --threads 8 --python this_file.
All sources/exports are new; no existing Blender session or game scene is edited.
"""
import json
import math
import random
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'ArtSource/BlueBiome/Blender/StillVillage'
DEST = ROOT / 'Assets/BlueBiome/StillVillage'
for folder in [SOURCE, SOURCE/'models', DEST/'Structures', DEST/'Decoration']:
    folder.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=32
scene.cycles.use_denoising=True
scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
scene.view_settings.view_transform='Standard'
scene.view_settings.look='Medium High Contrast'
scene.world.color=(.23,.23,.23)
PPU=128
assets=[]
current=None

def mat(name,color,rough=.8):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=rough
    return m
wood=mat('Walnut | middle',(.24,.105,.047))
wood_light=mat('Walnut | cut edge',(.39,.22,.10))
wood_dark=mat('Walnut | recessed',(.10,.047,.021))
stone=mat('Slate | middle',(.08,.18,.26))
stone_light=mat('Slate | edge',(.23,.40,.47))
stone_dark=mat('Slate | recess',(.025,.073,.115))
rope=mat('Binding | restrained thread blue',(.09,.24,.28))
green=mat('Foliage | middle',(.08,.28,.085))
green_light=mat('Foliage | light',(.25,.46,.13))
green_dark=mat('Foliage | shadow',(.035,.15,.075))
pink=mat('Blossom | middle',(.67,.20,.39))
pink_light=mat('Blossom | light',(.90,.40,.58))
pink_dark=mat('Blossom | shadow',(.38,.075,.22))
cloth=mat('Cloth | parchment',(.70,.57,.37))

def asset(name,kind='Structures'):
    global current
    col=bpy.data.collections.new(name); scene.collection.children.link(col)
    root=bpy.data.objects.new(name+'_ROOT',None); col.objects.link(root)
    root['asset_id']=name; root['pixels_per_unit']=PPU
    current={'id':name,'kind':kind,'col':col,'root':root}
    assets.append(current)
    return root

def bind(obj,name,material):
    for col in list(obj.users_collection): col.objects.unlink(obj)
    current['col'].objects.link(obj)
    obj.name=name; obj.parent=current['root']; obj.data.materials.append(material)
    return obj

def box(name,loc,size,material,bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    ob=bind(bpy.context.object,name,material); ob.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=ob.modifiers.new('Small readable edges','BEVEL'); mod.width=bevel; mod.segments=1
        ob.modifiers.new('Weighted plane normals','WEIGHTED_NORMAL')
    return ob

def curve(name,points,width,material):
    data=bpy.data.curves.new(name,'CURVE'); data.dimensions='3D'; data.resolution_u=10
    data.bevel_depth=width; data.bevel_resolution=2
    sp=data.splines.new('BEZIER'); sp.bezier_points.add(len(points)-1)
    for p,co in zip(sp.bezier_points,points):
        p.co=co; p.handle_left_type='AUTO'; p.handle_right_type='AUTO'
    ob=bpy.data.objects.new(name,data); current['col'].objects.link(ob)
    ob.parent=current['root']; data.materials.append(material)
    return ob

def cylinder(name,loc,radius,depth,material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=radius,depth=depth,location=loc,rotation=(math.pi/2,0,0))
    return bind(bpy.context.object,name,material)

def mesh(name,verts,faces,material):
    data=bpy.data.meshes.new(name); data.from_pydata(verts,[],faces); data.update()
    ob=bpy.data.objects.new(name,data); current['col'].objects.link(ob)
    ob.parent=current['root']; data.materials.append(material)
    return ob

def binding(x,z,thickness=.34):
    for i in range(3):
        box('Rope band', (x,-.012,z+i*.042),(thickness,.45,.025),rope,.012)

def grain(x,z,length,y=-.225):
    for i in range(2):
        curve('Restrained wood grain',[(x,y,z+i*.045),(x+length*.4,y-.003,z+.01+i*.045),(x+length,y,z+i*.042)],.005,wood_dark)

for name,width in [('stone_cap_short',2),('stone_cap_long',4)]:
    asset(name)
    for i in range(int(width)):
        # Upper edge exactly z=0; sprite origin is the walkable left corner.
        box('Slate block', (i+.5,0,-.17),(.988,.55,.34),stone,.035)
        box('Readable contact lip',(i+.5,-.291,-.055),(.91,.025,.038),stone_light,.012)
        curve('Quiet stone split',[(i+.28,-.282,-.13),(i+.33,-.283,-.20),(i+.31,-.283,-.28)],.006,stone_dark)
    box('Separate timber backing',(width*.5,.1,-.40),(width-.06,.35,.13),wood,.025)
    for x in [.2,width-.2]: cylinder('Joinery pin',(x,-.095,-.40),.037,.025,wood_light)

asset('timber_deck')
for i in range(4):
    box('Deck plank',(i+.5,0,-.16),(.986,.55,.32),wood,.025)
    grain(i+.10,-.10,.72,y=-.281)
box('Deck bearer',(2,.08,-.39),(3.85,.37,.12),wood_dark)
for x in [.25,3.75]: cylinder('Wood dowel',(x,-.29,-.19),.035,.025,wood_light)

asset('curved_brace')
box('Mount post',(.12,.09,-1.05),(.24,.4,2.1),wood)
box('Top bearer',(1,.08,-.10),(2.15,.42,.20),wood)
curve('Arched load brace',[(.2,0,-1.55),(.45,0,-.86),(1.02,0,-.4),(1.92,0,-.16)],.13,wood_light)
binding(.12,-1.1,.29)
for x,z in [(.13,-.27),(1.85,-.12)]: cylinder('Round joint',(x,-.23,z),.063,.035,wood_dark)

asset('support_post')
box('Main post',(0,0,-1.5),(.36,.40,3),wood,.04)
box('Mount socket',(.37,0,-.52),(.42,.40,.28),wood_light,.035)
cylinder('Socket recess',(.43,-.21,-.52),.072,.025,wood_dark)
binding(0,-2.28,.40); grain(-.10,-1.65,.19)

asset('bulb_hanger')
box('Hanger upright',(.10,0,-.45),(.28,.42,1.2),wood)
curve('Curved hanger beam',[(.11,0,.10),(.56,0,.53),(1.33,0,.86),(2.20,0,1.03)],.12,wood)
curve('Beam edge',[(.10,-.10,.15),(.56,-.11,.58),(1.33,-.11,.91),(2.2,-.1,1.08)],.014,wood_light)
for dx in [0,.06,.12]: box('Tip binding',(1.92+dx,0,.97),(.035,.30,.32),rope,.014)
curve('Separate living attachment',[(2.04,-.10,.90),(2.00,-.13,.70),(2.10,-.13,.58),(2.02,-.13,.50)],.027,green)
current['root']['bulb_socket']=[2.02,-.13,.50]

asset('dry_channel')
box('Trough base',(1.5,0,-.44),(3,.60,.13),wood)
box('Trough rear',(1.5,.27,-.22),(3,.12,.44),wood_light)
box('Trough front',(1.5,-.27,-.30),(3,.12,.28),wood)
for x in [.05,2.95]: box('End stop',(x,0,-.22),(.10,.60,.44),wood_light)
for x in [.4,2.6]:
    box('Trough foot',(x,0,-.59),(.24,.50,.21),wood_dark)
    box('External binding',(x,-.342,-.30),(.04,.025,.31),rope,.008)
grain(.2,-.30,2.6,y=-.335)

asset('stopped_waterwheel')
bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=8,location=(0,0,0),rotation=(math.pi/2,0,0),major_radius=1.3,minor_radius=.13)
bind(bpy.context.object,'Complete wheel rim',wood)
for i in range(8):
    a=i*math.tau/8
    spoke=box('Wheel spoke',(math.cos(a)*.7,0,math.sin(a)*.7),(1.35,.22,.15),wood_light)
    spoke.rotation_euler.y=-a
    paddle=box('Broad paddle',(math.cos(a)*1.55,0,math.sin(a)*1.55),(.42,.40,.58),wood)
    paddle.rotation_euler.y=-a
cylinder('Central wooden hub',(0,-.19,0),.26,.28,wood_light)
cylinder('Stationary axle socket',(0,-.34,0),.13,.025,wood_dark)
current['root']['optional_motion_axis']='local Y; static in still-water preview'

asset('shore_stone')
rng=random.Random(73)
for x,z,w,h in [(.7,-.63,1.4,1.26),(2.0,-.9,1.2,.90),(3.25,-1.12,1.3,.45)]:
    box('Shore plane',(x,.10,z),(w,.95,h),stone,.12)
    box('Cool upper plane',(x,-.395,z+h*.5-.10),(w*.80,.025,.04),stone_light,.012)

asset('grass_clump','Decoration')
for i in range(13):
    x=rng.uniform(-.48,.48); height=rng.uniform(.38,.85)
    lean=rng.uniform(-.45,.45); width=rng.uniform(.07,.16)
    verts=[]
    for j in range(13):
        t=j/12; mid=x+lean*t*t; z=height*t
        spread=width*math.sin(math.pi*t)**.75
        verts.extend([(mid-spread,-.10-i*.002,z),(mid,-.14-i*.002,z+.025*math.sin(math.pi*t)),(mid+spread,-.10-i*.002,z)])
    faces=[]
    for j in range(12):
        k=j*3; faces.extend([(k,k+3,k+4,k+1),(k+1,k+4,k+5,k+2)])
    mesh('Soft leaf',verts,faces,[green,green_light,green_dark][i%3])

asset('cherry_cluster','Decoration')
curve('Branch skeleton',[(-1.4,.12,.15),(-.6,.10,.34),(.1,.1,.40),(1.4,.13,.7)],.045,wood_dark)
for i in range(48):
    a=rng.uniform(0,math.tau); r=math.sqrt(rng.random())
    x=math.cos(a)*1.5*r; z=.60+math.sin(a)*.53*r
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=rng.uniform(.16,.27),location=(x,rng.uniform(-.20,.12),z))
    ob=bind(bpy.context.object,'Grouped blossom',[pink,pink_light,pink_dark][i%3])
    ob.scale=(1.0,.6,.85)
    for polygon in ob.data.polygons:
        polygon.use_smooth=True

asset('cloth_awning','Decoration')
curve('Curved awning rod',[(-1.4,0,.06),(-.70,0,-.04),(0,0,-.07),(.70,0,-.04),(1.4,0,.06)],.065,wood)
verts=[]; faces=[]
for i in range(33):
    u=i/32; x=(u-.5)*2.6
    for j in range(13):
        v=j/12
        z=-.06-.09*math.sin(math.pi*u)-v*(.60+.40*math.sin(math.pi*u))
        y=-.03-.07*math.sin(u*math.pi*8)*math.sin(v*math.pi*.8)
        verts.append((x,y,z))
for i in range(32):
    for j in range(12):
        k=i*13+j; faces.append((k,k+1,k+14,k+13))
ob=mesh('Still parchment cloth',verts,faces,cloth)
solid=ob.modifiers.new('Cloth thickness','SOLIDIFY'); solid.thickness=.008
for x in [-1.3,1.3]: curve('Cloth tie',[(x,-.06,.12),(x,-.10,-.08),(x,-.11,-.5)],.025,rope)

# Neutral studio, deliberately no floor or cast-shadow plane.
studio=bpy.data.collections.new('STUDIO'); scene.collection.children.link(studio)
def area(name,pos,energy,size):
    data=bpy.data.lights.new(name,'AREA'); data.energy=energy; data.size=size
    ob=bpy.data.objects.new(name,data); studio.objects.link(ob); ob.location=pos
    ob.rotation_euler=(Vector((0,0,0))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Neutral key',(-3,-4,5),420,5)
area('Neutral fill',(3,-3,1),170,5)
camdata=bpy.data.cameras.new('Game orthographic camera'); camdata.type='ORTHO'
camera=bpy.data.objects.new('Game orthographic camera',camdata); studio.objects.link(camera); scene.camera=camera
manifest=[]
for entry in assets:
    for other in assets: other['col'].hide_render=other is not entry
    bpy.context.view_layer.update()
    deps=bpy.context.evaluated_depsgraph_get()
    corners=[]
    for ob in entry['col'].objects:
        if ob.type in {'MESH','CURVE'}:
            ev=ob.evaluated_get(deps)
            corners.extend(ev.matrix_world@Vector(c) for c in ev.bound_box)
    left=min(v.x for v in corners)-.13; right=max(v.x for v in corners)+.13
    bottom=min(v.z for v in corners)-.13; top=max(v.z for v in corners)+.13
    width=math.ceil((right-left)*PPU/8)*8; height=math.ceil((top-bottom)*PPU/8)*8
    # Exact 128 pixels/unit; padding absorbs integer rounding at the right/bottom.
    world_w=width/PPU; world_h=height/PPU
    center=Vector((left+world_w/2,0,top-world_h/2))
    camera.location=(center.x,-10,center.z); camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    # Blender's orthographic scale uses the larger image dimension.
    camdata.ortho_scale=max(world_w,world_h)
    scene.render.resolution_x=width; scene.render.resolution_y=height; scene.render.resolution_percentage=100
    target=DEST/entry['kind']/(entry['id']+'.png')
    scene.render.filepath=str(target); bpy.ops.render.render(write_still=True)
    manifest.append({'id':entry['id'],'kind':entry['kind'],'texture':str(target.relative_to(ROOT)).replace('\\','/'),
        'canvas':[width,height],'origin_px':[-left*PPU,top*PPU],
        'bounds_units':[left,bottom,right,top],'pixels_per_unit':PPU})
    print('KIT_RENDER',entry['id'],width,height,flush=True)

# Save editable curves and modifiers, then export portable meshes separately.
for index,entry in enumerate(assets):
    entry['col'].hide_render=False
    entry['root'].location=(index%4*6,0,-(index//4)*5)
scene.camera.location=(9,-25,-4); scene.camera.rotation_euler=(math.pi/2,0,0)
camdata.ortho_scale=26
scene.render.resolution_x=1800; scene.render.resolution_y=1200
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'StillVillage_Kit_v1.blend'))
for entry in assets:
    entry['root'].location=(0,0,0)
    for ob in list(entry['col'].objects):
        if ob.type=='CURVE':
            bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); bpy.context.view_layer.objects.active=ob
            bpy.ops.object.convert(target='MESH')
    bpy.ops.object.select_all(action='DESELECT')
    for ob in entry['col'].objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=entry['root']
    bpy.ops.export_scene.gltf(filepath=str(SOURCE/'models'/(entry['id']+'.glb')),use_selection=True,export_format='GLB',export_animations=False,export_apply=True)
(DEST/'kit_manifest.json').write_text(json.dumps(manifest,indent=2))
(SOURCE/'kit_manifest.json').write_text(json.dumps(manifest,indent=2))
print('STILL_VILLAGE_KIT_COMPLETE',len(manifest),flush=True)
