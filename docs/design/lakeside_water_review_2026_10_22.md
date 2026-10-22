# Lakeside water review — October 22, 2026

**Historical review.** Chase subsequently approved implementation. Surface,
contact rims and exterior/interior corrections are delivered through `fc40a9b2`.
Use the [delivery report](../verification/lakeside_water_delivery_2026_10_22.md)
for installed behavior, final captures and remaining acceptance/background work.

Reviewed game revision `14710d84`. Scope: active Krita lakeside room, polygon
water/reflections, underwater backdrop, building compositing, dry pockets and
rock/player contact. The older rectangular reflective water path was inspected
separately. This commit contains review tools/evidence only; no saved gameplay,
collision, shader or art replacement changes.

## Main findings

### 1. The cyan strip is an alignment defect

The room uses `Volumes/Lake` with `polygon_lake.gdshader`, not a separate
rectangular `BlueReflectiveWater2D` overlay. Its top world-space vertices are
`(-1397,391)`, `(8,411)` and `(5473,406)`. They do not form a level surface.
`get_surface_global_y()` returns the minimum, **391**. Both the screen-space
mirror and the underwater backdrop/cloud cutoff use that value, while the
actual fill begins along the sloping polygon boundary.

| World x | Actual upper polygon edge y | Mirror/backdrop y | Uncovered band |
| ---: | ---: | ---: | ---: |
| 128, shore | 410.89 | 391 | 19.89px |
| 1472, tower | 409.66 | 391 | 18.66px |
| 2816, boat slip | 408.43 | 391 | 17.43px |
| 5400, right edge | 406.07 | 391 | 15.07px |

The band is the shallow depth backdrop exposed before the reflective fill
starts. The shader's eight-pixel surface highlight also measures from 391, so
it has already faded out at most of the actual fill's upper edge. Moving only
the reflection would leave the background and swimming/float surface disagreeing.

A disposable runtime preview aligns all three top vertices to **world y=411**
and updates the existing shared waterline. The detached strip disappears.
411 preserves the present main-shore height closely; it is a proposed alignment
target, not an installed edit. The contact/entry retest must include the slightly
lower water at the far left/right before accepting it.

[Current shoreline](../../work/water-review-2026-10-22/shore_current.png) ·
[Flat-plane diagnostic preview](../../work/water-review-2026-10-22/shore_flat_plane_preview.png) ·
[Chase's screenshot](../../work/water-review-2026-10-22/reported_surface_gap.png)

### 2. Rock contact and cave background share the wrong visual role

The 32 `TerrainArtwork/rear_cave` chunks draw at **z=-5**, behind the player at
**z=0**. Some of that artwork is a genuine back wall, but some supplies contact
surfaces traced by the solid rock collision. The separate nine `terrain` chunks
already draw at **z=5**. This is not a universal problem with every rock layer.

Preserve Chase's intentional few-pixel collision inset. Add/select front rock
contact rims so the painted lip hides those few pixels of the feet. Keep broad
cave back walls behind the player. A front rim is visual overlap, not another
collision surface. It should not obscure the torso, weapon tell or required route.

Moving the **entire** rear cave layer to z=3 in a disposable instance hides the
whole standing character against the cave back wall. That disproves a blanket
"put all rocks in front" fix.

[Current cave contact](../../work/water-review-2026-10-22/cave_contact_current.png) ·
[Rejected whole-layer-front preview](../../work/water-review-2026-10-22/cave_all_rock_front_preview.png)

### 3. Dry-pocket masking is applied to the exterior too

The tower's dry pocket removes the global water fill at every pixel inside the
pocket polygon, including the closed exterior facade. Consequently the submerged
tower has a bright, sharply outlined dry-shaped strip across its exterior while
nearby posts and stone remain blue. This is the visual contradiction Chase is
describing. The interior can legitimately be dry; its exterior still needs to
look submerged when viewed from outside.

Keep physical dry-pocket classification separate from exterior wet appearance.
A closed exterior receives underwater grading. An exposed cutaway interior keeps
normal dry colors and readable residents/player. Mark the wet/dry opening with
architecture and a restrained boundary cue instead of a large bright polygon.
This is a presentation change, not a proposal to remove pockets or add a new
pressure/door/progression mechanic.

[Current submerged exterior](../../work/water-review-2026-10-22/tower_outside_submerged.png) ·
[Current dry cutaway](../../work/water-review-2026-10-22/tower_inside_dry.png)

The two small houses do not need to be treated as flooded interiors. Fisher's
floor is y=326.72, above the local lake surface near y=411; the Workshop floor
is much higher still. Tint only genuinely submerged posts/foundations. The boat
slip's open water remains swimmable. Preserve approved Interact house entry.

### 4. The current water is one overlay over almost everything

Current effective draw order, back to front:

| Layer | z |
| --- | ---: |
| Underwater depth backdrop | -85 |
| Building rear pass / outdoor small-house facades | -10 |
| Background wood | -7 |
| Bridges/bulbs | -6 |
| Combined cave rocks | -5 |
| Presented dry-pocket caustics | -2 |
| Movement rings | -1 |
| Player | 0 |
| Separate solid terrain artwork | 5 |
| Foreground foliage | 9 |
| Building foreground facade pass | 10 |
| Lake fill, reflection and tint together | 20 |

Thus water currently washes over terrain and facades as well as actors. Simply
moving that entire overlay behind everything would remove useful immersion cues
and change which objects are available to screen-space reflection. Reflection
capture order must be checked when separating those responsibilities.

Recommended roles:

| Role | Recommended placement/behavior |
| --- | --- |
| Krita underwater distance/background | Behind buildings, rocks, actors and water effects |
| Rear cave walls, distant structures and timber | Behind gameplay; quiet values and depth separation |
| Water body/reflections | Behind solid shoreline/contact lips; reflections strongest near the actual surface |
| Wet actors/posts/rock faces | Light, depth-aware immersion grade on the wet part; preserve silhouettes |
| Player and enemies | Clearly readable; feet may overlap front contact rims |
| Front rock/shore rims | Above the overlapping feet and water body; retain subtle wet material response below the line |
| Dry interior | Excluded from wet tint when visible as an interior; outside facade remains wet |
| Surface accents | Thin, restrained contact glints/rings; avoid a large opaque cyan sheet |

These are compositing roles, not proposed final z numbers. A complete split
needs a file-scoped implementation proposal and approval before scene-tree/art
replacement changes under `AGENTS.md`.

### 5. Opacity and pocket settings are misleading/inconsistent

- `underwater_opacity` defaults to **0.16**, but the presented lake shader emits
  hard-coded alpha **0.58** or **0.23**. The exported value is used to decide the
  `submerged` boolean through alpha equality; it is not the final shader alpha.
  The presented shader also supplies its own colors. Make those controls honest
  before using the inspector to tune water against new paintings.
- One player's wet state changes the opacity of the whole lake. Keep the useful
  clearer underwater view, but distinguish that camera readability treatment
  from local object wetness. Check transition popping before adding more effects.
- `AirPocket` and `AirPocket2` use the caustics presentation; `AirPocket3` has
  `lake_presentation=false`, so it retains a faint green greybox fill/outline
  instead. Standardize the visual treatment. Current three pockets use 23 of
  the supported 256 visual vertices, well below the 16-pocket limit.
- Pocket caustics currently make the dry region look like another kind of water.
  Reduce broad interior patterning; concentrate a small cue at a framed boundary
  or floor. Keep the center visibly dry.
- Reflections use the visible screen. Offscreen scenery cannot contribute and
  reflections fade near screen edges. A painted underwater background should
  provide stable depth when the camera submerges and the sky leaves the screen.

## What to paint in Krita

Use the existing **6912×5888** map registration at world origin **(-1408,-2560)**,
1:1 scale. Keep these as separate layers/exports:

1. Underwater distance: quiet depth/color masses and distant silhouettes, with
   clear negative space behind routes and enemies.
2. Near underwater dressing, where useful, kept separate from solid contact art.
3. Front rock/shore contact rims, distinct from cave back walls, if authored by
   hand rather than derived from existing painted pixels during implementation.

Let Godot supply live reflections, water tint and contact effects. Preserve
unlit reusable art; do not bake reflected houses, a second rigid cyan surface,
moving caustics or player lighting into the background. Existing palette/value
rules still apply. Water should remain unnaturally still, with restrained local
responses rather than a new flowing ocean effect.

For registration, artwork y = world y + 2560; the **preview** surface y=411 is
artwork row 2971. Confirm the common surface before painting a hard shoreline.
The depth background itself can be prepared independently now.

## Recommended commit order

1. **Surface alignment and real opacity controls.** First bounded correction:
   flatten this room's lake cap at the agreed common y; retain one source of
   truth for volume, mirror, backdrop/cloud cutoff and float surface; wire real
   shader alpha/color controls. Candidate commit:
   `fix: align lakeside water surface and presentation controls`.
   Expected files: `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`,
   `Src/Environment/Greybox/greybox_polygon_water.gd`,
   `Src/Environment/BlueBiome/Water/polygon_lake.gdshader`,
   a focused `tools/environment/verify_lakeside_water_surface.gd` (and `.gd.uid`),
   plus this report/current work list and dated verification evidence.
2. **Front contact art.** Separate a narrow front contact treatment from broad
   rear cave art, preserving rock collision positions, bridge/bulb depth and
   existing house behavior. Prepare the exact masks/assets and file list before
   seeking the required art/scene approval. Commit independently after visible
   contact tests; do not silently move all cave art in front.
3. **Exterior/interior water compositing.** Keep underwater facades wet and
   cutaway rooms dry, standardize all three pockets and calm their cues. Define
   reflection eligibility and the shared surface/foreground tint split before
   changing the rendering structure. Obtain the file-scoped approval, verify
   water/dry transitions and house/tower views, then commit.
4. **Krita background integration and final water acceptance.** Import the
   approved painting at unchanged map registration. Compare normal play scale,
   daylight/dusk, surface/underwater cameras, shore/slip/tower, enemies and F2.
   Run H1 water-control/combat and H3 route checks for the exercised revision;
   record frame time. Commit the accepted art and review separately.

No new lore, progression, combat behavior or collision-height changes are proposed.
These are recommended follow-ups, not approvals granted by this review.

## Evidence and limits

`tools/environment/audit_lakeside_water.gd` records live depth, shader, pocket and
boundary data. `-- --capture` saves real Forward+ images and the clearly named
temporary flat-plane/whole-rock-front variations. It never saves a scene or
shader. [Audit JSON](../../work/water-review-2026-10-22/audit.json).

Godot 4.7.2 stable mono, Windows Forward+, AMD Radeon RX 6800 XT, isolated
APPDATA. The audit never writes scene/art files. A concurrent manual Godot save
changed the room's Bellstriker placement and editor serialization during this
review; that scene edit is preserved unstaged, separately from this checkpoint.
The reviewed water polygon/pocket/depth settings match `14710d84` and were not
changed by those manual edits. Both existing
`verify_lake_authoring.gd` (**LAKE AUTHORING: PASS**) and
`verify_lake_readability.gd` (**PASS: dry-pocket precedence...**) pass. Those
checks verify water classification and movement invariants, not surface image
alignment or foreground occlusion. The newly found defects can coexist with
their passing results. The older rectangular fixture also reports
**BLUE_REFLECTIVE_WATER_VERIFY_OK**; its shader has different UV-based surface
fading and is not the active shader shown here.

The readability run also logs `Missing glove anim: Swim_Idle`; inspect that
separately if a visible equipment animation fault reproduces. Existing
camera/interpolation, six-ObjectDB/three-resource shutdown diagnostics and GPU
texture/RID teardown diagnostics remain unresolved under T04. No source parse
error or failed water assertion occurred. No frame-time measurement, completed
hands-on control review or final art acceptance is claimed.

Review checkpoint subject: `docs: review lakeside water and contact readability`.
