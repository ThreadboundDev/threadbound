# Cloth and baked movement comparison

The local Blender files and Chamber captures are in `LocalOnly/OG_Material_Review/`. Open `OG_Cloth_Review.blend` to inspect the revised material. Its render shows the ink outline. The cloth keeps its torn geometry with darker fray color, and the exposed leg above each boot uses a flat ivory fill.

`OG_Motion_Trial.blend` fits this mesh to the existing game-ready rig with trial transferred weights. Some folds around the cuffs and skirt still deform roughly. The bake uses the donor `idle_4`, `run_1` and `jump_1` clips. It removes positive pelvis lift from the frame camera so the game controller can supply world movement. All 51 source frames retain their 900 × 1200 pixel scale. The atlas uses a shared crop and an eight-source-pixel black silhouette expansion.

The isolated Chamber preview uses normal movement controls. Press **F7** to switch between baked movement sprites and the current live player. Verified idle, movement, jump, landing, mirrored facing and display switching. Combat, equipment swaps and animation blending have no corresponding baked clips in this study.

To regenerate from the repo root, run `og_cloth_pass.py` in background Blender with the local `OG_Material_Review.blend` open. Run `og_motion_probe.py -- --bake` through Blender's `--python` option with `OG_Cloth_Review.blend` open. Then run `package_og_motion.py` with Pillow. The prepared isolated Godot project under `work/player-sprite-lookdev-2026-11-10/import_project/` runs the study with `--path . --script res://review/og_cloth_preview.gd --rendering-method forward_plus`. Append `-- --verify` to capture the checked movement states.
