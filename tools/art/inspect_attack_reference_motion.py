"""Print source sword-arm reach/bend throughout the existing attack clips."""
from pathlib import Path
import bpy, math

root = Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root / 'ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Animation_Library.blend'))
rig = bpy.data.objects['Threadborne_Rig']
rig.animation_data.use_nla = False
for bone in rig.pose.bones:
    for constraint in bone.constraints:
        constraint.mute = True
for name, frames in [('slash_1', range(1, 47, 4)), ('slash_2', range(1, 37, 4)), ('attack_1', range(1, 72, 7))]:
    rig.animation_data.action = bpy.data.actions[name]
    print('REFERENCE', name)
    for frame in frames:
        bpy.context.scene.frame_set(frame)
        bpy.context.view_layer.update()
        shoulder = rig.pose.bones['upper_arm.R'].head
        elbow = rig.pose.bones['forearm.R'].head
        hand = rig.pose.bones['hand.R'].head
        bend = math.degrees((shoulder-elbow).angle(hand-elbow))
        print(frame, 'wrist_relative_shoulder', tuple(round(v, 3) for v in hand-shoulder), 'elbow_degrees', round(bend))
