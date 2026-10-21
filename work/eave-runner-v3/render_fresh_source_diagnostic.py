from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['EaveRunner_Rig'];rig.animation_data.action=bpy.data.actions['idle'];sc.frame_set(1);bpy.context.view_layer.update()
sc.render.engine='CYCLES';sc.cycles.samples=12;sc.cycles.use_denoising=True;sc.render.resolution_percentage=100;sc.render.resolution_x=900;sc.render.resolution_y=1100
sc.render.filepath=str(ROOT/'work/eave-runner-v3/renders/Diagnostic_Fresh_Source_Full.png');bpy.ops.render.render(write_still=True)
hems=[o for o in sc.objects if o.type=='MESH' and o.name.startswith('Finished tunic and cowl cut hem')]
for ob in hems:ob.hide_render=True
print('HIDDEN_TUNIC_HEMS',len(hems),'triangles',sum(len(p.vertices)-2 for o in hems for p in o.data.polygons),flush=True)
sc.render.filepath=str(ROOT/'work/eave-runner-v3/renders/Diagnostic_Fresh_Source_Hems_Hidden.png');bpy.ops.render.render(write_still=True)
