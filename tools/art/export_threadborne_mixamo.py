"""Export a textured, unrigged T-pose copy for manual Mixamo upload."""
import bpy,json
from pathlib import Path
from mathutils import Matrix
root=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character'
out=root/'mixamo_upload';out.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(root/'Threadborne_2D_Shoulder_Refinement.blend'))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
source=bpy.data.objects['Threadborne_Posing_Preview']
ob=source.copy();ob.data=source.data.copy();bpy.context.scene.collection.objects.link(ob)
ob.name='Threadborne_Mixamo_Upload';ob.parent=None;ob.matrix_world=Matrix.Identity(4)
ob.modifiers.clear();ob.vertex_groups.clear();ob.hide_set(False);ob.hide_viewport=False;ob.hide_render=False
textures=[]
for m in ob.data.materials:
    if not m or not m.use_nodes:continue
    for n in m.node_tree.nodes:
        if n.type=='TEX_IMAGE' and n.image and n.image.name not in textures:
            im=n.image;im.filepath_raw=str(out/(im.name+'.png'));im.file_format='PNG';im.save()
            textures.append(im.name)
bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
target=out/'Threadborne_Mixamo_Upload.fbx'
bpy.ops.export_scene.fbx(filepath=str(target),use_selection=True,object_types={'MESH'},
    use_mesh_modifiers=False,bake_anim=False,add_leaf_bones=False,
    path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
assert target.exists() and target.stat().st_size>100000
report={'file':str(target),'vertices':len(ob.data.vertices),'faces':len(ob.data.polygons),'armature_exported':False,'textures':textures,'bytes':target.stat().st_size}
(out/'export_report.json').write_text(json.dumps(report,indent=2))
print('MIXAMO_EXPORT_COMPLETE',json.dumps(report),flush=True)
# Verify the actual FBX, not only the exporter result. This clears this offline process only.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(target))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(meshes)==1 and not any(o.type=='ARMATURE' for o in bpy.context.scene.objects)
assert len(meshes[0].data.uv_layers)>0
assert len(meshes[0].data.materials)>0
color_nodes=[n for m in meshes[0].data.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image and 'BaseColor' in n.image.name]
assert color_nodes and all(n.image.size[0]>0 for n in color_nodes)
print('FBX_REIMPORT_VERIFIED',len(meshes[0].data.vertices),'vertices',len(color_nodes),'base color maps',flush=True)
