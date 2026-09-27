# Equipped animation review

Open `Threadborne_Equipped_Animation_Test.blend`. This is a separate review asset, not a replacement for the Godot player. The original shoulder-refinement file is unchanged.

Play the timeline at 30 fps:

- Idle: frames 1–77.
- Run: frames 78–99.
- Jump: frames 100–125.

The three named actions are retained separately. The timeline is a test reel with abrupt clip boundaries, not production transitions. Mixamo motion is transferred to the detailed character, with 30 added finger bones (62 bones total). The light posing mesh is used in the viewport; renders use the detailed mesh.

The sword follows the right hand, blade toward the thumb end of the grip. The handle is fitted inside the curled fingers. Attachment checks cover all 125 frames; maximum grip-center error is about 1.95 mm. The shield follows the left forearm. Its slide for grapple use is not animated yet.

Equipment fit revision: the shield has moved 6 mm toward the arm, and its two leather loops have deeper, separately sized arches around the clothed forearm. The sword's rigid pendant cords were removed; its blade, guard and grip remain. These edits apply to this animation test, leaving the original weapon source intact for recovery. `*_shield_fit.png` provides close-up checks in idle, run and jump.

Follow-up fit: the elbow end of the shield is tilted down 7 degrees about the wrist strap, without increasing strap slack. Shield tassels and the remaining cords behind the sword handle are removed. `sword_back_hand_check.png` checks the previously obscured side of the grip. Rebuilds must run `finish_weapon_cord_cleanup.py` after `refine_equipped_straps.py` and before final rendering.

The back-hand diagnostic crops the lightweight posing mesh to reveal contact without torso occlusion; its cut wrist and lower mesh detail are diagnostic only and are not present in the full-character renders.

Sword readability: a shared 56-degree roll around the handle axis improves broad-face visibility from the fixed side camera during run and jump. It is a constant attachment offset (also used in idle), not a camera-facing effect or per-clip switch. Grip position and blade direction are preserved. It introduces no new attachment rotation jump between clips; the original body-animation transitions still need gameplay blending. `fit_sword_readability.py -- --apply` sets the roll, and `finalize_equipped_side_test.py` preserves it when rendering.

The camera is true side-on, level, orthographic, facing the character's right side. Render canvas is 900 × 1200 with transparency; quarter-size previews are 225 × 300, with approximately 180 px standing character height. Padding accommodates jumping. Keep the same canvas and pivot across animations; do not trim individual frames independently.

`equipped_animation_preview.gif` is a roughly 12 fps review of the three clips. `preview_frames/` contains transparent PNG samples. The full-resolution stills and `*_grip_check.png` images are close inspection aids. `*_import.blend` files are rebuild intermediates, not alternate final characters.

Remaining polish: cloth currently follows skinning, not independent cloth simulation; shoulder deformation and foot contact may need animation-specific adjustment. No Godot runtime assets or equipment code were changed. This has not been tested in the game yet.

Rebuild order: `inspect_mixamo_clips.py`, `build_mixamo_weapon_test.py`, `refine_equipped_straps.py`, then **`finalize_equipped_side_test.py`** (required final grip and camera correction), followed by `assemble_equipped_preview.py` using Python with Pillow. Run Blender in the background to avoid stealing focus.
