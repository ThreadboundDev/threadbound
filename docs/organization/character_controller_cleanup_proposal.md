# Character controller cleanup proposal

November 2, 2026. **Approved by Chase; implementation delivered November 3.**
Chase approved the player migration and requested that only the current Blue
playtest level remain. The prior filesystem cleanup is complete.

## What is actually active

`player.gd` is a 2D CharacterBody controller. `player_live_3d_visual.gd` renders
the equipped animated model into a transparent SubViewport, then composites it
into the 2D world. That viewport and its output sprite are the current renderer;
they are necessary for the current game presentation.

The problem is the second, hidden presentation pipeline. `player.tscn` still
loads old sprite sheets into an AnimatedSprite2D named `Player Animation`.
The controller reads its animation names, frame counts, completion signals,
facing and transforms. Save-point sitting/standing, meditation readiness,
several effect anchors and fallback attack timing still depend on it. The
separate `AnimationPlayer` also carries old stowed-weapon and sprite-transform
tracks alongside active attack-anchor tracks. `Live3DVisual` hides that art
after loading it rather than removing its dependencies.

Flow aura already prefers `Live3DComposite`, with an old-sprite fallback.
Base/colored glove scripts and some fixture scenes still reference the old
sprite. Removing its node or textures alone would break those consumers.

The 3D renderer's upper-body attack/lower-body locomotion sampling is active:
it keeps swimming/running legs moving during attacks. Those blends are useful
current behavior and must be retained. They are separate from the obsolete
sprite-sheet overlays.

## Proposed implementation

1. Record the exact existing logical animation timings in a texture-free data
   file and introduce a small animation clock for the completion/frame events
   that gameplay still requires. Preserve frame durations, speed, pause,
   backward playback and transition ordering; the 3D action clock continues
   to own the existing 3D attack strike windows.
2. Make the controller use explicit facing/state and the live renderer's
   presentation/anchor methods. Route save-point transitions and damage/Flow
   presentation through the current character instead of a hidden sprite.
3. Remove the old body sprite, old glow sprite and retired stowed weapon art
   from the player scene after their callers have been migrated. Rename the
   remaining animation player to describe its attack-pose purpose and remove
   sprite-only tracks. Retain collision, grapple, equipment mount and attack
   anchors and their existing behavior.
4. Replace glove reads of old sprite state with the controller's facing and
   animation interface. Update their old fixture paths and the verification
   scenes. This is a presentation migration, with no new attacks, costs,
   equipment rules, movement tuning, character assets or scene placements.
5. Only after dependency and regression checks pass, put newly unreferenced
   legacy player textures/shaders into deletion staging in a separate manifest.
   An unreferenced-file search alone is not sufficient evidence for deleting
   authoring inputs or dynamically loaded resources.

This removes the parallel hidden character pipeline and makes responsibilities
clear without redesigning the controls. It crosses the scene-tree and equipment
boundaries protected by the repository's AGENTS.md, so a file-specific approval
is required before implementation.

## Proposed file scope

Existing runtime files:

- `Src/Characters/Player/player.gd`
- `Src/Characters/Player/player.tscn`
- `Src/Characters/Player/player_live_3d_visual.gd`
- `Src/Characters/Player/flow_state_aura.gd`
- `Src/Equipment/base_gloves.gd`
- `Src/Equipment/blue_gloves.gd`
- `Src/Equipment/yellow_gloves.gd`
- `Src/Equipment/blue_gloves.tscn`
- `Src/Equipment/red_gloves.tscn`
- `Src/Equipment/yellow_gloves.tscn`

New runtime files:

- `Src/Characters/Player/player_animation_clock.gd` and Godot-generated `.uid`
- `Src/Characters/Player/player_animation_timing.gd`

Existing verification files:

- `tools/environment/verify_downhill_contact.gd`
- `tools/environment/verify_room_greybox.gd`
- `tools/grapple/verify_base_grapple.gd`
- `tools/player_animation/verify_player_animation.gd`
- `tools/player_animation/verify_player_animation.tscn`
- `tools/player_animation/verify_pogo_attack.gd`
- `tools/player_animation/verify_pogo_attack.tscn`
- `tools/playtest_feedback/verify_playtest_feedback.gd`

New behavior regression:

- `tools/player_animation/verify_player_presentation.gd` and generated `.uid`
  (actual player scene: save-point completion/reversal, facing, effect anchors,
  damage presentation and removal of old sprite texture dependencies).

Documentation:

- `docs/art/player_animation_inventory.md`
- `docs/art/player_blender_pipeline.md`
- `docs/organization/character_controller_cleanup_proposal.md`
- `docs/project_status_and_worklist.md`

If implementation reveals another required runtime file, expand this proposal
before editing that file. Deletion candidates will be listed individually after
the migration proves them unused; none are preapproved for permanent deletion.

## Validation and acceptance

Capture the existing clock/attack/save-point behavior first. Compare it after
the migration. Run the actual fitted-doll pose/attachment suite and original
model comparison, player animation/pogo/grapple/defense checks, water combo and
special checks, safe platform drop, save/revive and the focused presentation
regression. Record existing fixture failures separately rather than weakening
tests. Use isolated save data.

Chase's normal-speed movement, attacks, water, grapple, meditation/save point,
damage and equipment review remains the acceptance step. Commit/push the
verified migration separately from file organization.

## Implementation record

See [delivery and validation](runtime_cleanup_2026_11_02.md). Timing data is a small
preloaded GDScript resource so normal exports include it automatically. The focused
presentation regression has a `.tscn` runner; the clock parity check adds
`tools/player_animation/verify_animation_clock.gd`. Unused normalized sheets and
the glow/meditation shaders are staged, with a per-file manifest and matching hashes.
Obsolete atlas-pixel and hidden-body transform assertions retired with that renderer;
active glove art/pose, gameplay and metadata assertions remain. Original gameplay
fixture failures were reproduced and recorded without changing their expectations.
