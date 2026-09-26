# Blue development checkpoint — September 26, 2026

Branch: `threadbound/chore-blue-development-checkpoint`, based on `5ee389c6` from `threadbound/level-blue-biome-development`.

## Review groups

- Repository hygiene and Git LFS setup.
- Editable player models, animation sources, exports and generation tools.
- Still village, background and water bulb art studies.
- Polygon water, air pockets and greybox authoring.
- Live 3D player, attacks, sword effects, defense and input presentation.
- Directional water bulb interactions.
- Reedhook and Tide Duelist assets, behavior, animation and checks.
- Lake greybox, test rooms and layered presentation.
- Design/art documentation and development media.

Named source revisions are preserved. Automatic Blender backups, scratch files, caches and logs remain excluded. New Blender/GLB/FBX/ZIP assets are stored through LFS; existing Git history is unchanged. The complete branch is the runnable checkpoint; shared runtime files make some topic commits dependent on later commits.

## Validation

Passed the relevant Godot checks:

- `tools/combat/verify_lake_attack_refresh.gd`
- `tools/environment/verify_lake_authoring.gd`
- `tools/environment/verify_lake_readability.gd`
- `tools/environment/verify_room_greybox.tscn`
- `tools/environment/verify_bulb_choices.tscn`
- `tools/enemies/verify_reedhook.tscn`
- `tools/enemies/verify_tide_duelist.tscn`
- `Src/Tests/PlayerCombat/player_defense_test.tscn`

Two stale tests were updated: lake authoring now installs its own stable polygon fixture instead of assuming the designer's room layout; greybox presentation checks now expect translucent water and velocity-driven Swim_Idle, with explicit facing for the legacy sprite check.

Existing headless log/certificate errors and shutdown resource warnings remain. The legacy glove path reports a missing Swim_Idle animation. Passing these checks is not a substitute for visual playtesting, especially the latest fish tell, attack readability and lake layout. No merge or release is implied by this checkpoint.
