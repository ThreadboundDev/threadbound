"""Render a controlled current/relit look-dev pair without modifying the source blend."""
import bpy
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'ArtSource/Player/Blender/imported_character/mixamo_test/Threadborne_Equipped_Animation_Test.blend'
OUT=ROOT/'Assets/Threadborne/Player/LookDev'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
s=bpy.context.scene;s.frame_set(38)
s.render.resolution_x=900;s.render.resolution_y=1200;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.film_transparent=True
s.cycles.samples=32
s.render.filepath=str(OUT/'01_current.png');bpy.ops.render.render(write_still=True)

# The original scene has one neutral point light behind the side camera. Turn it
# into a restrained cool rim, then add a broad warm key and soft cool fill.
existing=next((o for o in s.objects if o.type=='LIGHT'),None)
if existing:
    existing.data.energy=650;existing.data.color=(.48,.64,1.0);existing.data.shadow_soft_size=2.0
def area(name,location,energy,color,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.color=color;data.shape='DISK';data.size=size
    ob=bpy.data.objects.new(name,data);s.collection.objects.link(ob);ob.location=location
    ob.rotation_euler=(Vector((0,0,1.15))-ob.location).to_track_quat('-Z','Y').to_euler();return ob
area('LookDev_Warm_Key',(-3.8,-3.2,4.2),1050,(1.0,.63,.38),3.2)
area('LookDev_Cool_Fill',(-2.8,3.0,2.1),380,(.42,.62,1.0),4.0)
area('LookDev_Mask_Kicker',(-2.2,-.2,2.7),220,(1.0,.87,.64),1.3)
if s.world:
    s.world.use_nodes=True
    bg=next((n for n in s.world.node_tree.nodes if n.type=='BACKGROUND'),None)
    if bg:bg.inputs['Color'].default_value=(.015,.022,.030,1);bg.inputs['Strength'].default_value=.12
try:
    s.view_settings.view_transform='AgX';s.view_settings.look='AgX - Medium High Contrast'
except Exception:
    pass
s.view_settings.exposure=.45

# Lift only the costume's deepest texture values; preserve the worn texture and
# keep the mask as the brightest focal area.
for mat in bpy.data.materials:
    if not mat or not mat.use_nodes or not mat.name.startswith('Threadborne_Costume_Material'):continue
    p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if not p or not p.inputs['Base Color'].is_linked:continue
    link=p.inputs['Base Color'].links[0];source=link.from_socket
    lift=mat.node_tree.nodes.new('ShaderNodeMixRGB');lift.name='LOOKDEV • lift black cloth';lift.blend_type='SCREEN'
    lift.inputs[0].default_value=.14;lift.inputs[2].default_value=(.07,.055,.045,1)
    mat.node_tree.links.remove(link);mat.node_tree.links.new(source,lift.inputs[1]);mat.node_tree.links.new(lift.outputs[0],p.inputs['Base Color'])
s.render.filepath=str(OUT/'02_relit.png');bpy.ops.render.render(write_still=True)
print('LOOKDEV_RENDER_COMPLETE',flush=True)
