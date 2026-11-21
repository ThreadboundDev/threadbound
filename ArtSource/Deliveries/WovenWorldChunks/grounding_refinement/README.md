# Grounding refinement — November 21, 2026

Additive art-test variants, awaiting Chase's in-game review. The direction is
continuous natural material with a visible standing plane, irregular foliage
endings and stronger contact at the boots. Tan tops are not a requirement.

| Candidate | Runtime size | Placement |
| --- | --- | --- |
| `foliage_soft_base` | 759 x 277 | Planting anchor Y=252; staggered complete tips |
| `foliage_rim` | 759 x 362 | Anchor Y=264; leaves hang across the leading edge |
| `platform_integrated_top` | 448 x 132 | Standing datum Y=16 inside reviewed top Y=6–26 |

The platform limits are visual annotations for this specific image, independent
of its hue. They are not a universal minimum pixel depth. Judge the feet and
surface together at the intended gameplay camera.

`generation_manifest.json` preserves full prompts and references. `sources/`
contains the built-in image_gen outputs; its backend version is not exposed.
The two tan-platform attempts are rejected sources, absent from runtime assets.
They illustrate the earlier mistaken emphasis on surface color and separate
cap thickness.

Run `tools/art/woven_world/prepare_grounding_refinement.ps1` from the repository
root to reproduce alpha trimming, proportional resizing, metadata and native
placeable scenes. Preparation does not redraw or blend the generated art.
Runtime files are in `Assets/BlueBiome/Art/WovenWorldChunks/GroundingRefinement/`.

The chunk test auditions one rock platform and one foliage cluster at runtime.
V compares all three foliage modes. Existing source assets and the user's scene
edits are preserved. Matching the entire shrub/terrain palette and detail scale
is still pending; this pass addresses silhouette placement and grounding.

The parent delivery contains the 132 headless / 139 Forward+ check reports and
actual in-game close-ups. Cache-permission and shutdown resource diagnostics
remain documented there. All assertions passed; final visual acceptance remains
with Chase.

## Chase's placement review

`chase_ground_a_placement_reference.png` is Chase's in-game screenshot after his
manual Ground A collision adjustment. He reports the placement is much closer
and the shadow helps. This is the reference for feet sitting within the top
plane. His current saved Ground A collider begins 4 px below its earlier datum;
the asset and edited level are preserved outside this documentation checkpoint.
The prior automated reports predate this manual edit and were not rerun for a
documentation-only update.

Either new foliage variant is preferable to the hard clipped original. Across
placed props, avoid an exposed cropped baseline; make bases contact the support
intentionally. Matching foliage colors/detail is still pending. The dark player
outline is a suspected remaining source of separation, awaiting a controlled
visual comparison before changing player rendering.
