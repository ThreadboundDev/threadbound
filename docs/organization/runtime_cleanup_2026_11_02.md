# Approved Blue scene and player cleanup

November 2, 2026. Chase approves the character-cleanup proposal and asks to
retain only the Blue level currently used for testing. Implementation delivered November 3; hands-on gameplay acceptance remains open.

The current test card identifies `lakeside_painted_comparison.tscn`, which inherits
the older Krita playtest. Their saved content is consolidated into
`Src/Environment/BlueBiome/blue_lakeside_test.tscn`, the single Blue level in
the game scene tree. The original comparison UID is retained for editor references.
Player, houses, water, terrain, bridge and NPC components remain reusable scenes.

The [location manifest](blue_scene_locations_2026_11_02.json) lists every affected
level. Existing automated checks still need 24 old layouts; those have moved to
`tools/fixtures/blue_layouts/`, behind `.gdignore`. They are regression inputs,
not selectable game levels, and are excluded from normal Godot import/export
discovery. Their assertions remain unchanged. Tools retain their original layout
when testing a historical fixture; normal launchers use the one current scene.

Consumer changes are resource-path updates in the affected Blue helper scripts,
environment/enemy verification tools, art-authoring tools, current test guides
and character preview launcher. The runtime scene root, existing collider geometry,
water masks, room layouts, actor placement and current artwork are preserved.
Packing an inherited scene omitted four overrides; the three bridge `stamp=0`
values and Bellstriker's `start_facing=-1` are restored explicitly.

The separate player migration follows
[the approved file scope](character_controller_cleanup_proposal.md): texture-free
timing, controller-owned facing, live character effects, removal of hidden body/
glow/pattern sprites and old weapon-art tracks, preserving active attack anchors,
grapple mechanics and useful live-3D animation blends. The ongoing modular
equipment work in the shared checkout must be retained and is not part of this
task's commits.

Checkpoints are separate: Blue scene consolidation first, then the verified player
presentation migration. No new gameplay systems, tuning or asset replacements.

## Delivered player boundary

`player.tscn` shrinks from 3,228 to 170 lines. The old body AnimatedSprite2D,
GlowSprite, disabled WallClingVFX, dynamic pattern overlay, stowed shuttle art,
sprite-only breathing/scale/pitch code and unused weapon-art pose clips are gone.
The remaining pose player is `AttackPoseAnimationPlayer`: RESET and quick attack
tracks target the active hitbox anchor. The controller owns presentation facing;
it preserves the separate movement commitment. Damage and yellow snap flashing
now target the visible live composite. Patterns retain their stats/HUD effects.

`player_animation_clock.gd` is a Node with no drawing or transforms. It preserves
24 clip names, frame counts, FPS, loop modes, forward/reverse playback, pause,
resume and completion/frame signals. `player_animation_timing.gd` is preloaded,
so exports include it. Single-precision progress and exact-boundary behavior
match Godot's native sprite clock. Visible character poses, useful layered blends,
equipment adapters, model sources, active grapple rope and attack windows remain.

86 unused files (14,973,801 bytes / 14.28 MiB) moved to sibling deletion staging
folder `08 Retired Player Sprite Runtime`, then were permanently deleted with
Chase's November 3 approval. [Final deletion receipt](deletion_2026_11_03.md).
The [per-file manifest](retired_player_assets_2026_11_03.json) records original paths
and hashes. The pattern shader remains because GameMenu uses it. No videos moved.

## Verification

- Blue inherited-scene flattening: 29,775 stored-property/geometry comparisons pass;
  lake-authoring and all ten historical Blue-room layout checks pass.
- Engine-native clock parity: 25,920 comparisons pass across all 24 clips,
  forward/reverse, speeds 1.0/1.25, pauses and resumes.
- Actual player presentation: 39 checks pass for fitted and original models,
  including facing, crouch/block, collision sizes, effect anchors, patterns,
  visible damage flashing and asynchronous save-point sitting/standing.
- Fitted doll: 875 checks / 320 sampled poses pass. Modular equipment: 1,220
  checks / 40 sampled poses pass. These existing systems were preserved.
- Water combo and all three water specials pass; 31 safe-platform-drop checks,
  61 downhill-contact checks / 12 slopes, 122 water-grapple checks, and Thread
  Knot recovery/merchant/central-light checks pass.
- Retained old animation suite: exactly the same 19 failures before/after.
  Broad grapple suite: exactly the same 20 failures before/after. No new failures.
  The old pogo frame-window assertion and greybox drop-through assertion also
  reproduce with the pre-cleanup controller. Their expectations were retained;
  these older fixtures disagree with later accepted combat/drop-through behavior.
- Existing shutdown ObjectDB/resource diagnostics remain in these engine tests.

Local logs, before snapshots, native timing captures, reference comparison and
hash proofs are under ignored `tmp/runtime-cleanup-2026-11-02/`. User save data is
isolated for every test. The implementation is delivered; Chase's normal-speed
movement/combat/water/grapple/save-point review remains the acceptance step.

Actual canonical Blue level also launches and renders in Forward+ with the cleaned
player; the live avatar, level and HUD are present. A local screenshot is retained
with the verification logs. Existing scene-entry/shutdown diagnostics remain.

Git checkpoints: Blue scene consolidation `2560e610`; player migration `d2eac7e2`.
Task branch: `threadbound/refactor-player-and-blue-scene-cleanup`. Separate ongoing
equipment/feedback/organization work in the shared checkout is preserved.
