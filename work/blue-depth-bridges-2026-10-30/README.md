# Blue depth and bridge review

[Delivery, images and limits](../../docs/art/blue_depth_and_bridges_2026_10_30.md).

- `validation.json`: 70 engine checks.
- `before.json` / `after.json`: collision coordinates and measured pan positions.
- `anchors.json`: physics-surveyed support points and actual supporting bodies.
- `*-comparison.jpg`: actual scene captures before/after, with no art retouching.
- `reusable-assets.jpg`: new asset types in an isolated geometry illustration.

Use normal imported project resources and Godot 4.7.2. Redirect APPDATA to
`tmp/blue-depth-bridges/userdata` so tests do not touch normal saves/preferences.
Run `--headless --path . --fixed-fps 60 --script
res://tools/environment/verify_blue_depth_bridges.gd` for the focused checks.
`capture_environment.gd` renders the comparison scene on GPU; add `-- --baseline`
only on the pre-integration revision. The `-- --survey-only` option runs headless
and requires no GPU screenshots. Raw captures are excluded by the local gitignore.
`review_assets.gd` renders the standalone asset illustration. `build_review.py`
packages figures with Python/Pillow and checks captured collision equality.

`apply_underwater.py` invokes only the importer's pure scoped scene composer
without opening/reexporting the KRA or altering PNGs. It verifies idempotence.
Use `extract_map.py --underwater-only` when intentionally reimporting the named
source paint layer; do not run its legacy full-scene/physics generation.

Current tests validate the delivered art's placement and motion, not gameplay
feel. The current project has baseline scene-ownership and shutdown diagnostics;
no clean-log claim is made. Chase's hands-on acceptance remains pending.
