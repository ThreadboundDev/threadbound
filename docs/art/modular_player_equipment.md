# Modular player equipment — November 2, 2026

Chase approved fitting the six new Base Gear archives to the current doll and
building reusable presentation attachments. His slot correction is authoritative:

| Slot | Components that equip together |
| --- | --- |
| Gloves | Both forearm bracers, plus the shield-arm grapple coil and needle |
| Boots | Both boots, ending at mid-shin |
| Head/chest | Cowl, tunic/sash and pants, as one outfit |
| Weapon | The base sword and shield, separately attached but one weapon item |

The separately generated clothing inputs are authoring components, not additional
equipment selections. Head/chest reaches above the elbows and knees; joint gaps
and fingers remain exposed. The existing ability manager still owns gloves,
boots and chest. Weapon presentation is independent of those three selections.

## Player and enemy presentation

November 4 decision. Keep the player live 3D on the shared rig so gear can
swap during animation and the renderer resolves overlaps between equipment
pieces. Keep the demo enemies as outlined 2D sprites. Use their clear
silhouettes and painted shading as a reference when judging the player's
materials and edges at normal gameplay zoom.

November 3 fit correction: Chase rejects the oversized, nearly knee-high boots.
The cuffs now end at 0.415 m in the rest pose, halfway between the ankle and knee,
instead of 0.625 m. The shaft shortens above the ankle to preserve foot/heel
height, with a narrower, shorter foot fit. The coverage partition now exposes
the upper shin. The saved source/export and idle/run/attack review captures are
rebuilt. All 590 export checks and 1,220 rendered equipment checks pass, including
independent midpoint-height and floor checks for both boots. Appearance acceptance
remains open. Checkpoint: `fix: fit base boots to mid-shin` on the equipment branch.

## Files and rebuilding

Original archives are preserved in `Assets/Threadborne/Equipment/Base Gear/`.
The existing equipped doll export is the verified animation/rest-skeleton input;
the previous equipped doll and editable source are preserved.

The modular body uses the repaired November 7 Blender export. Its carved wrists
and hands form a separate coverage region that the fitted Base and Blue gloves
cover with their matching hands. The older bare mesh is archived outside the
runtime asset directory.

To rebuild only the repaired body and leave fitted equipment in place, run
`--python tools/art/prepare_modular_player_equipment.py -- --body-only`. This
stages the GLB, blend and texture in `LocalOnly/Equipment/RepairedModularBody`.
Install the GLB in `LocalDoll` and save the blend in the modular equipment
source directory below. Run
`--python tools/art/verify_modular_player_equipment.py -- --body-only` to check
the installed export and editable source. The historical full exporter also
rebuilds the original gear, so use the body-only command for doll revisions.

Run Blender 5.2 in background mode with:

```text
--python tools/art/prepare_modular_player_equipment.py
--python tools/art/verify_modular_player_equipment.py
```

Run these as two separate Blender invocations. The builder writes:

- `ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/ModularEquipment/Threadborne_Doll_Modular.blend`
- `Assets/Threadborne/Player/LocalDoll/threadborne_doll_modular.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_cowl.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_tunic.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_pants.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_bracers.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_boots.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_sword.glb`
- `Assets/Threadborne/Player/LocalDoll/Equipment/base_shield.glb`

The native source, model exports, embedded/extracted textures, reports and review
captures stay local, continuing the existing treatment of this character in the
public repository. A code/documentation push does **not** back up this artwork.

The builder records source archive hashes and fits against the actual rest body.
It seeds GPU-compressed texture imports before the first Godot scan. The initial
lossless GPU imports exhausted image memory in the Chamber; matching the existing
doll's GPU compression policy resolves that failure without reducing source art.
It mirrors the boot/bracer, separates the sword/shield at their existing empty
gap, retains UVs/textures, and adds a braided coil and stowed metal needle on
`forearm.L`. All original body triangles remain in reversible coverage regions;
equipping a covering item hides its underlying shell, and removing it restores
the original body. This prevents bare toes rendering through closed boots.

## Reusing the attachment system

`equipment_visual_definition.gd` describes one item: slot, model paths, body
coverage masks and measured blade/grapple anchors. `base_gear_loadout.tres` groups
the three outfit models in one head/chest definition. Its root metadata maps the
four slots to their definitions; no local artwork is preloaded into public code.

`PlayerLive3DVisual.equipment_visuals` exposes `PlayerEquipmentVisuals`:

```gdscript
var visuals = player.live_3d_visual.equipment_visuals
visuals.equip(outfit_definition) # Replaces all head/chest components together.
visuals.equip(weapon_definition) # Independent weapon item.
visuals.clear_slot(&"boots")     # Removes visuals and restores the bare shell.
visuals.register_variant(&"gloves", 3, blue_glove_definition)
```

Each new model must be exported in the current doll's canonical rest frame with
named skin bindings. Rigid props use one bone; clothing may blend up to four.
The runtime rebinds incoming meshes to the one live skeleton, then discards
their donor skeletons. Equipment contains no animation clocks. All components
are prepared before replacing a slot, so a missing/invalid component leaves the
old item intact. A weapon swap also clears the previous sword trail.

Existing `EquipManager.equip_changed` events select registered visual variants.
Until colored gear receives authored models, those selections use the fitted
base art while retaining their existing abilities. This pass adds no abilities,
unlocks, inventory/save format or new menu. New gear definitions can be used by
the existing selection workflow as its authored variants become available.

The renderer automatically chooses the modular local doll only when the body
and every default gear export are imported. Otherwise it retains the previous
doll/bundled-model fallback. `--original-player` still selects the bundled player.
Sword trails use measured hand-local blade points; the existing gameplay rope
gets its origin from the needle on the left bracer.

## Verification and acceptance

- 590 independent saved-export checks pass over 32 skinned poses. The editable
  source reopens with all 48 clips; 62 bones, normalized weights and all original
  body triangles are retained. Maximum sampled rigid edge error is 0.00000162 m.
- 1,220 Forward+ real-player checks pass over 40 poses: one shared skeleton,
  grouped outfit replacement, rollback for missing/unskinned components, isolated
  weapon swaps, existing selection signals, reversible body masks, blade anchors,
  an actual grapple fired from the shield-arm needle, and stowed-needle
  visibility handing off to the active grapple and returning after reset.
- Eight texture extraction/import-policy checks pass with exact embedded-image
  byte equality. The final full Chamber test passes all six movement, attack,
  jump and floor assertions both headlessly and with Forward+ rendering. Actual
  Chamber idle/run/attack/jump captures are saved in the local delivery folder.
- The previous equipped doll passes all 875 checks over 320 poses. The bundled
  original-player run comparison passes all 17 checks.
- The broader `verify_base_grapple.tscn` suite has 20 existing assertion failures
  (legacy pose-library/anchor and grapple-strike expectations). All 20 reproduce
  unchanged with `--original-player`; this pass does not weaken or alter them.
- The final focused/chamber runs have no gameplay script errors or texture-memory
  errors. Existing shutdown ObjectDB/resource/texture-RID diagnostics also
  reproduce on the original-player comparison.

Validation uses Godot 4.7.2, Forward+ and the Radeon RX 6800 XT. The generated gear
is still dense source art; no frame-time budget or optimized shipping LOD is
claimed. Cloth is skinned, not simulated. Ragged hems, extreme-pose cloth/limb
clearance and shield-hand grip still require Chase's normal-speed appearance
review. T44 is delivered for that review, not marked visually accepted. The
existing controller cleanup remains a separate proposal.

## Git checkpoint

Code, typed item definitions, build/verification tools and documentation use
`threadbound/feature-modular-player-equipment`, checkpoint
`feature: attach modular base gear to player`. Local character artwork remains
outside the public source checkpoint. Unrelated organization, art and debug
working-tree changes are preserved.
