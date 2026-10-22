# T17 water readability implementation

Chase approved proceeding with the October 22 review's waterline, contact rims
and exterior/interior compositing recommendations. The new Krita background is
not available yet; this delivery reuses current art. Manual saved scene edits
were checkpointed first as `4130555b`, including the Bellstriker placement.

## Checkpoint 1 — shared surface and honest controls

The lake's three upper vertices now share world y=411. The volume's
`get_surface_global_y()` supplies both presentation and backdrop/cloud cutoff.
The shader uses exported shallow/deep colors and actual normal/underwater
opacity (.34/.16 defaults); wet state is explicit rather than inferred from
equal alpha values. Camera clarity blends over .25 seconds.

`verify_lakeside_water_surface.gd`: 14 checks pass, including physical wet/dry
classification at y=410/412, all top vertices, backdrop alignment, material
controls and equal-opacity false-submersion regression. Existing lake authoring
fixture passes. Existing six-ObjectDB/three-resource shutdown diagnostics remain
tracked under T04. Commit `4ad653bc`:
`fix: align lakeside water surface and presentation controls`.

## Checkpoint 2 — front rock contact

`RockContactRims` derives front strips from exposed floor-facing collision
contours, rejecting internal seams and retaining source PNG alpha/UV registration.
Only 3px projects outside the existing collision; the matching painted solid
face continues 24px inward, preventing a boot from reappearing below a thin mask.
The cave back wall stays at -5; rims draw at +3. No collision or source PNG is
changed. Current build: 918 short boundary segments, 31 batched texture meshes,
2,049 triangles. Editor rebuild follows edited collision and painted chunk
transforms; runtime builds once. Transform registration is covered by the final
fixture as well.

Forward+ delivery fixture: 68 checks pass; cave contact and corrected shoreline
captures inspected. Existing house entry: 405 checks pass. Shader/resource
shutdown diagnostics remain tracked as above. Contact appearance still needs
Chase's normal-speed review, including wide stances beside small painted rocks.
Commit `5428b96e`: `fix: add foreground rock contact rims`.

## Checkpoint 3 — wet exterior, dry interior

Commit `fc40a9b2`: `fix: separate wet exteriors from dry water pockets`.

The lake now draws its reflection/color body behind actors, with a separate
restrained immersion tint in front of actors but behind solid rock contact.
Front building art receives a wet grade based on the actual lake polygon,
independent of dry room masks. Opening a cutaway still reveals a dry interior;
the remaining exterior posts/walls stay wet. No entry behavior or pocket physics
has changed. All three pockets now use the same presentation, with caustics
reduced to a faint boundary/floor cue (intensity .06).

| Draw order | Presentation |
| --- | --- |
| -85 | Underwater distance backdrop |
| -10 / -7 / -6 / -5 | Rear buildings, wood supports, bridges/bulbs, cave walls |
| -4 | Lake body and reflections |
| -2 / -1 / 0 | Pocket boundary cue, movement ripples, player |
| +2 | Light immersion tint; dry pockets excluded |
| +3 / +5 / +9 | Painted contact rims, main terrain, front foliage |
| +10 | Exterior facade with its own lake wet grade |

The existing screen reflection samples scenery behind the lake. The facade's
separate 3D viewport texture also contributes, so moving the lake behind the
player does not remove building reflections. Actors/contact rims are excluded
from that rear screen sample. Offscreen scenery remains unavailable and the
existing viewport-edge fade remains; this is still a screen-based reflection.

## Final verification and evidence

Tested implementation: `fc40a9b2`, Godot 4.7.2. Forward+ / Vulkan captures on
AMD Radeon RX 6800 XT are 1920×1080. Isolated fixture userdata avoids changing
the player's saves.

- Final delivery fixture: **92 checks pass**, including layer ordering,
  synchronized masks, original painted UV/alpha, art transform registration,
  exterior wet mask/reflection hookup and actual wet/dry player classification.
- Surface fixture: **14 checks pass**; existing lake authoring fixture passes.
- Existing regressions: **405 house-entry**, **606 walkway**, **19 authored
  encounter/reset** checks pass; water readability fixture passes dry-pocket
  precedence, wet edges, delayed overlap, wake clipping and pocket depth.
- Rock collision source is byte-for-byte unchanged from saved checkpoint
  `4130555b`; its SHA-256 and regression summary are in
  [results.json](../../work/water-delivery-2026-10-22/results.json).
- All eight GPU views were inspected: corrected shore transition, cave contact,
  visible swimmer, wet tower exterior, dry tower cutaway, dusk, Fisher interior
  and Workshop interior. House feet remain visible at their existing floors.

[GPU check output](../../work/water-delivery-2026-10-22/verification.json) ·
[shore](../../work/water-delivery-2026-10-22/shore.png) ·
[cave contact](../../work/water-delivery-2026-10-22/cave_contact.png) ·
[swimmer](../../work/water-delivery-2026-10-22/swimmer.png) ·
[wet exterior](../../work/water-delivery-2026-10-22/tower_wet_exterior.png) ·
[dry cutaway](../../work/water-delivery-2026-10-22/tower_dry_cutaway.png) ·
[dusk](../../work/water-delivery-2026-10-22/tower_dusk.png) ·
[Fisher interior](../../work/water-delivery-2026-10-22/fisher_interior.png) ·
[Workshop interior](../../work/water-delivery-2026-10-22/workshop_interior.png).

Existing diagnostics remain open: Camera2D interpolation override, Camera3D
updates outside physics, missing glove `Swim_Idle`, six ObjectDB/three resource
shutdown diagnostics, and GPU texture/RID shutdown diagnostics. These runs pass
their assertions but do not clear T04 or establish a frame-time budget.

## Remaining acceptance and Krita background

Implementation is delivered; T17 remains open for Chase's normal-speed review
and the separate background asset. Use the [next test card](../next_test_session.md).
Check small rock lips, wide stances, jumping, dry-room transitions, swimmer
contrast and day/dusk at normal playing scale.

The new Krita underwater background has not been supplied. Keep the existing
6912×5888 registration at world origin (-1408,-2560), 1:1 scale; the installed
waterline y=411 is artwork row 2971. Paint quiet distance silhouettes on a
separate layer, without baked reflections or a second surface stripe. Integrate
that export in a separate asset checkpoint when available. Source paintings,
collision inset, manual Bellstriker placement and bridge/bulb depths are retained.

The original review and temporary previews remain historical diagnostic evidence.
