"""Project the supplied concept onto the supplied fish, then bake its existing UVs."""
from pathlib import Path
import bpy,math
from mathutils import Vector
R=Path(__file__).resolve().parents[2];D=R/'ArtSource/BlueBiome/Blender/Enemies/TideDuelist_Painted_v2'
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(D/'Fish_unpainted.glb'))
o=next(o for o in bpy.data.objects if o.type=='MESH');o.name='TideDuelist_Painted';bpy.context.view_layer.objects.active=o
s=bpy.context.scene
uv_original=o.data.uv_layers.active.name
uv=o.data.uv_layers.new(name='ConceptProjection')
ys=[v.co.y for v in o.data.vertices];zs=[v.co.z for v in o.data.vertices]
ymin,ymax,zmin,zmax=min(ys),max(ys),min(zs),max(zs)
for poly in o.data.polygons:
 for li in poly.loop_indices:
  v=o.data.vertices[o.data.loops[li].vertex_index].co
  u=(v.y-ymin)/(ymax-ymin);vv=(v.z-zmin)/(zmax-zmin)
  uv.data[li].uv=((22+u*2138)/2172,(8+vv*708)/724)
mat=bpy.data.materials.new('Painted navy ivory and brass');mat.use_nodes=True;o.data.materials.clear();o.data.materials.append(mat)
n=mat.node_tree.nodes;l=mat.node_tree.links;n.clear();out=n.new('ShaderNodeOutputMaterial');bs=n.new('ShaderNodeBsdfPrincipled');l.new(bs.outputs['BSDF'],out.inputs['Surface']);bs.inputs['Roughness'].default_value=.57
tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(D/'Fish_reference.png'));tex.extension='EXTEND';tex.label='Supplied color reference, projected symmetrically'
coords=n.new('ShaderNodeUVMap');coords.uv_map='ConceptProjection';l.new(coords.outputs['UV'],tex.inputs['Vector'])
mix=n.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[1].default_value=(.045,.085,.16,1);l.new(tex.outputs['Alpha'],mix.inputs[0]);l.new(tex.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
# Bake the projection into the model's original unwrap, preserving editability.
o.data.uv_layers.active=o.data.uv_layers[uv_original]
target=bpy.data.images.new('TideDuelist_Painted_BaseColor',width=2048,height=2048,alpha=False)
bake=n.new('ShaderNodeTexImage');bake.image=target;n.active=bake
em=n.new('ShaderNodeEmission');l.new(mix.outputs[0],em.inputs['Color']);l.new(em.outputs[0],out.inputs['Surface'])
s.render.engine='CYCLES';s.cycles.samples=1;s.render.bake.margin=16
bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.ops.object.bake(type='EMIT')
target.filepath_raw=str(D/'TideDuelist_BaseColor.png');target.file_format='PNG';target.save()
# Runtime material uses the baked atlas, not a camera-dependent projection.
l.new(bs.outputs[0],out.inputs['Surface']);l.new(bake.outputs['Color'],bs.inputs['Base Color']);n.remove(em);n.remove(mix);n.remove(tex);n.remove(coords)
o.data.uv_layers.remove(uv)
# Let fine painted highlights carry the style; lighting adds a restrained volume cue.
bs.inputs['Specular IOR Level'].default_value=.28
camdata=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',camdata);s.collection.objects.link(cam);s.camera=cam;camdata.type='ORTHO';camdata.ortho_scale=2.10
s.world=bpy.data.worlds.new('Lake studio');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.27,.40,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.55
for name,pos,power,size in [('Key',(3,-2,4),400,4),('Fill',(-3,1,2),250,3)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(name,data);s.collection.objects.link(ob);ob.location=pos;ob.rotation_euler=(-ob.location).to_track_quat('-Z','Y').to_euler()
s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=True;s.render.resolution_x=1400;s.render.resolution_y=700;s.render.resolution_percentage=100;s.render.film_transparent=True;s.view_settings.view_transform='Standard'
for name,pos in [('side',(4,0,0)),('three_quarter',(4,-1.1,1.15)),('reverse',(-4,0,.1))]:
 cam.location=pos;cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(D/f'Fish_painted_{name}.png');bpy.ops.render.render(write_still=True)
cam.location=(4,-1.1,1.15);cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(D/'TideDuelist_Painted_v2.blend'),compress=True)
bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(D/'TideDuelist_Painted_v2.glb'),export_format='GLB',use_selection=True,export_animations=False,export_lights=False,export_cameras=False)
print('FISH_PAINTED',D)

