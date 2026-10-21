from pathlib import Path
import bpy
R=Path.cwd();bpy.ops.wm.open_mainfile(filepath=str(R/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend'))
s=bpy.context.scene;r=bpy.data.objects['EaveRunner_Rig'];m=bpy.data.materials.new('Diagnostic clay');m.use_nodes=True;p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(.35,.35,.35,1);p.inputs['Roughness'].default_value=.8
for o in s.objects:
    if o.type=='MESH':
        o.data.materials.clear();o.data.materials.append(m)
s.render.resolution_x=900;s.render.resolution_y=1100;s.cycles.samples=8
r.animation_data.action=bpy.data.actions['idle'];s.frame_set(1)
for state in ['POSE','REST']:
    r.data.pose_position=state;bpy.context.view_layer.update();s.render.filepath=str(R/('work/eave-runner-v3/renders/Clay_'+state+'.png'));bpy.ops.render.render(write_still=True)
