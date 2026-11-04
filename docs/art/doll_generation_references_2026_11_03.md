# Consistent doll T-pose references — November 3, 2026

**Superseded for character generation.** Chase clarifies that the requested input
is generated concept artwork, not the in-game model rendered in a T-pose. Use the
[corrected generated concept package](../../work/generated-doll-concept-2026-11-03/README.md)
for new full-clothed generations. The native-render package below remains only a
technical fit/reference record; it is not the selected visual direction.

Chase requests front and back references of the actual doll, both bare and in
the current base outfit, to keep the character and its parts consistent across
future clothing generations. These four images are direct Blender renders of
the same existing 3D source, with no character redraw or shape edits.

## Local reference package

Folder:
`ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/GenerationReferences_2026_11_03/`.

| Files | Use |
| --- | --- |
| `master_bare_front.png`, `master_bare_back.png` | Authoritative body identity, blank stitched head, limb proportions and joint construction |
| `base_outfit_front.png`, `base_outfit_back.png` | Current cowl, tunic/sash, breeches, bracers and mid-shin boots on that exact doll |
| `manifest.json` | Source/body/garment hashes, all 62 rest-joint positions, image hashes and camera settings |
| `outfit_reference_prompt.txt` | Reusable identity constraints for preparing new clothing reference images |
| `Threadborne_Reference_Master.blend` | Separate editable reference scene, opening on the clothed front view |
| `Threadborne_TPose_Front_Back_References.zip` | Four PNGs, manifest, prompt and usage README |

All four PNGs are 2048x2048, using the same orthographic scale, camera center,
rest T-pose, exposure and symmetric studio lighting on white. The back views
are rendered from behind the same model. Hands and the blank head stay visible;
sword, shield and grapple hardware are omitted for the character-generation
input. The mid-shin boot correction is retained.

For a starter full-character Tripo job, use the two **base outfit** images as
the views of that one clothed object. Keep the two bare images as the body
master for designing/fitting every later style. Do not mix bare and clothed
images as four views of one clothed object. The text prompt is for preparing
future outfit images, not a replacement for the matched image inputs.

Identical references do not guarantee identical generated meshes. Each result
still needs fitting to the same body dimensions and skeleton before section
boundaries can interchange. These references do not install replacement
equipment or resolve the open animated-clipping report.

## Rebuilding and validation

Run Blender 5.2 in background mode with:

```text
--python tools/art/render_doll_generation_reference.py
```

Input:
`ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/ModularEquipment/Threadborne_Doll_Modular.blend`.
The original source is not saved over. The renderer records and verifies its
file hash, checks identical body/garment geometry hashes after each view, retains
62 bones and 48 actions, and checks ZIP integrity and exact packaged file bytes.
All four views are visually inspected for pose, framing, detail and front/back
consistency. Reference integrity is checked independently after saving.

The character images, archive, manifests and reference Blender scene remain
local under the existing public-repository treatment of the doll. The Git
checkpoint contains the reproducible rendering tool and documentation; it
does not remotely back up the reference artwork. Existing runtime code,
equipment models and unrelated working-tree edits are preserved.
