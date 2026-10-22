# T18 — painted 2D comparison

Chase requested this on October 22 while away from the computer. This explicitly
authorizes a reversible art comparison of the current buildings, enemies,
villagers/props and water bulbs, preserving scale, placement, palette and the
player. It does not accept a permanent change of art direction. T17 water
acceptance remains pending until Chase can play.

## Scope and files

Branch: `threadbound/art-painted-2d-comparison`, from pushed `4448c06f`.
The first checkpoint records source measurements and the comparison setup;
subsequent coherent checkpoints preserve painted buildings and animated actors.

The separate comparison scene inherits the current authored room. Its presentation
controller swaps only artwork. Original models and gameplay scenes remain intact.
AI, collisions, damage, movement, doors, dry pockets, NPC interactions, player
and manual placements retain their current implementations. Hidden original
animation data supplies existing projectile bone anchors; this comparison is
not a performance benchmark for a future fully stripped 2D build.

Planned added files:

- `Assets/BlueBiome/Art/PaintedComparison/`: `fisher_house.png`, `workshop.png`,
  `tower.png`, `boat_slip.png`, `lantern.png`, `net_mender.png`, `boatwright.png`,
  `tide_duelist.png`, `reedhook.png`, `bellstriker.png`, `eave_runner.png`,
  `loom_heron.png`, `water_bulb.png`, and asset manifest/prompt records.
- `Src/Environment/BlueBiome/Comparison/`: standalone comparison `.tscn`,
  presentation controller and focused sprite-animation support if needed.
- `tools/art/capture_painted_comparison_sources.gd` and focused comparison checks.
- `work/painted-2d-comparison-2026-10-22/`: exact source bounds, original-reference
  views, same-camera comparison captures and verification results.
- This report, `docs/project_status_and_worklist.md`, `docs/next_test_session.md`.

No production asset replacement, model deletion or gameplay scene restructuring
is required. Decorative changes stay on the artwork: rope ties, timber joinery,
shutters, nets, baskets and restrained material accents, without new gameplay.

## Style and comparison criteria

Authority: `environment_art_style.md`, `blue_biome_palette_and_rendering_rules.md`,
the Threadborne character and existing terrain. Graphic illustration, strong
silhouettes, restrained dark contours, hard-edged value groups and quiet surface
texture. Walnut #6E4936, parchment #D8C5A2, slate #3D6380, shadow #10263D,
cool edge #86BFD2; amber #F2A64A and cyan accents are limited to their existing
roles. Reusable assets contain neutral material shading, not baked sunlight,
water reflections or glow clouds.

The bulbs currently use 2D frames baked from a 3D model. Their comparison is
painted illustration versus that rendered look. Bridges already use 2D stamp
art; retain them during this test. A 3D railing/bridge experiment can follow
the review, separately.

Match the current measured world-space envelope and foot/door anchors rather
than the obsolete 168px planning reference. Record any limitations in animation
or exact contact silhouette honestly. Review normal-scale readability,
material/palette cohesion, facade/cutaway consistency, decoration density,
attack tells and motion, then judge depth/turning/lighting benefits separately.

## Delivery status

In progress. No manual appearance acceptance is implied. Generation uses the
built-in imagegen tool; prompts and final project-bound originals are retained.
