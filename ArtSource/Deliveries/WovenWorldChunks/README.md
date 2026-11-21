# Woven world chunks — November 20, 2026

Chase liked the woven low-poly style and identified the repeating terrain as
the weak part of the first kit. This follow-up follows his requested direction:
large full-depth ground chunks, floating platforms in different sizes and
decoration variants, assembled into a short playable level.

## Play and edit

Open `res://Src/Tests/Art/WovenWorld/woven_chunk_level.tscn` in Godot and press
**F6**, or run this from the repository root:

```powershell
& tools/art/woven_world/start_chunk_review.ps1
```

- **1 / 2 / 3:** move between the three review positions.
- **C:** show collision and walkable surface lines.
- **R:** return to the start.
- **V:** compare the original, irregular-base and hanging-rim foliage at the
  middle ground's leaf cluster.
- **O:** cycle original, thin dark and thin material-colored character outlines.
  Thin material is the starting mode; the current mode is shown in the heading.
- Normal movement and jump controls work. The lower route has two ground gaps;
  the optional upper route starts with the existing double jump.
- Missing a jump returns the player to the current review area without damage.

`Geometry`, `Decorations` and `Planting` are authored nodes in the scene and
can be repositioned in Godot. The level instances the actual production player
and its live modular wooden doll. It does not regenerate the character or change
its movement, combat or equipment. The earlier tile comparison and production
levels remain intact. This is a traversal/art audition, not a production level
or a water/combat encounter.

## Reusable pieces

All ten new images and their native placeable scenes are under
`Assets/BlueBiome/Art/WovenWorldChunks/`.

| Piece | Delivered size | Use |
| --- | --- | --- |
| `ground_a` | 1792 x 1125 | Broad slate cliff, 1059 px below its surface |
| `ground_b` | 1536 x 928 | Staggered grey cliff, 871 px below its surface |
| `ground_c` | 1792 x 1028 | Warm weathered cliff, 951 px below its surface |
| `platform_small` | 256 x 85 | Short step |
| `platform_medium` | 448 x 97 | Medium ledge |
| `platform_large` | 768 x 120 | Broad shelf |
| `platform_long` | 1024 x 135 | Long traverse shelf |
| `tree_alt` | 920 x 882 | Green canopy and interlaced trunk |
| `foliage_alt` | 360 x 180 | Fern and folded-leaf variant |
| `blossom_shrub` | 320 x 177 | Low pink flowering shrub |

Drag the corresponding `.tscn` from `placeables/` into a scene. A ground or
platform root marks its walkable plane at local Y=0; its artwork is offset to
that plane and its collider is already aligned. Decoration roots mark the
planting base, centered horizontally. Ground pieces have solid rectangular
bodies; platform caps use one-way collision. Decorations have no collision.

The test places three ground chunks and six platforms using the four distinct
platform sources. It also reuses the first kit's pink tree, leaves and boulders.
The lower cuts of the ground images stay below the current camera view. Deeper
camera travel or different zoom may need deeper source art. Piece boundaries
in this test are exposed cliff edges and gaps; arbitrary chunks are not claimed
to join seamlessly at every possible position.

## Source artwork and preparation

The ten new images were generated using the **built-in image_gen tool**. The
tool does not expose its backend version. `generation_manifest.json` preserves
every full prompt; `sources/` keeps each original alpha image and the same style
reference used for the first kit. Source, runtime and rendered PNGs use Git LFS.

Run `tools/art/woven_world/prepare_chunks.ps1` to reproduce the runtime images,
placeables, metadata and contact sheet. Preparation trims alpha with a small
margin, resizes proportionally and measures the opaque walkable caps. It does
not slice the cliff faces into tiles, repeat fill, blend seams or redraw images.
All three sampled ground bodies are fully opaque within the measured interior.
Collision caps remain simple horizontal planes; inspect contact at the edges
before using the kit in production.

## Verification and review

- **146 headless checks passed:** ten original image/scene deliveries, visible cap
  alignment, full-depth bodies, all nine placed surfaces supporting the actual
  player, both ground gaps, double-jump upper entry, all five upper jump links,
  safe fall reset, three grounded review positions and the contact-shadow checks
  described below, plus the refinement's top-plane depth, foliage silhouettes,
  outline comparison and exact restoration of original outline materials.
  The older review's fallback player/camera path also passes
  its 37 headless checks; see `base_review_checks.json`.
- **163 Forward+ checks passed:** the same coverage plus thirteen 1920 x 1080
  captures: three route views, airborne shadow, integrated rock top, foliage edge,
  collision review and six matched outline comparisons. Render checks verify
  the requested camera zoom and changes in silhouette area and near-black ink.
  See `gpu_checks.json`, `route_1.png`, `route_2.png`, `route_3.png`,
  `contact_shadow_airborne.png`, `integrated_top_review.png`,
  `foliage_edge_review.png` and `grounding_collision_review.png`.
  The six outline images and actor-only measurements are in `outline_review/`.
- The background uses the existing lake/cliff and village artwork. The source
  lake pixels extend through the deeper gaps to remove the previous backdrop's
  horizontal cutoff. No production backdrop image is modified.
- Six existing save/settings CFG files retained their hashes after verification;
  see `user_data_checks.json`. This level has no save point or progression event.
- Godot emitted a shader-cache folder permission diagnostic and shutdown
  texture/RID/ObjectDB/resource diagnostics. All verification assertions passed;
  those diagnostics remain unresolved by this scoped art delivery.

Run `start_chunk_review.ps1 -Headless` or `start_chunk_review.ps1 -Verify` to
repeat the checks. Judge the woven texture at gameplay zoom, tree/character fit,
cap contact, cliff scale and platform silhouettes while moving. Chase's visual
acceptance and production adoption remain pending. The current work list records
the scoped checkpoint; unrelated repository edits and staged deletions are
preserved outside this delivery.

## November 21 contact-shadow follow-up

Chase requested a shadow beneath the doll to connect it visually to the world.
The chunk level now draws a soft contact ellipse on the nearest authored cap
below the character, plus smaller contact marks at the projected animated heel
and toe positions. It stays on the receiving surface during flight, becomes
smaller and fainter with height, clips at cap edges and disappears over gaps.
The gradient is native Godot data and remains unlit so the daylight fixture
does not wash it out. Player geometry, animation and collision are unchanged.

Chase's local scene edits are preserved outside this checkpoint. During review
he reported reverting some additions; the on-disk scene still contained an
authored player and 0.83-zoom room camera when verification ran. The shared
startup now reuses saved Player/Camera2D nodes instead of spawning a second
pair, leaving the authored camera controller in charge of follow composition.
Without placed nodes it retains the original runtime creation path. Save and
checkpoint the final reverted scene separately; do not restore additions from
an earlier on-disk version over the user's editor state.

Verification covers one player/one camera, the shadow on all nine caps, grounded
opacity, both animated foot projections, airborne fade and fixed surface height,
ignoring overhead platforms, clipping at an edge and hiding over a gap. Existing
movement/route checks still pass. The authored camera emits Godot's physics-
interpolation callback warning; cache/shutdown diagnostics remain as noted above.
This shadow is installed in the art-test level. Production-level adoption is
separate from this visual audition.

Chase's follow-up review confirms that he likes the art style and vibrance.
Platform foliage and shrubs do not yet blend well together. The next art
refinement should unify their greens, shading/detail scale and planted edges.
No foliage replacement is included in this shadow checkpoint.

## November 21 standing-plane and foliage refinement

Chase clarified that **tan was only a way to identify the existing surface**.
Walkable tops can use the object's natural material. They need visible depth
for the feet, with the collision datum inside that plane, rather than a separate
contrasting slice. The latest sample continues grey rock across the upper/front
transition. Two rejected tan attempts remain only in the source archive.

The audition applies the new integrated-rock sample to BridgeA at runtime and
registers the three ground sprites 12 px higher relative to their fixed physics
surfaces. This places the standing line farther inside their existing top planes.
No collider, movement or user-authored scene placement is changed. Runtime
foliage comparison is limited to `Planting/LeafClusterMiddle`: V cycles original,
irregular base and hanging rim. The rim is the default. Broader foliage palette
and detail-scale cohesion still need review.

The shadow now has denser animated sole contacts and a softer surrounding
spread. Contacts follow each foot's projected row within the shallow top plane;
the rear foot is not forced onto the front foot's row. This is drawn contact
shading, independent of adding a scene light.

See [refinement sources and preparation](grounding_refinement/README.md).
The original image files and Chase's edited scene remain preserved. F6 runs the
same `woven_chunk_level.tscn`; visual acceptance and production adoption remain
pending. Current verification used the scene's fallback runtime player/camera
after Chase removed the authored pair, and confirmed one player and one camera.

## November 21 outline comparison

Chase approved trying thinner, material-colored contours after his placement
review. He then reported that the thin outline looks much better, establishing
thin width as the preferred audition direction. The colored treatment remains
the test default; O keeps all three modes available for comparison while moving.

The comparison uses the current player's actual depth-tested outline shells.
Thin modes halve each shell's existing width, retaining the finer hand/hardware
ratios. Material mode uses restrained dark wood, leather, cloth and metal colors.
Only instance-local material copies change. Original materials restore exactly,
and newly equipped visual parts receive the selected comparison mode. No player
renderer source, shader asset or equipment definition is modified.

The test now reads receiving surfaces from the actual collider shapes, so
Chase's manual Ground A cap adjustment also moves the contact shadow and debug
line. The grounding check waits for the landing pose to settle. His ground asset
and scene files remain outside this checkpoint. Current checks include those
local edits; the cap reader also supports the earlier placement without edits.

See [matched captures and comparison details](outline_review/README.md). Runtime
production adoption remains a separate step. Editor import emitted its existing
empty settings-path diagnostic; shader-cache and shutdown diagnostics remain.
