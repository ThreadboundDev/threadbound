# Base and Blue equipment test

On the art checkout, run Godot with `--path . -- --equipment-art-test`, or set
`--equipment-art-test` in Godot's editor run arguments. Open **Inventory →
Equipment** and click the Base or Hermit icon for each of **Gloves**, **Boots**
and **Head / Chest**. The glove icons show their coil or reel and hook. The
Head / Chest item includes the head, headgear, top and trousers. Swapping any
of the three slots updates the doll in gameplay. The test argument makes both
sets available immediately. Without the argument, Blue uses the existing
Balance unlock.

The two suits share bracer joins just beyond the elbows (X ±0.5177) and mid-shin boot cuffs
(Z 0.415). Each fitted glove pair uses the existing wooden hands. Its stowed
hardware includes a separate needle or hook on the shield-arm bracer, and the
live grapple origin follows the fitted glove. Casting hides the stowed hook
and uses the existing active rope and projectile art. Blue's ribbons are
weighted to the rig. The sleeves have the approved secondary motion prototype
described below. The inventory now shows an independent idle preview of the
current character, updating as gear and masks change. Glove icons show the
bracer, wooden hand and attached grapple together. See the
[inventory preview delivery and checks](inventory_character_preview_2026_11_05.md).

The grapple is part of the Gloves item. Separate 3D authoring lets the reel
and hook fit the bracer and animate independently. Swapping Gloves swaps the
bracers, grapple visuals, and grapple behavior together.

The original archives are `base gear model.zip`, `lasso rope 3d model.zip`,
`Blue gear.zip` and `fantasy weapon 3d model.zip`. The builder expects all four
in the same directory and uses the existing local fitted doll as its rig and
hand reference. For a local rebuild from the project root, run Blender with
`--background --factory-startup --python-exit-code 1 --python tools/art/prepare_base_blue_equipment.py -- <archive-directory>`.
Keep the generated GLBs and icons in
`Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/` and the editable
Blender file and review captures in `LocalOnly/Equipment/BaseBlue/`, following
the local art policy in [Modular player equipment](modular_player_equipment.md).

Run the Godot verification with `--path . --script res://tools/player_animation/verify_base_blue_equipment.gd -- --equipment-art-test --no-debug-feedback`.
It exercises all eight combinations through the inventory, checks rig and
weapon bindings, and casts both grapples from the fitted anchors. A rendered
run also captures idle, running, and casting poses and the populated inventory.
Gameplay art review is open.

## Blue sleeve motion

The November 5 approved prototype adds spring chains to the hanging portions
of both Blue sleeves, with a chest-bound torso collider. The upper fabric stays
attached to the arms. Equip Blue Head / Chest to enable it; Base Head / Chest
disables it. Swaps, teleports, long frames, and door transitions reset inertia.
Restart the game after Godot imports the rebuilt `blue_head_chest.glb`.

The inventory verification now passes 287 checks, including moving sleeves in
idle, run, casting, and grapple swinging with both facing directions. Review
`blue_sleeve_*` captures and `godot_sleeve_motion_report.json` beside the Blender
source. The `rigid` and `settled` captures freeze the same pose for comparison.
Sampled fabric penetration into the torso proxy fell about 82% in the rendered
comparison. Broad cloth can still intersect between spring points; this is a
bone approximation and needs Chase's moving review. Ribbons and the sash retain
their existing rig weights. See the [approved scope and validation](blue_cloth_motion_proposal_2026_11_05.md).

### Close-up feedback

During gameplay in any development/editor run, scroll up to zoom in (up
to 16×), scroll down to return toward the saved gameplay zoom, or press `\`
to reset. Zoom does not require `--equipment-art-test`; that argument only
unlocks the equipment for review. Restart a running game to load code changes.
Zoom input is inactive while paused. Use **Ctrl+F1**
for screenshot feedback or **Ctrl+F2** for a movement clip. The feedback
report captures the current camera zoom.

November 4 zoom fix: removed the art-test launch requirement. The headless
`tools/player_animation/verify_gameplay_zoom.gd` regression exercises wheel
input, multi-tick scrolling, both bounds, reset, pause and missing-camera
handling. It passes nine checks with and without the art-test argument.

## Blue deformation follow-up

The November 4 Chamber report showed full Hermit gear in idle and flagged
deformation at the arms and between the legs. The Blue fitting pass now blends
the broad sleeves from chest to upper arm, maintains the shared elbow weights
at the cut, and raises the generated trouser bridge from near knee height
toward the crotch. The inner cloth blends back into the pelvis and thighs.
The shared rig, cut planes, and animation clips are reused.

The revised local assets passed 238 Godot checks across all eight combinations.
Rendered idle, run, and cast poses are in `LocalOnly/Equipment/BaseBlue/`.
The prominent dark wedge is gone in the sampled run. Some texture stretch
remains on the inner thigh in the wide casting stance. Restart the art-test
session to load the new meshes for hands-on review.

## Shared doll fit follow-up

Base and Blue use the same faceless wooden head and hands from the fitted
master doll. The open bracer cuff is centered on the rounded wrist profile
and overlaps it slightly. Both retain their imported elbows. The shared bracer cut is
on the forearm side of those joints to keep the elbow geometry with Head /
Chest. Base retains the imported trouser hem, exposed shin, and boot rim
shape, with the knee pivot covered by the trousers. Open the rebuilt
`LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend` for the updated rigged
meshes and the adjacent rest and posed captures.

The Base cowl sits lower and closer to the neck. Its weights follow the
chest and blend across the shoulder into the upper arm. This keeps the folds
from climbing with the head during turns. The fit can be compared in the
Base idle, run, and casting captures in the same review directory.

## Forearm shield

The equipped shield uses the imported face and rebuilt backing, with two
leather straps and pads fitted to the left bracer. The complete shield
follows `forearm.L`, leaving the hand free. Base and Blue use the same
shield and keep their own stowed grapple hardware.

The current revision uses Chase's `medieval sword 3d model.zip` download.
To rebuild both weapons, run Blender with
`--background --factory-startup --python-exit-code 1 --python tools/art/fit_revised_base_weapons.py -- <path-to-archive>`
after the gear is fitted. This fits the revised sword and shield face, trims
the shield's rear handle, then fits the two forearm bands and padding.
The tools update `base_sword.glb`, `base_shield.glb`, and the measured sword
trail anchors. The shield fitting step saves a
Blender review file and renders in `LocalOnly/Equipment/Shield/`. Restart the
art-test session after import to review it with both gloves.
