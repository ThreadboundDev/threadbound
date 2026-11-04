# Loomed and Hermit — fitted Blender master, November 4, 2026

Chase requested one Blender shell fitted to the actual doll and checked against
both the Base cowl and Hermit brim, with Loomed and Hermit finishes carrying
their own black eye markings, gold repairs and matching embroidery.

The local delivery is `LocalOnly/Equipment/Masks/Threadborne_Master_Mask.blend`.
The three shell objects (`MASTER_Shell`, `Loomed_Shell`, `Hermit_Shell`) share
one mesh datablock and UV layout. The 2.4 mm porcelain shell has real almond
eye cuts and recessed black liners over the doll's otherwise faceless head.
All mask meshes are rigidly weighted to the existing `head` bone.

Loomed has wing-and-tear eye paint, an interlocking brow knot, and a long
diagonal gold repair. Hermit has swept eye paint, a slate-indigo wave, and a
separate repair confined to the lower cheek and chin. The gold lips and seams
remain editable geometry. The painted finishes use separate 2048 px base-color
maps; the native file also retains the hidden pigment source geometry.

The source file contains the unchanged bare doll and both fitted outfits as
references. Toggle the collections and object visibility to compare finishes;
the saved view shows Loomed with the Base cowl. The plain master is hidden.
Paint-source objects have a `purpose` property identifying them; they are not
part of the finished visible mask or its export.

## Delivery files

All paths below are relative to `LocalOnly/Equipment/Masks/`:

- `Threadborne_Master_Mask.blend`: packed editable scene with fitting references.
- `loomed_mask.glb`, `hermit_mask.glb`: self-contained, head-skinned mask exports.
- `loomed_basecolor.png`, `hermit_basecolor.png`: projected finish maps.
- `porcelain_basecolor.png`: common plain glaze texture.
- `loomed_embroidery_repeat.png`, `hermit_embroidery_repeat.png`: horizontal
  three-repeat strip studies, 1800 × 300 px, including thread and cloth.
- `fitted_review.png`, `finish_review.png`: side-by-side review sheets.
- `<finish>_front.png`, `<finish>_three_quarter.png`: isolated mask views.
- `<finish>_base_fit.png`, `<finish>_blue_fit.png`: all four finish/headgear pairs.
- `<finish>_outfit.png`, `<finish>_embroidery_fit.png`: complete rest outfits
  and stitching close-ups. Loomed sits on the Base waist wrap; Hermit sits on
  the hanging front sash. Stitch geometry inherits the actual cloth skin weights.
- `fit_report.json`, `verification.json`: measured fit and saved-file checks.

The strips are orthographic appearance studies with their cloth backgrounds,
not production alpha/normal/roughness decal atlases. The editable repeat geometry
is retained in the Blender file for that later material pass.

## Rebuild and verification

Run these as separate Blender 5.2 background invocations from the repository root:

```text
blender --background --factory-startup --python-exit-code 1 --python tools/art/build_loomed_hermit_masks.py
blender --background --factory-startup --python-exit-code 1 --python tools/art/verify_loomed_hermit_masks.py
```

Then run `tools/art/package_loomed_hermit_review.ps1` with PowerShell on Windows.
The builder reads `LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend`; it does
not modify that source. Pass `-- --no-render` to omit the review captures.

The saved-file verifier checks shared mesh identity, separate packed finish
textures, a watertight shell, unchanged donor geometry, head weights, seven
rest/turn/tilt poses against all three reference heads, and reimports both GLBs
in fresh scenes. It also checks the actual GLB mesh count so Blender's generated
bone widgets are excluded from skin validation without skipping exported meshes.

Validation on November 4: **63 checks pass**. There are zero shell/reference
triangle intersections across all seven tested poses. The shared shell has
8,410 vertices and 16,824 triangles. This is the editable art-resolution master;
shipping LOD and frame-time budgeting are not claimed. Both final review sheets
were inspected after correcting the eye-edge shading and pigment projection.

This is an art delivery for Chase's review. No runtime scenes, equipment
selection, passives, inventory or saves change. Normal-speed in-game animation,
gameplay-zoom readability and visual acceptance remain open. T44 stays in review.

## Git and local artwork

The builder, verifier, review-sheet script and this handoff are checkpointed on
`threadbound/feature-modular-player-equipment` with
`asset: build fitted loomed and hermit mask master`.
The Blender source, exports, textures and captures remain local under the
existing [character-art policy](modular_player_equipment.md). A code/documentation
push does **not** back up the generated artwork.
