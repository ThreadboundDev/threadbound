# Current character files

For the latest **equipped animation review**, open `mixamo_test/Threadborne_Equipped_Animation_Test.blend`. It includes Idle (1–77), Run (78–99), Jump (100–125), animated fingers, a fitted right-hand sword and left-forearm shield, and a true side-on orthographic camera. See `mixamo_test/README.md` for playback, render sizing, and remaining limitations. The notes below describe the earlier base rig, which remains unchanged.

Open `Threadborne_2D_Shoulder_Refinement.blend` for posing. It opens in Pose Mode: select a body bone and use R to rotate, Alt+R to reset. Save experiments under a new name. Edit Mode changes the rest skeleton and requires weight rechecking.

The viewport uses `Threadborne_Posing_Preview` (39,045 vertices); renders use `Threadborne_Character` (982,421 vertices). The dense surface's RENDER collection is disabled only in the viewport. To inspect full detail, enable that collection's viewport monitor and hide the posing preview to avoid overlap. Solid/Texture mode is the lightweight default.

The rig has 32 bones. IK guides exist but are disabled. Initial weights were proximity-based after Blender's automatic weighting failed; the shoulder/armpit blend has since been refined and checked at 45°/60°. Lower-body weights were preserved. Fingers, independent cloth, final IK, weapon fitting and completed animation clips are not ready yet.

`imported_source_snapshot.blend` is the untouched character source backup. `mixamo_upload/Threadborne_Mixamo_Upload.fbx` is the lighter unrigged T-pose model for Mixamo, with supporting textures retained. The detailed original is not being replaced; motion transfer back to it remains to be tested.

The sprite camera has a 900 × 900 transparent canvas, approximately 720px standing body height and a target 0.25 scale for 180px gameplay height. Do not independently resize animation frames.

Superseded revisions, diagnostic images, and scripts were moved to `C:/Users/chase/Documents/Threadborne_Art_Archive/2026-09-05-retired-blender`. Current renders and validation reports remain here. See `docs/art/player_blender_pipeline.md` for the active workflow.
