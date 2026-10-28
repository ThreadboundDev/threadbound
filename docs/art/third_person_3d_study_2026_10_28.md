# Third-person 3D study — October 28, 2026

Chase authorized building the separate 3D experiment and downloading/using
appropriate assets. Keep the current character, avoid chibi proportions, use
stylized/low-poly surroundings that fit together, and permit a different sword
and shield. This delivers that bounded study; production scenes and systems are
unchanged. Appearance and feel acceptance remain Chase's decision.

## Open and play

The standalone project is installed at
`C:\Users\chase\Documents\Threadbound 3D Study\project.godot`.
Open it in Godot and press F5, or run
[the launcher](../../tools/study/start_third_person_study.ps1).
Use `-Editor` to open that separate project in the editor.

The checkpointed source is
[work/third-person-study-2026-10-28/project](../../work/third-person-study-2026-10-28/project/README.md).
Its parent `.gdignore` excludes the entire study from production Godot imports.
[Installer](../../tools/study/install_third_person_study.py) copies those sources
to the standalone folder, checks hashes and preserves subsequent manual edits.

WASD moves relative to the camera; mouse looks; Space jumps; Shift runs;
wheel zooms; **V switches between new and original weapons**; R returns to the
start; Escape releases the cursor and left click captures it again. Controller
maps use left/right sticks, A jump, LB run, Y weapons and Back return.
Controller mappings exist; physical-device feel still needs hands-on review.

## What to review

Walk toward the workshop, watch the worker, jump onto the porch and low stone
platforms, cross the bridge and rotate the camera around the same Threadborne.
Compare the sword/shield silhouettes. Judge whether the materials, proportions
and space feel like one world, and whether full 3D movement/camera feels promising.

- [Gameplay view](../../work/third-person-study-2026-10-28/third_person_gameplay.png).
- [Character and workshop view](../../work/third-person-study-2026-10-28/third_person_character.png).
- [Focused check results](../../work/third-person-study-2026-10-28/verification.json).

## Sources and adaptation

The same current player mesh, clothing and rig come from
`Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb`.
Selected original idle/walk/run/jump clips drive a new independent capsule
controller. Authored animation travel is compensated horizontally so the model
does not walk away from its controller. No player anatomy or costume redesign.

The new `sword_B` and `shield_B` use the retained KayKit Weapons Bits CC0 release.
Working-copy geometry is aligned and scaled to the existing animated attachment
roots. The original pair remains available for comparison. This adds no equipment
system or weapon progression.

The house, clothed adult worker, table-work loop and props reuse the
[prior CC0 workshop study](cc0_house_villager_comparison_2026_10_28.md), including
the authored apron/patch and planing motion. Worker texture working copies are
targeted to 1K for this scene; sources remain intact.

Downloaded [Kenney's Nature Kit 2.1 from his OpenGameArt upload](https://opengameart.org/content/nature-kit)
after the main Kenney archive host returned HTTP 403. The downloaded ZIP passed
CRC inspection and includes an explicit CC0 commercial-use notice with optional
credit. Only two trees, a bush and two rocks are converted from OBJ/MTL to GLB;
leaf colours are muted. The archive stays in the external asset library.
The first retained retro-tree trial was superseded; its foliage copies were
removed from this study. This is not the same release as the current site's
Nature Kit 1.0; source/version/hash are recorded explicitly.

An authored clearing, footpath, bridge, water material, jump blocks, lighting
and fog connect the sources with a restrained green/stone/indigo/flax palette.
No new generative images were used. New downloaded content is CC0; the existing
player retains its original provenance. See the study's
[provenance](../../work/third-person-study-2026-10-28/project/assets/provenance.json)
and [workshop source manifest](../../work/third-person-study-2026-10-28/project/assets/workshop_source_manifest.json).

## Scope and validation

This study implements walk/run/jump, camera orbit/zoom/collision, original/new
weapon comparison and fall recovery. It is not a port of production movement.
No combat, grapple, dash, dialogue, saves or swimming. Water is visual scenery;
fall recovery returns the player after dropping into the channel. Porch and
bridge lips can require a jump. Those limits matter when judging feel.

Focused Godot checks exercise movement in both horizontal axes, camera-relative
motion, jump/landing, floor/house/bridge collisions, camera retraction, work-loop
motion, weapon switching and recovery. Actual GPU screenshots are inspected;
capture metrics record renderer, GPU, resolution and frame-time samples.
Headless behavior checks do not establish controller comfort or final performance.
Review the captures and play at normal speed before accepting the visual direction.

Results: **20/20 focused checks pass**, including a fresh standalone-project
import/run outside the production repository. Camera retraction against the
house measured 2.64 m from a requested 5.4 m. The
[asset audit](../../work/third-person-study-2026-10-28/asset_validation.json)
checks seven self-contained GLBs, nine resource links, all workshop maps at
1024px or less, and unchanged original player/Blender-source hashes.
The workshop export is 10.4 MB, reduced from 48.4 MB in the first working copy.
Both 120-frame GPU capture samples at 1440x900 on an RX 6800 XT / GL Compatibility
reported roughly 4.17 ms median and 4.5–4.8 ms p95 engine frame deltas. These
short stationary captures are not an end-to-end latency or minimum-spec benchmark.
Metrics sit beside the screenshots; hands-on keyboard/controller and visual
acceptance remain pending.

Checkpoint: `feature: add isolated third-person Threadbound study`.
No conversion of the main game is implied. A promising initial review should
lead to a bounded dash/grapple study before a decision on full 3D production.
