"""Bake two concept views to an editable UV atlas; preserve imported world geometry."""
from pathlib import Path
import hashlib
import json
import math
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

D = Path(__file__).resolve().parent
ROOT = D.parents[1]
REF = ROOT / 'work/bellstriker-generation-references-2026-11-09'
SIZE = 4096
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(D / 'source_untextured.fbx'))
objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
assert len(objects) == 1
o = objects[0]
o.name = 'Bellstriker_Painted_Comparison'
bpy.context.view_layer.objects.active = o
o.select_set(True)
before = np.array([tuple(o.matrix_world @ v.co) for v in o.data.vertices])
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
m = o.data
m.calc_loop_triangles()
coords = np.array([tuple(v.co) for v in m.vertices])
assert np.max(np.abs(before-coords)) < 1e-6
lo, hi = coords.min(axis=0), coords.max(axis=0)
span = hi-lo

# The delivered FBX has no UVs. Retain geometry and create only a texture unwrap.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.008)
bpy.ops.object.mode_set(mode='OBJECT')
atlas_uv = m.uv_layers.active
atlas_uv.name = 'PaintedAtlasUV'

def padded_reference(filename):
    """Extend silhouette colors into a padding band to avoid projecting white fringes."""
    image = bpy.data.images.load(str((D if filename=='side_paint_guide.png' else REF) / filename))
    w,h = image.size
    pixels = np.array(image.pixels[:],dtype=np.float32).reshape(h,w,4)
    rgb = pixels[:,:,:3]
    mask = ((rgb.max(axis=2)-rgb.min(axis=2))>.055) | (rgb.max(axis=2)<.30)
    ys,xs = np.where(mask)
    bounds = (int(xs.min()),int(xs.max()),int(ys.min()),int(ys.max()))
    valid = mask.copy()
    padded = pixels.copy()
    padded[~mask,:3] = (.12,.20,.32)
    # Expand the nearest colored region without pulling light-gray background inward.
    for _ in range(72):
        old = valid.copy()
        total = np.zeros_like(rgb)
        count = np.zeros((h,w),dtype=np.float32)
        for axis,shift in [(0,1),(0,-1),(1,1),(1,-1)]:
            ok = np.roll(old,shift,axis=axis)
            if axis==0: ok[0 if shift==1 else -1,:]=False
            else: ok[:,0 if shift==1 else -1]=False
            total += np.roll(padded[:,:,:3],shift,axis=axis)*ok[:,:,None]
            count += ok
        add = (~old)&(count>0)
        padded[add,:3] = total[add]/count[add,None]
        valid |= add
    padded[:,:,3]=1
    out = bpy.data.images.new(filename+'_projection_padding',width=w,height=h,alpha=False)
    out.colorspace_settings.name='sRGB'
    out.pixels.foreach_set(padded.ravel())
    out.pack()
    return out,bounds

front,front_bounds=padded_reference('bellstriker_front_v1.png')
back,back_bounds=padded_reference('bellstriker_back_v1.png')
side,side_bounds=padded_reference('side_paint_guide.png')
for name,image,bounds,reverse in [('FrontProjection',front,front_bounds,False),('BackProjection',back,back_bounds,True)]:
    layer=m.uv_layers.new(name=name)
    xmin,xmax,ymin,ymax=bounds
    for loop in m.loops:
        x,y,z=coords[loop.vertex_index]
        u=(x-lo[0])/span[0]
        if reverse:u=1-u
        v=(z-lo[2])/span[2]
        layer.data[loop.index].uv=((xmin+u*(xmax-xmin))/image.size[0],(ymin+v*(ymax-ymin))/image.size[1])
layer=m.uv_layers.new(name='SideProjection')
xmin,xmax,ymin,ymax=side_bounds
for loop in m.loops:
    x,y,z=coords[loop.vertex_index]
    u=(y-lo[1])/span[1];v=(z-lo[2])/span[2]
    layer.data[loop.index].uv=((xmin+u*(xmax-xmin))/side.size[0],(ymin+v*(ymax-ymin))/side.size[1])

# Front and rear colors meet around the local thickness of each limb, rather than
# a single plane through the whole animal. Ray casts find that local thickness.
bvh=BVHTree.FromPolygons([Vector(v) for v in coords],[tuple(p.vertices) for p in m.polygons])
weights=m.color_attributes.new(name='FrontBackBlend',type='FLOAT_COLOR',domain='POINT')
side_weights=m.color_attributes.new(name='SideBlend',type='FLOAT_COLOR',domain='POINT')
for v in m.vertices:
    x,y,z=v.co
    f=bvh.ray_cast(Vector((x,-2,z)),Vector((0,1,0)),4)[0]
    b=bvh.ray_cast(Vector((x,2,z)),Vector((0,-1,0)),4)[0]
    t=(y-f.y)/(b.y-f.y) if f is not None and b is not None and b.y-f.y>.0001 else (v.normal.y+1)/2
    t=max(0,min(1,(t-.20)/.60));t=t*t*(3-2*t)
    weights.data[v.index].color=(t,t,t,1)
    # Use the side guide only on side-facing surfaces visible to that camera.
    direction=1 if x>=0 else -1
    hit=bvh.ray_cast(Vector((direction*2,y,z)),Vector((-direction,0,0)),4)[0]
    visible=hit is not None and abs(hit.x-x)<.015
    side_factor=max(0,min(1,(abs(v.normal.x)-.35)/.50))
    side_factor=side_factor*side_factor*(3-2*side_factor)
    if not visible:side_factor*=.12
    side_weights.data[v.index].color=(side_factor,side_factor,side_factor,1)

mat=bpy.data.materials.new('Bellstriker_Navy_Ivory_Gold_Coral')
mat.use_nodes=True
m.materials.clear();m.materials.append(mat)
n=mat.node_tree.nodes;l=mat.node_tree.links;n.clear()
out=n.new('ShaderNodeOutputMaterial')
bs=n.new('ShaderNodeBsdfPrincipled')
bs.inputs['Roughness'].default_value=.48
bs.inputs['Specular IOR Level'].default_value=.28
sources=[]
for name,image in [('FrontProjection',front),('BackProjection',back)]:
    uv=n.new('ShaderNodeUVMap');uv.uv_map=name
    tex=n.new('ShaderNodeTexImage');tex.image=image;tex.extension='EXTEND'
    l.new(uv.outputs['UV'],tex.inputs['Vector']);sources.append(tex)
attribute=n.new('ShaderNodeVertexColor');attribute.layer_name='FrontBackBlend'
mix=n.new('ShaderNodeMixRGB');l.new(attribute.outputs['Color'],mix.inputs[0])
l.new(sources[0].outputs['Color'],mix.inputs[1]);l.new(sources[1].outputs['Color'],mix.inputs[2])
uv=n.new('ShaderNodeUVMap');uv.uv_map='SideProjection'
side_tex=n.new('ShaderNodeTexImage');side_tex.image=side;side_tex.extension='EXTEND';l.new(uv.outputs['UV'],side_tex.inputs['Vector'])
side_attr=n.new('ShaderNodeVertexColor');side_attr.layer_name='SideBlend'
side_mix=n.new('ShaderNodeMixRGB');l.new(side_attr.outputs['Color'],side_mix.inputs[0]);l.new(mix.outputs[0],side_mix.inputs[1]);l.new(side_tex.outputs['Color'],side_mix.inputs[2])
em=n.new('ShaderNodeEmission');l.new(side_mix.outputs[0],em.inputs['Color']);l.new(em.outputs[0],out.inputs['Surface'])
atlas=bpy.data.images.new('Bellstriker_BaseColor_4K',width=SIZE,height=SIZE,alpha=False)
atlas.colorspace_settings.name='sRGB'
target=n.new('ShaderNodeTexImage');target.image=atlas;n.active=target
m.uv_layers.active=atlas_uv;atlas_uv.active_render=True
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=1;s.render.bake.margin=16
bpy.ops.object.bake(type='EMIT')
atlas.filepath_raw=str(D/'Bellstriker_BaseColor_4K.png');atlas.file_format='PNG';atlas.save()
for node in list(n):
    if node not in (out,bs,target):n.remove(node)
l.new(target.outputs['Color'],bs.inputs['Base Color']);l.new(bs.outputs[0],out.inputs['Surface'])
for layer in list(m.uv_layers):
    if layer.name!='PaintedAtlasUV':m.uv_layers.remove(layer)
m.color_attributes.remove(weights)
m.color_attributes.remove(side_weights)
atlas.pack()

# Studio review uses the same camera/light recipe for all color views.
center=Vector((lo+hi)/2);scale=max(span)
s.world=bpy.data.worlds.new('Neutral studio');s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.35,.40,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
for name,delta,power in [('Key',(-1,-2,3),55),('Fill',(2,-1,1),30),('Rim',(1,2,2),45)]:
    data=bpy.data.lights.new(name,'AREA');data.energy=power*scale**2;data.shape='DISK';data.size=scale*2
    ob=bpy.data.objects.new(name,data);s.collection.objects.link(ob)
    ob.location=center+Vector(delta)*scale;ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler()
cam=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));s.collection.objects.link(cam);s.camera=cam
cam.data.type='ORTHO';cam.data.ortho_scale=scale*1.13
s.render.resolution_x=1536;s.render.resolution_y=1152;s.render.resolution_percentage=100
s.cycles.samples=32;s.cycles.use_denoising=True;s.view_settings.view_transform='Standard'
s.render.film_transparent=False
for name,delta in [('front',(0,-4,0)),('back',(0,4,0)),('three_quarter',(2,-4,.6)),('side',(4,0,0))]:
    cam.location=center+Vector(delta)*scale;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(D/('preview_'+name+'.png'));bpy.ops.render.render(write_still=True)
cam.location=center+Vector((2,-4,.6))*scale;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(D/'Bellstriker_Painted_v1.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(D/'Bellstriker_Painted_v1.glb'),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
report=dict(source_sha256=hashlib.sha256((D/'source_untextured.fbx').read_bytes()).hexdigest(),vertices=len(m.vertices),triangles=len(m.loop_triangles),geometry_world_max_error=float(np.max(np.abs(before-coords))),uv_layers=[u.name for u in m.uv_layers],texture_size=[SIZE,SIZE],front_reference_bounds=front_bounds,back_reference_bounds=back_bounds,side_reference_bounds=side_bounds,method='Front/back projection plus visibility-weighted side paint guide, silhouette padding, local-thickness blending, emission bake to UV atlas',limitations='Reference shading is included in base color; hidden surfaces and side transitions retain projection compromises. Side guide is generated color guidance, not anatomy authority. Unrigged comparison candidate, no gameplay replacement.')
(D/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('PAINT_DELIVERED',json.dumps(report))
