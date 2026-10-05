"""Export saved manual combo edits without regenerating or saving the .blend.

Run: blender --background --python tools/art/export_water_combo.py
"""
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_v4_IK.blend'))
names = {'water_combo_1', 'water_combo_2', 'water_combo_3'}
assert names.issubset(bpy.data.actions.keys()), 'Keep all three combo action names.'
rig = bpy.data.objects['Threadborne_Rig']
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
for track in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(track)
for action in list(bpy.data.actions):
    if action.name not in names:
        bpy.data.actions.remove(action)
bpy.context.scene.render.fps = 30
bpy.ops.object.select_all(action='DESELECT')
for obj in [rig, bpy.data.objects['Threadborne_Posing_Preview']]:
    obj.hide_set(False)
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
dest = ROOT / 'Assets/Threadborne/Player/Equipped3DTest/threadborne_water_combo.glb'
bpy.ops.export_scene.gltf(filepath=str(dest), export_format='GLB', use_selection=True, export_materials='NONE', export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True, export_skins=True, export_lights=False, export_cameras=False)
print('WATER_COMBO_EXPORTED', dest)
