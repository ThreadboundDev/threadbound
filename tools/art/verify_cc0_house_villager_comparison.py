"""Read and verify the saved Blender comparison; optionally render its detail loop."""
import bpy
import json
from pathlib import Path
import sys
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/cc0-house-villager-2026-10-28'
bpy.ops.wm.open_mainfile(filepath=str(WORK / 'CC0_House_WorkingVillager_Comparison.blend'))
scene = bpy.context.scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
targets = {side: bpy.data.objects['Work wrist target / ' + side] for side in ('l', 'r')}
report = dict(joints=len(rig.data.bones), action=rig.animation_data.action.name,
              wrist_error_max_m=0, frames_checked=[], feet_displacement_max_m=0,
              loop_pose_error_max=0, missing_images=[])
assert report['joints'] == 65
assert report['action'] == 'Threadbound_Work_Plane_Loop_96f'
foot_start = None
for frame in range(1, 98):
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    for side, target in targets.items():
        error = (rig.matrix_world @ rig.pose.bones['hand_' + side].head - target.location).length
        report['wrist_error_max_m'] = max(error, report['wrist_error_max_m'])
    feet = [(rig.matrix_world @ rig.pose.bones['foot_' + side].head).copy() for side in ('l', 'r')]
    if foot_start is None:
        foot_start = feet
    report['feet_displacement_max_m'] = max([report['feet_displacement_max_m']] + [(a-b).length for a,b in zip(feet, foot_start)])
    report['frames_checked'].append(frame)
    if frame == 1:
        pose_start = {b.name: b.matrix.copy() for b in rig.pose.bones}
        plane_start = bpy.data.objects['Authored / hand-plane motion control'].location.copy()
    if frame == 97:
        report['loop_pose_error_max'] = max(abs(v) for pb in rig.pose.bones for row in (pb.matrix-pose_start[pb.name]) for v in row)
        report['loop_tool_error_m'] = (bpy.data.objects['Authored / hand-plane motion control'].location-plane_start).length
for image in bpy.data.images:
    if image.source == 'FILE' and not image.packed_file:
        report['missing_images'].append(image.name)
assert report['wrist_error_max_m'] < .001, report
assert report['feet_displacement_max_m'] < .0001, report
assert report['loop_pose_error_max'] < .0001, report
assert report['loop_tool_error_m'] < .0001, report
assert not report['missing_images'], report
report['result'] = 'PASS'
(WORK / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
scene.frame_set(13)
if '--render-detail' in sys.argv:
    camera = scene.camera
    camera.location = (2.3, -6.5, 2.9)
    camera.rotation_euler = (Vector((.65, -.65, 1)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.ortho_scale = 2.65
    scene.render.resolution_x = scene.render.resolution_y = 800
    scene.render.resolution_percentage = 72
    scene.cycles.samples = 8
    for frame in range(1, 97, 2):
        scene.frame_set(frame)
        scene.render.filepath = str(WORK / 'temp' / f'detail_{frame:03}.png')
        bpy.ops.render.render(write_still=True)
print('CC0_COMPARISON_VERIFICATION_PASS', flush=True)
