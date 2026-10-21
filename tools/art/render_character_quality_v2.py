"""Background source-model previews. No graphical app window is opened."""
from pathlib import Path
import bpy,json,sys
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'work/character-quality-v2/renders';OUT.mkdir(exist_ok=True)
jobs=[('Villagers/LakesideVillagers_v2.blend','NetMender','TalkIdle'),('Villagers/LakesideVillagers_v2.blend','Boatwright','TalkIdle.001'),('Enemies/EaveRunner/EaveRunner_Woven_v2.blend','EaveRunner','idle'),('Enemies/LoomHeron/LoomHeron_Woven_v2.blend','LoomHeron','needle_aim')]
for path,kind,clip in jobs:
    if '--villagers-only' in sys.argv and kind not in ['NetMender','Boatwright']:continue
    if '--net-only' in sys.argv and kind!='NetMender':continue
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome'/path));rig=next(o for o in bpy.data.objects if o.type=='ARMATURE' and kind in o.name);sc=rig.users_scene[0];bpy.context.window.scene=sc
    rig.animation_data.action=bpy.data.actions[clip];sc.frame_set(20 if kind=='LoomHeron' else 1)
    for o in sc.objects:
        if o.type=='MESH' and o.parent!=rig and 'Floor' not in o.name and 'floor' not in o.name:o.hide_render=True
    cam=sc.camera;cam.location=(2.6,-5.8,2.25) if kind!='LoomHeron' else (3,-5,2.7);target=Vector((0,0,.95 if kind!='LoomHeron' else 1.18));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=2.15 if kind!='LoomHeron' else 4.1
    sc.render.engine='CYCLES';sc.cycles.samples=48;sc.cycles.use_denoising=True;sc.render.resolution_x=1800;sc.render.resolution_y=1800 if kind!='LoomHeron' else 1400;sc.render.resolution_percentage=100
    if '--quick' in sys.argv:
        sc.cycles.samples=12;sc.render.resolution_x=1000;sc.render.resolution_y=1000
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(OUT/(kind+('_v2_Check.png' if '--quick' in sys.argv else '_v2_Source.png')));bpy.ops.render.render(write_still=True)
    # Close detail view uses real extra topology and 4K textures, not AI retouch.
    if kind!='LoomHeron' and '--quick' not in sys.argv:
        target=Vector((0,-.02,1.56 if kind=='EaveRunner' else 1.48));cam.location=target+Vector((1.5,-4,.7));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.85;sc.render.resolution_x=1400;sc.render.resolution_y=1400;sc.render.filepath=str(OUT/(kind+'_v2_Detail.png'));bpy.ops.render.render(write_still=True)
    print('CHARACTER_V2_RENDERED',kind,flush=True)
