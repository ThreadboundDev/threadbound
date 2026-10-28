"""Render a local Fab asset review. Only linear previews/metadata are delivered.

Raw FBX/TGA and Blender working copies remain ignored; no game asset replacement.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector
import zipfile

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/armored-golem-review-2026-10-28'
SOURCE=WORK/'temp/source'
OUT=WORK/'renders'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(SOURCE/'Mesh/StoneGolem.fbx'))
scene=bpy.context.scene
rig=next(o for o in scene.objects if o.type=='ARMATURE')
character=[o for o in scene.objects if o.type=='MESH']
scene.render.fps=30

# One skin only. Selectively copy its emission mask from the original archive.
emission='Textures/T_StoneGolem_Body_Emission_Skin1.tga'
with zipfile.ZipFile('C:/Users/chase/Downloads/textures.zip') as archive:
    (SOURCE/emission).write_bytes(archive.read(emission))
for category in ('Body','Armor','Weapon'):
    mat=bpy.data.materials.new('Review / source '+category+' skin 1')
    mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    for suffix,socket in [('Albedo_Skin1','Base Color'),('Roughness','Roughness'),('Metallic','Metallic')]:
        path=SOURCE/f'Textures/T_StoneGolem_{category}_{suffix}.tga'
        image=bpy.data.images.load(str(path),check_existing=True)
        # Downsample the temporary preview image in memory, not the source texture.
        image.scale(2048,2048)
        if suffix!='Albedo_Skin1':image.colorspace_settings.name='Non-Color'
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
        mat.node_tree.links.new(node.outputs['Color'],shader.inputs[socket])
    if category=='Body':
        image=bpy.data.images.load(str(SOURCE/emission));image.scale(2048,2048)
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
        mat.node_tree.links.new(node.outputs['Color'],shader.inputs['Emission Color'])
        shader.inputs['Emission Strength'].default_value=.8
    for ob in character:
        for index,old in enumerate(ob.data.materials):
            if category.lower() in old.name.lower():ob.data.materials[index]=mat

def load_action(name):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(SOURCE/f'Animations/StoneGolem@{name}.fbx'))
    imported=list(set(bpy.data.objects)-before)
    other=next(o for o in imported if o.type=='ARMATURE')
    differences={bone.name:max(abs(x) for row in bone.matrix_local-other.data.bones[bone.name].matrix_local for x in row) for bone in rig.data.bones}
    print('RIG_COMPARISON',name,'model scale',tuple(rig.scale),'animation scale',tuple(other.scale),
          'model pelvis',tuple(rig.data.bones['pelvis'].head_local),'animation pelvis',tuple(other.data.bones['pelvis'].head_local),flush=True)
    assert {b.name for b in rig.data.bones}=={b.name for b in other.data.bones}
    source_action=other.animation_data.action
    start,end=[int(x) for x in source_action.frame_range]
    action=bpy.data.actions.new('Golem review / '+name)
    rig.animation_data_create();rig.animation_data.action=action
    for frame in range(start,end+1):
        scene.frame_set(frame);bpy.context.view_layer.update()
        transform=rig.matrix_world.inverted()@other.matrix_world
        poses={pb.name:transform@pb.matrix for pb in other.pose.bones}
        for pb in rig.pose.bones:
            if pb.parent:
                pb.matrix_basis=pb.bone.convert_local_to_pose(poses[pb.name],pb.bone.matrix_local,
                    parent_matrix=poses[pb.parent.name],parent_matrix_local=pb.parent.bone.matrix_local,invert=True)
            else:
                pb.matrix_basis=pb.bone.convert_local_to_pose(poses[pb.name],pb.bone.matrix_local,invert=True)
            pb.rotation_mode='QUATERNION'
            pb.keyframe_insert('location',frame=frame,group=pb.name)
            pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
            pb.keyframe_insert('scale',frame=frame,group=pb.name)
    action.use_fake_user=True
    for ob in imported:bpy.data.objects.remove(ob,do_unlink=True)
    return action

def world_bounds():
    points=[]
    for ob in character:
        evaluated=ob.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mesh=evaluated.to_mesh()
        points += [evaluated.matrix_world@v.co for v in mesh.vertices]
        evaluated.to_mesh_clear()
    return [[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)]

idle=load_action('idle1')
scene.frame_set(int(idle.frame_range[0]))
bpy.context.view_layer.update()
base_bounds=world_bounds()
world=bpy.data.worlds.new('Review stage');world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.07,.10,.14,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.6
scene.world=world
floor_mat=bpy.data.materials.new('Review floor');floor_mat.use_nodes=True
floor_mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.04,.055,.07,1)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,base_bounds[2][0]-.004))
bpy.context.object.data.materials.append(floor_mat)

def area(name,xyz,power,size,color):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=size;data.color=color
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=xyz
    ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Warm key',(-3,-4,5),750,4,(1,.87,.72))
area('Cool fill',(4,-2,3),600,4,(.61,.77,1))
area('Rim',(0,4,4),1100,3,(.76,.87,1))
data=bpy.data.cameras.new('Review camera');camera=bpy.data.objects.new('Review camera',data);scene.collection.objects.link(camera)
scene.camera=camera;data.type='ORTHO';data.ortho_scale=2.8
def point_camera(position,target=(0,0,.95)):
    camera.location=position
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
point_camera((3,-7,2.8))
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=800;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
scene.render.filepath=str(OUT/'golem_three_quarter.png');bpy.ops.render.render(write_still=True)
point_camera((7,0,2.1))
scene.render.filepath=str(OUT/'golem_gameplay_side.png');bpy.ops.render.render(write_still=True)

attack=load_action('attack1')
start,end=[int(v) for v in attack.frame_range]
sample_frames=sorted(set([start,int(start+(end-start)*.25),int(start+(end-start)*.5),int(start+(end-start)*.75),end]))
motion=[]
for frame in sample_frames:
    scene.frame_set(frame);bpy.context.view_layer.update()
    motion.append(dict(frame=frame,bounds=world_bounds(),
                       weapon_bones={name:list(rig.matrix_world@rig.pose.bones[name].head) for name in ('Weapon_r','Weapon_l') if name in rig.pose.bones}))
# Frame against all sampled attack bounds, not just the idle silhouette.
span=max(max(r['bounds'][axis][1] for r in motion)-min(r['bounds'][axis][0] for r in motion) for axis in (0,1,2))
data.ortho_scale=max(2.8,span*1.2)
point_camera((3,-7,2.6))
scene.render.resolution_percentage=70;scene.cycles.samples=8
for index in range(36):
    frame=start+(end-start)*index/35
    scene.frame_set(int(frame),subframe=frame%1)
    scene.render.filepath=str(WORK/'temp'/f'attack_{index:03}.png')
    bpy.ops.render.render(write_still=True)
report=dict(mesh='Mesh/StoneGolem.fbx',preview_skin=1,source_bones=len(rig.data.bones),
            mesh_triangles=sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in character),
            material_count=len({mat.name for ob in character for mat in ob.data.materials}),
            preview_texture_resolution=2048,normal_maps='Not applied; tangent/normal import remains unvalidated.',
            idle_bounds=base_bounds,attack='attack1',attack_frame_range=[start,end],fps=30,
            attack_duration_seconds=(end-start)/30,attack_samples=motion,
            model_source_or_blend_published=False,game_installation=False)
(WORK/'render_inspection.json').write_bytes((json.dumps(report,indent=2)+'\n').encode())
print('GOLEM_REVIEW_RENDER_COMPLETE',flush=True)
