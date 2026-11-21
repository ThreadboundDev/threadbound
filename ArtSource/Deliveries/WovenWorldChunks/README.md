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

- **105 headless checks passed:** ten image/scene deliveries, visible cap
  alignment, full-depth bodies, all nine placed surfaces supporting the actual
  player, both ground gaps, double-jump upper entry, all five upper jump links,
  safe fall reset and three grounded review positions.
- **109 Forward+ checks passed:** the same coverage plus three 1920 x 1080
  route captures and a collision review. See `gpu_checks.json`, `route_1.png`,
  `route_2.png`, `route_3.png` and `collision_review.png`.
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
