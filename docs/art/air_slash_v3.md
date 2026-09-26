# Air slash V3

This pass responds to the frozen body and wrist-driven cut in V2. Every bone except `upper_arm.R`, `forearm.R`, and `hand.R` follows the moving `jump_1` animation, sampling jump frames 7–22 across the 16-frame attack. This is a baked moving jump segment, not a live layer that preserves the current jump playback position.

The sword hand rises near the shoulder while the elbow folds backward in the side-view plane. The elbow opens as the hand travels forward, then down, and the arm blends back into the moving jump. The sword maintains a fixed alignment to the forearm during the cut instead of supplying the motion with a separate wrist rotation. The single hit window is source frames 5–8; VFX follow that timing.

The attack smear shader now renders white without the rejected red, yellow, and blue accent lines. The atlas artwork is unchanged in this pass.

Editable Blender source: `ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Air_Light_v3_final.blend`, action `air_light_1`. The right arm bones are grouped by name in the action. The generator is `tools/art/build_air_light_animation.py`; export uses `tools/art/export_equipped_live_3d_test.py`.

For a manual pose edit in Blender: open that file, select `Threadborne_Rig`, enter Pose Mode, and choose action `air_light_1` in the Dope Sheet's Action Editor. Frames 3–4 are the windup, 6 the extension, 8 the follow-through, and 16 the return to jump. Adjust `upper_arm.R` and `forearm.R` together; avoid using only `hand.R` to create the cut. Insert rotation keys after posing. The Godot GLB must be re-exported for edits to appear in-game.

Runtime asset: `Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_air_light_v3_final.glb`.

Verification compares the imported non-arm bones to corresponding moving jump frames, checks that the body moves and the elbow opens, and exercises the existing single-hit timing at multiple playback speeds and frame rates. Render captures show the body separately from the VFX. Aesthetic acceptance remains a gameplay review decision.
