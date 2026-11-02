# Doll gameplay integration — November 2, 2026

Chase requested the new textured doll's bones and weights checked, with the
existing sword, shield and animations attached for gameplay review before
generating clothing or other gear. This delivers a local game candidate from
the latest 25k finger-cleanup/Rigify prototype. Visual acceptance remains open.

## Delivered

- Editable gameplay source:
  `ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/Threadborne_Doll_GameReady.blend`.
- Equipped game export:
  `Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb`.
- Local build/export/engine reports and actual Godot captures in
  `ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/`.
- Rebuild with Blender 5.2 and `tools/art/prepare_doll_game_model.py`;
  independently inspect the saved export with `tools/art/verify_doll_game_model.py`.

The native Rigify prototype and unrigged source remain intact. The game version
uses the existing 62 bone names, hierarchy and rest rotation bases, with joint
origins fitted to the doll. The 400-bone control rig is not exported into the
game. Body proportions are uniformly scaled to game units; palms turn into the
game rig's rest convention. Rigid shell weights are retained, hand transitions
are normalized and limited to four influences, and finger curls are fitted to
the existing equipment. The source mesh has 25,022 vertices; the GLB has 49,869
after UV/normal splits. That is not a second mesh or a subdivision pass.

The original sword, shield and grapple meshes and attachment hierarchy are
carried over. No weapon geometry, hitbox, damage, timing, movement, equipment
system or gameplay scene is changed. All 48 main clips are exported with their
names and durations (within one source frame). Separately loaded authored attack
position tracks are rebased to the fitted joint origins, and their finger curls
match the doll's source clips. Existing upright posture, run arm motion, water
blending, grapple sampling and sword trail attachment code remain in use.

The doll gets a softer, less exposed material response so its pale texture
retains wear under the game's lights. This adjustment only targets its mesh.

## Playing and comparison

Normal local play and editor previews select the doll when its imported export
is present. A checkout without the local export uses the bundled original model.
`--original-player` after Godot's `--` selects the original for comparison.
The `model_scene` export can also select a fitted scene explicitly.

From the repository in PowerShell:

```powershell
./tools/player_animation/start_doll_preview.ps1
./tools/player_animation/start_doll_preview.ps1 -Blue
```

The launcher uses the real Chamber or Blue test room. Normal tutorial/welcome
behavior is retained. The automated Chamber capture temporarily omits the
welcome overlay and disables tutorial prompts in its own instance so it can
exercise movement, attacks and jumps without input being paused. It does not
save a scene change or use Chase's normal save profile.

## Validation and limits

- 73 independent saved-export checks pass, including weights, embedded textures,
  62 joints, all 48 clips, finite evaluated skinning and rigid edge lengths.
- 67,855 rigid-shell edges are measured at each of 32 animation samples. Maximum
  measured length error is below 0.000001 metres. Blended finger joints are
  intentionally excluded from the rigid-edge claim.
- 875 Forward+ Godot checks pass over 320 poses across the installed animation
  library, including fitted limb lengths, separately authored attack offsets,
  weapon attachment access and the matching lower-body sampler.
- The real Chamber loads the doll by default. Actual input moves the player,
  triggers an attack, jumps and returns to the real floor. Idle/run/attack/jump
  captures are saved locally at normal gameplay framing.
- The original-player run regression passes all 17 checks with the comparison
  flag. Validation used Godot 4.7.2 / Forward+ on the Radeon RX 6800 XT;
  the unchanged-original regression ran headless.

The checks are not a claim of final animation, mechanical joint clearance or
clothing fit. Individual fingers and the reused shield straps still merit
close-up art review, and the continuous generated finger surfaces deform near
joints. The existing high-poly weapons are retained; no performance target is
claimed. The runners emit resource/RID cleanup warnings at shutdown; the
original-player runner also reports resources left at shutdown. No gameplay
script error occurs in the final successful doll runs.

Chase's moving visual acceptance is required before marking T42 complete or
starting the gear generation/fitting pass.

## Git checkpoint

Checkpoint: `art: integrate local doll with game rig and equipment`, on
`threadbound/art-pale-doll-model-study`. Runtime support, build/validation tools
and these notes are committed and pushed. The character source, exports,
textures and screenshots remain local/untracked, continuing the previous
recorded treatment of the Tripo character in this public repository. This
checkpoint does **not** remotely back up that artwork. Existing unrelated
untracked editor/import files are preserved.
