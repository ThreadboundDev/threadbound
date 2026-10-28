# CC0 house and working-villager comparison

October 28, 2026. Chase explicitly requested a side-by-side house/villager study
using the downloaded character rig, clothes and animation stock, with our own
table-work motion. **Delivered for appearance/motion review.** This does not
accept a full 3D conversion or replace existing house/villager scenes.

## Review files

- [House + villager side-by-side](../../work/cc0-house-villager-2026-10-28/renders/house_villager_side_by_side.png).
- [Four-second house/work loop](../../work/cc0-house-villager-2026-10-28/renders/house_villager_motion.gif).
- [Worker detail comparison](../../work/cc0-house-villager-2026-10-28/renders/worker_side_by_side.png).
- [Four-second worker detail loop](../../work/cc0-house-villager-2026-10-28/renders/worker_motion.gif).
- [Editable Blender scene](../../work/cc0-house-villager-2026-10-28/CC0_House_WorkingVillager_Comparison.blend).

Left: the existing `workshop_v2.png` exterior and `boatwright.png` work pose,
composed from their existing atlas cells without changing either source file.
That work pose is held **static** in both GIFs. It is not a demonstration of the
old live 3D villager's animation. Those historical painted assets have their
original image-generation provenance; no new generated imagery was used here.

Right: new CC0-source model assembly with an animated peasant worker. House
shapes, lighting and camera differ from the painted art. This is a presentation
study, not a pixel-matched conversion of one house or a game performance test.
The worker close-up is enlarged to inspect contact. Judge motion at normal speed
before drawing conclusions from still poses.

## Sources and adaptation

Exact original ZIP hashes, selected members and working-copy hashes are recorded
in [source_manifest.json](../../work/cc0-house-villager-2026-10-28/source_manifest.json).
Bundled CC0 notices are retained in the task's `licenses/` folder. Original
archives remain in the external asset library. This study uses:

- P09 Medieval Village MegaKit: modular plaster/wood walls, door/frame/window,
  floor and roof geometry. Assemble one porch workshop and unify its materials
  around walnut, parchment and slate. Model-source trim remains editable.
- P10 Modular Character Outfits: male peasant mesh, clothes and master 65-joint rig.
- P13 Universal Base Characters: head/neck, brows/eyes, simple-parted hair and beard.
  Remove the hidden body by head/neck skin weights to avoid shoulder/clothing
  intersections. Relink two known upstream normal-map filename errors in the
  extracted JSON working copy; original ZIP is unchanged.
- P12 Universal Animation Library: retain `Idle_Loop` as a reference and transfer
  upper-body breathing through named bones with rest-axis compensation. The
  two rigs differ by up to ~0.212 radians in rest orientation, so matching names
  alone are insufficient. Source translations are not copied.
- P03 Fantasy Props: workbench, rope, bucket and crate.
- P07 KayKit Resource Bits: timber and textile stacks.

Authored additions: a canvas apron, indigo patch, flax stitches/ties, workpiece,
small hand-plane and its grips. The planing loop contains two restrained strokes
over 96 frames / four seconds at 24 FPS. Hands follow authored wrist targets;
arm motion is solved and baked to ordinary bone keys. Feet/root remain fixed.
Subtle torso breathing, lean and downward attention support the working pose.
The source idle action and final work action are retained in the Blender file.

All preview source and output live under a task-level `.gdignore`, keeping Godot
from importing the scene, textures, renders or temporary source packs. Images
are packed into the delivered Blender file so it opens without temporary files.
No runtime resources, current NPCs, house assets or production scenes changed.

## Validation and limits

[Saved-scene verification](../../work/cc0-house-villager-2026-10-28/verification.json)
checks all 97 poses including the repeated loop endpoint: 65 joints, correct
work action, wrist targets within 1 mm, fixed feet within 0.1 mm, matching first
and repeated endpoint bone poses/tool positions, and packed image dependencies.
The rendered stills and representative start/mid/end frames were inspected for
clipping, hands/tool contact, planted feet, text layout and clear presentation.
Each GIF contains 48 rendered frames over exactly 4,000 ms and repeats.

The 3D source is an initial look, with soft study lighting and simplified material
colors. It needs an in-room contour/palette/lighting pass if selected. The apron
is a simple rigid attachment and is mostly behind the bench. Head/hair, hand
grip/finger polish and material detail remain reviewable. This is not a final NPC
or evidence of runtime frame time. No Godot import, controller integration,
interaction, occlusion or gameplay regression tests were run for this art-only
delivery. No permanent visual-direction acceptance is inferred from verification.

For a later approved trial, compare the preferred look in the actual room against
the existing player and terrain. The 3D source could also supply rendered 2D
sprites; keeping it does not require converting the game to live 3D.

## Reproduce

Use the bundled Python for preparation/packaging and Blender 5.2 for build/check:

```text
python tools/art/prepare_cc0_house_villager_comparison.py
blender -b --factory-startup --python-exit-code 1 --python tools/art/build_cc0_house_villager_comparison.py -- --animate
blender -b --factory-startup --python-exit-code 1 --python tools/art/verify_cc0_house_villager_comparison.py
python tools/art/package_cc0_house_villager_comparison.py
```

Preparation requires the six selected original CC0 ZIPs at the cataloged external
library path. Extracted working copies and raw frame PNGs stay under ignored
`temp/`; only deliberate previews, source scene, provenance and results are kept.
The builder saves through a fresh temporary blend, then copies the generated
result into the delivery path, avoiding a failed Blender overwrite/backup rename.

## Audio and VFX clarification

**NOX Essentials remains available: all 1,644 sound files.** The cleanup removed
two custom-license **music** packs, not this CC0 SFX collection. We can audition
existing wood/rock/water footsteps and water/cave ambience before collecting more.
No sounds or VFX were installed in this visual comparison.

Useful additional searches: `CC0 rope creak tension`, `CC0 cloth tear fabric
stretch`, `CC0 underwater bubbles swimming`, and `CC0 stylized thread unravel
VFX spritesheet`. For VFX, look for editable timing, transparent frames or an
editable shader, a side-view silhouette, and limited bright pixels so effects
do not hide attack tells. These are search targets, not verified pack offers.
Music remains a collection gap under the CC0-only rule.

Checkpoint: `art: compare CC0 house and animated clothed villager`.
