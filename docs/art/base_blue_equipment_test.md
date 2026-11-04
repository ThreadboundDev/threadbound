# Base and Blue equipment test

On the art checkout, run Godot with `--path . -- --equipment-art-test`, or set
`--equipment-art-test` in Godot's editor run arguments. Open **Inventory →
Equipment** and click the Base or Hermit icon for each of **Gloves**, **Boots**
and **Head / Chest**. The glove icons show their coil or reel and hook. The
Head / Chest item includes the head, headgear, top and trousers. Swapping any
of the three slots updates the doll in gameplay. The test argument makes both
sets available immediately. Without the argument, Blue uses the existing
Balance unlock.

The two suits share cuts at the rig elbows (X ±0.4427) and mid-shin boot cuffs
(Z 0.415). Each fitted glove pair uses the existing wooden hands. Its stowed
hardware includes a separate needle or hook on the shield-arm bracer, and the
live grapple origin follows the fitted glove. Casting hides the stowed hook
and uses the existing active rope and projectile art. Blue's ribbons are
weighted to the rig. Secondary cloth simulation and an updating inventory
portrait are outside this fitting pass.

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

### Close-up feedback

During gameplay in an equipment art-test session, scroll up to zoom in (up
to 16×), scroll down to zoom out, or press `\` to reset. Use **Ctrl+F1**
for screenshot feedback or **Ctrl+F2** for a movement clip. The feedback
report captures the current camera zoom.

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
