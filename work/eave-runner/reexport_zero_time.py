import bpy,tempfile,os
from pathlib import Path
root=Path('C:/Users/chase/Documents/threadbound')
tempfile.tempdir=str(root/'work/eave-runner/temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.open_mainfile(filepath=str(root/'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v1.blend'))
bpy.ops.object.select_all(action='DESELECT')
rig=bpy.data.objects['EaveRunner_Rig'];actor=bpy.data.objects['EaveRunner_TexturedMesh']
rig.select_set(True);actor.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(root/'Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v1.glb'),export_format='GLB',use_selection=True,
 export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
 export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)
print('EAVE_RUNNER_ZERO_TIME_EXPORT_READY')
