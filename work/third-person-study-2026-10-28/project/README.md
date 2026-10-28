# Threadbound third-person study

Independent Godot 4.7 project. Open `project.godot`, then F5, or use the main
repository's `tools/study/start_third_person_study.ps1` launcher. The installed
copy lives in `Documents/Threadbound 3D Study`; this source copy is backed up in
the main repository beneath a `.gdignore` so the production game skips it.

The study keeps the current Threadborne body, clothes, rig and selected original
animations. It adds an optional CC0 sword/shield pair, an animated workshop
worker and selected CC0 nature pieces, with an authored layout and palette.
`assets/provenance.json`, `assets/workshop_source_manifest.json` and
`assets/licenses/` record sources. Existing player provenance still applies;
this project is not being represented as an entirely CC0 asset pack.

| Action | Keyboard/mouse | Controller |
| --- | --- | --- |
| Move | WASD, relative to camera | Left stick |
| Look | Mouse | Right stick |
| Jump | Space | A / bottom face button |
| Run | Hold Shift | Hold LB |
| Zoom | Mouse wheel | Mouse wheel |
| Compare original/new sword and shield | V | Y / top face button |
| Return to start | R | Back / Select |
| Release cursor | Escape | Escape |
| Capture cursor again | Left click | Left click |

Follow the path to the worker, jump onto the porch/low stone platforms, turn the
camera around Threadborne, and cross the small bridge. The camera retracts
against solid geometry. Walking off the test area returns you to the clearing.

This is an appearance/camera/basic movement study. Movement values are study
values, not a translation of the production controller. It has no combat,
grapple, dash, dialogue, saves or swimming. Water is scenery; entering the
channel eventually triggers fall recovery. Dash/grapple and directional combat
need a further scoped experiment before judging a full game conversion.

`tests/verify_study.gd` runs the focused headless checks. Run with
`godot --headless --path <project-folder> --script tests/verify_study.gd`.
The result is saved as `test_results.json` inside the study. Normal play does not run tests.

To regenerate assets from the repository, run
`tools/study/prepare_third_person_assets.py`, then Blender in background mode
with `tools/study/export_third_person_assets.py`. These require the retained
external archives and the prior house/villager Blender study. Original archives,
player exports and the prior Blender scene are read-only inputs. The installer
refuses to overwrite manually changed files from an earlier installation.
