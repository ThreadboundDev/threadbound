from pathlib import Path
import bpy,json
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/eave-runner-v3'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];rig.data.pose_position='POSE';rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1);bpy.context.view_layer.update()
tunic=next(o for o in sc.objects if o.type=='MESH' and o.name.startswith('Player-fitted sculpted'))
core=next(o for o in sc.objects if o.type=='MESH' and o.name.startswith('Continuous woven anatomy'))
deps=bpy.context.evaluated_depsgraph_get();t=BVHTree.FromObject(tunic,deps);c=BVHTree.FromObject(core,deps)
rows=[];protrusions=0;both=0
for j in range(20):
    z=1.13+j*.018
    for i in range(19):
        x=-.15+i/18*.3;origin=Vector((x,-.8,z));direction=Vector((0,1,0))
        tp,tn,ti,td=t.ray_cast(origin,direction,1.6);cp,cn,ci,cd=c.ray_cast(origin,direction,1.6)
        if tp is not None and cp is not None:
            both+=1;gap=cp.y-tp.y;protrusions+=gap<-.001
            rows.append({'x':x,'z':z,'core_minus_tunic_y':gap})
result={'both_hit_count':both,'core_protrudes_in_front_over_1mm':protrusions,'min_depth_gap':min(row['core_minus_tunic_y'] for row in rows),'max_depth_gap':max(row['core_minus_tunic_y'] for row in rows),'samples':rows}
(OUT/'player_tunic_surface_overlap.json').write_text(json.dumps(result,indent=2));print('OVERLAP',both,protrusions,result['min_depth_gap'],result['max_depth_gap'],flush=True)

for ob in sc.objects:
    if ob.type=='MESH':ob.hide_render=ob!=tunic
clay=bpy.data.materials.new('TEMP diagnostic clay');clay.use_nodes=True;clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.35,.45,.5,1);clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.7
tunic_material=tunic.data.materials[0]
tunic.data.materials.clear();tunic.data.materials.append(clay)
sc.render.engine='CYCLES';sc.cycles.samples=8;sc.cycles.use_denoising=True;sc.render.resolution_percentage=100;sc.render.resolution_x=800;sc.render.resolution_y=800;cam=sc.camera;cam.location=(1.2,-5,1.9);target=Vector((0,0,1.35));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.75
sc.render.filepath=str(OUT/'renders/Diagnostic_Tunic_Only_Clay.png');bpy.ops.render.render(write_still=True)
core.hide_render=False;core.data.materials.clear();core.data.materials.append(clay)
sc.render.filepath=str(OUT/'renders/Diagnostic_Tunic_Plus_Core_Clay.png');bpy.ops.render.render(write_still=True)
core.hide_render=True;tunic.data.materials.clear();tunic.data.materials.append(tunic_material)
sc.render.filepath=str(OUT/'renders/Diagnostic_Tunic_Original_Material.png');bpy.ops.render.render(write_still=True)
bs=tunic_material.node_tree.nodes['Principled BSDF']
for link in list(bs.inputs['Normal'].links):tunic_material.node_tree.links.remove(link)
sc.render.filepath=str(OUT/'renders/Diagnostic_Tunic_Normal_Disabled.png');bpy.ops.render.render(write_still=True)
