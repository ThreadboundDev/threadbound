# Loom Heron V3 — bird-only craft rebuild

Open **LoomHeron_Woven_v3.blend**. Textures are packed. The saved studio camera
and lighting are included, along with 153 named editable model components.
The scene uses the existing 18-bone rig and all 11 original animation clips.
Choose a clip in the Action Editor; ranged clips are needle_aim, needle_fire,
and low_recover. Idle, flight and perch loop.

The actual Godot prefab in the Threadbound project now uses LoomHeron_v3.glb.
Its ranged behavior, 2D collision, placement and render scale are retained.

## Review files

- Heron_v3_Beauty.png: whole model.
- Heron_v3_Head_and_Craft.png: ceramic face, textile layers and braided joins.
- Heron_v3_Rear.png: wing backs and tail construction.
- Heron_v3_Perched.png and Heron_v3_Aim.png: existing rig pose checks.
- Heron_v3_Game_Camera.png: source model with the prefab's camera geometry.
- Heron_v3_Motion.gif: flight, charge, release and recovery source animation.
- Heron_v3_Pose_Review.png: selected motion frames together.

All previews are actual Blender renders of this saved model. They use Blender
lighting and are not Godot screenshots. No concept-image paintover is used.

## Verification

835 source checks, 167 actual-prefab art checks, 134 existing guardian combat
checks and 19 real-room checks passed. This verifies model data and behavior;
GPU appearance, frame time and final art acceptance still need playing.

573,520 triangles, 15 materials, 18 bones. The approved shared 4K maps are reused
with more carefully authored geometry, independent component UVs and material
variation. Older bird sources remain in the project.
