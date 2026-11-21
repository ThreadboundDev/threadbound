# Woven-world outline audition — November 21, 2026

Run `res://Src/Tests/Art/WovenWorld/woven_chunk_level.tscn` with F6. Press O to
cycle the following modes; the heading names the active one. V still compares
foliage bases. Chase reports that the thin outline looks much better. Thin width
is the preferred direction; material-colored ink is the current test default.

| Mode | Width relative to the original | Ink |
| --- | --- | --- |
| 0 — Original | 100% | Original near-black materials, restored exactly |
| 1 — Thin dark | 50% | Original near-black color |
| 2 — Thin material | 50% | Dark material-family colors; default |

The current two-world-pixel main outline becomes approximately one world pixel
in both thin modes, before camera zoom. Existing fine hand/hardware ratios and
depth-tested object shells remain intact. The palette uses cloth `#303c49`,
wood `#4b3928`, leather/shield `#483727` and metal/sword `#394650`.

`gameplay_0/1/2.png` use 1x zoom. `close_0/1/2.png` use 2x zoom. All six are
actual 1920 x 1080 game renders of the same frozen stance on the locally adjusted
Ground A. Only outline materials and the explanatory heading change within each
zoom group. The camera remains active while the pose is paused; checks assert
both requested zooms. These images are not generated character approximations.

`metrics.json` samples the actor's transparent 3D viewport at 400 x 300 using
nearest-neighbor sampling. It counts pixels with alpha > 0.8 and, among them,
near-black pixels whose maximum RGB channel is < 0.1. Render assertions require
the thin shell to reduce opaque silhouette area and the material treatment to
reduce near-black pixels relative to thin dark at the same width. These are
coverage checks, not a visual acceptance score.

The helper `woven_outline_comparison.gd` owns local copies of shell materials,
restores source materials exactly, and reapplies the profile to newly loaded
equipment visuals. It changes no gear abilities, meshes, animations or shared
player shaders. The chunk script reads the actual collider cap for shadows and
debug lines, preserving manual collision placement.

Full-route validation passes 146 headless and 163 Forward+ checks. The latter
includes all thirteen current captures and actor render measurements. Six save/
settings CFG hashes are unchanged. Existing editor-settings, shader-cache and
shutdown resource diagnostics are recorded in the parent delivery. Production
adoption and final colored-versus-dark selection remain separate from this test.
