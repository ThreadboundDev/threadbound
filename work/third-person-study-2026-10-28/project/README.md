# Threadbound third-person combat and traversal playtest

Independent Godot 4.7 project. Open `project.godot`, then F5, or use the main
repository's `tools/study/start_third_person_study.ps1` launcher. The installed
copy lives in `Documents/Threadbound 3D Study`; this source copy is backed up in
the main repository beneath a `.gdignore` so the production game skips it.

The playtest keeps the current Threadborne body, clothes, rig and selected original
animations. It adds Reedhook, Eave Runner, a Bellstriker champion, a six-ring
grapple/platform route, combat/specials, sound and an optional CC0 sword/shield
pair alongside the workshop worker and selected CC0 nature pieces.
`assets/provenance.json`, `assets/workshop_source_manifest.json` and
`assets/licenses/` record sources. Existing player provenance still applies;
this project is not being represented as an entirely CC0 asset pack.

| Action | Keyboard/mouse | Controller |
| --- | --- | --- |
| Move | WASD, relative to camera | Left stick |
| Look | Mouse | Right stick |
| Jump | Space | A / bottom face button |
| Run | Hold Shift | Hold LB |
| Dash | Ctrl | B |
| Tap-to-buffer sword combo / airborne strike | LMB | RT |
| Guard / fresh frontal parry | RMB | LT |
| Neutral burst / movement + directional spin | Q | X |
| Hold grapple / enemy grapple strike | E | RB |
| Lock/unlock nearest enemy | Tab | Right-stick click |
| Zoom | Mouse wheel | Mouse wheel |
| Compare original/new sword and shield | V | Y / top face button |
| Reset enemies, health, AP and traversal | R | Back / Select |
| Pause / resume | Escape | Start |
| Help / sound mute | H / M | Keyboard H / M |

Start at the workshop, then turn toward the field encounters. The elevated route
has six consecutive grapple rings and thread-marked safe landings. Cross the
stream to challenge the champion. The camera retracts against solid geometry
and foliage; falls return to the last marked landing. Both specials cost 2 AP
from a six-point pool. Each spent point recharges independently in ten seconds.

This remains an independent 3D adaptation. Movement, meter distances, aim assist
and encounter health are study values. No dialogue, production saves/equipment,
swimming or complete Momentum/Flow simulation. Water is scenery; entering the
channel eventually triggers fall recovery. Physical-controller feel, sound
balance, normal-speed combat and camera comfort require hands-on review.

`tests/verify_study.gd` runs the focused headless checks. Run with
`godot --headless --path <project-folder> --script tests/verify_study.gd`.
The result is saved as `test_results.json` inside the study. Normal play does not run tests.
`tests/verify_combat_playtest.gd` runs the expanded integration suite and writes
`combat_test_results.json`. Both result files and generated captures are ignored.
`assets/combat_provenance.json` records new enemy/audio inputs. Source game art
and registered sounds retain their original provenance; newly downloaded music
and the retained NOX recordings have CC0 evidence under `assets/licenses/`.

To regenerate assets from the repository, run
`tools/study/prepare_third_person_assets.py`, then Blender in background mode
with `tools/study/export_third_person_assets.py`. These require the retained
external archives and the prior house/villager Blender study. Original archives,
player exports and the prior Blender scene are read-only inputs. The installer
refuses to overwrite manually changed files from an earlier installation.

Combat additions regenerate with `tools/study/prepare_combat_playtest.py`,
Blender's `tools/study/export_playtest_eave_runner.py`, and the player exporter
with `-- --player-only`. The CC0 ambient OGG is retained in the external library.
Godot regenerates extracted texture copies/import caches from the self-contained
GLBs. This source does not depend on the main project's autoloads or res:// paths.
