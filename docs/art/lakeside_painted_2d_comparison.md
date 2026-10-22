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

**Ready for Chase's comparison; no permanent art-direction acceptance.** Source
measurements/references are pushed as `6e654911`, buildings as `f47c62fe`, and
LFS tracking as `9efac8e7`. Final comparison implementation: **`6d23110c`**, pushed
on `threadbound/art-painted-2d-comparison`. All new PNGs are retained unchanged from the
built-in imagegen output; alpha/pose measurements create atlas metadata only.

Open and F6:
`res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`.
It starts in painted mode. **F7** switches all categories; the bottom controls
switch **Buildings / Actors / Bulbs** separately. Unchecked means current models
(or the existing rendered bulb frames). Existing landmarks, Day/dusk, Interact
doors and **F2** still work. The main menu and original playtest are unchanged.

The four building sheets include matched exterior/cutaway states where needed,
with new joinery, rope, netting and basket details. Fisher/tower plaster received
a neutral-albedo cleanup to remove directional lighting inherited from model
references. The other nine sheets cover lantern, both villagers/workstations,
all five model enemy types and bulb lifecycle.

| Asset | Existing world envelope / registration |
| --- | --- |
| Fisher house | 744.96×835.321, same bottom anchor and centered door |
| Workshop | 1000.96×636.921, same left door and floor |
| Tower | 1200×4100, same prongs, tiers and bottom anchor |
| Boat slip | 1034.24×972.921, same open center and footings |
| Lantern | 38.4×69.44, same hanging anchor; all four placements |
| Enemies | Initial alpha envelope measured from current render; fixed pose scale and existing facing/body transforms |
| Villagers | Existing floor anchor and combined workstation envelope; work/greet poses plus separate station frame |
| Bulbs | Sac diameter registered to existing hit/grapple square; all four placed instances |

Painted contours naturally differ from model geometry. Existing physical shapes,
door destinations and floors are retained; drawing a new contour does not move
collision. Atlas regions preserve extended weapons/wings, and grounded poses
share foot registration rather than resizing independently per pose.

## Validation and captured comparison

Godot 4.7.2 Forward+ / Vulkan, RX 6800 XT, 1920×1080 captures, isolated userdata:

- **168 comparison checks pass**: 13 RGBA sheets / 50 atlas frames, exact building
  envelopes, unchanged collision when switching, original player, five enemy
  bindings including F2 replacement, existing projectile bone anchor, both house
  interactions/floor contact, mixed resident rendering and real bulb lifecycle.
- **405 original house-entry checks pass**; **19 authored encounter/reset checks
  pass**. These exercise the unchanged base room; the comparison fixture above
  exercises the inherited comparison scene itself.
- Eleven original gameplay/layout sources match `4448c06f`, including room,
  rocks, water, bulb logic, player scene, stage renderer and the five enemy scripts.
  Hashes and regression results: [regressions.json](../../work/painted-2d-comparison-2026-10-22/regressions.json).
- [Verification output](../../work/painted-2d-comparison-2026-10-22/verification.json)
  records all 32 same-camera images: houses outside/inside, mixed NPCs, wet/dry
  tower, dusk, boat slip, overview, each enemy and bulb ready/spent.

Useful pairs:

| View | Current models | Painted 2D |
| --- | --- | --- |
| Fisher house | [models](../../work/painted-2d-comparison-2026-10-22/fisher_models.png) | [painted](../../work/painted-2d-comparison-2026-10-22/fisher_painted.png) |
| Workshop | [models](../../work/painted-2d-comparison-2026-10-22/workshop_models.png) | [painted](../../work/painted-2d-comparison-2026-10-22/workshop_painted.png) |
| Boat slip | [models](../../work/painted-2d-comparison-2026-10-22/boat_slip_models.png) | [painted](../../work/painted-2d-comparison-2026-10-22/boat_slip_painted.png) |
| Overview | [models](../../work/painted-2d-comparison-2026-10-22/overview_models.png) | [painted](../../work/painted-2d-comparison-2026-10-22/overview_painted.png) |
| Eave Runner | [models](../../work/painted-2d-comparison-2026-10-22/eave_runner_models.png) | [painted](../../work/painted-2d-comparison-2026-10-22/eave_runner_painted.png) |
| Water bulb | [rendered](../../work/painted-2d-comparison-2026-10-22/bulb_models.png) | [painted](../../work/painted-2d-comparison-2026-10-22/bulb_painted.png) |

Camera interpolation and resource/RID shutdown diagnostics remain open under T04.
This run reports six ObjectDB/three resources at GPU teardown; the house regression
reports ten/five. Passing assertions does not establish a clean shutdown.

## What this comparison can and cannot decide

Judge material/color cohesion, contours, decoration, silhouette and gameplay-scale
readability first. Layered 2D still provides foreground/rear-wall occlusion and
working cutaways; models provide continuous 3D articulation/turning and real
surface lighting/shadows. Both use the same water compositing and placements.

Enemy sheets contain six key poses, NPCs two character poses, and bulbs six
lifecycle poses. These are comparison animations, not a finished replacement
for all continuous model clips. NPC greetings do not reproduce full 3D turning;
enemy weapon/beak drawings can differ from retained physical/projectile anchors.
Review motion/attachment at normal speed before choosing a production approach.

The whole-tower atlas is softer under large diagnostic zoom; if selected, a
production 2D tower should use higher-resolution storey exports. No performance
claim follows from this test: hidden model animation/reference data remains,
and mixed NPCs use a separate lit pass to remain in front of painted rear walls.
Unused enemy render viewports are disabled, but this is not a stripped 2D build.

New Krita underwater distance art remains pending under T17. No bridge rebuild,
permanent art replacement, lore change or new gameplay system is included.
