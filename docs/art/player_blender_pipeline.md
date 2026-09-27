# Current Blender assets

Active assets live under `ArtSource/Player/Blender/`.

## Character

- `imported_character/mixamo_test/Threadborne_Equipped_Animation_Test.blend`: latest separate animation test, with three transferred Mixamo clips, animated fingers, fitted weapons, and a true side-on orthographic camera. See its adjacent README. It is the source for the isolated Godot test and remains separate from the production player.
- `Src/Tests/EquippedPlayer/equipped_player_test.tscn`: isolated Godot visual test using the existing Blue Water Playground and player controller. It does not replace the production player. All 125 source frames are exported at 30 fps on fixed 450 × 600 canvases and displayed at 0.5 scale for an approximately 180 px character. Baked jump height is stripped so Godot owns world movement.
- `Src/Tests/EquippedPlayer/lookdev_comparison.tscn`: static same-pose comparison of the original render, warm/cool relighting, and relighting plus an exterior outline inside the Blue Water Playground. The approved third treatment is applied to the animated test with darker high-contrast grading and a two-pixel-at-game-scale outline.
- `Src/Tests/EquippedPlayer3D/equipped_player_3d_test.tscn`: isolated live-3D-in-2D comparison using the same playground and controller. A transparent orthographic SubViewport supplies real normals and toon-band lighting, while a CanvasItem shader supplies the exterior outline. The export-only model is conservatively decimated and the shield is consolidated for runtime testing; the source Blender file and production player remain untouched.

- `imported_character/Threadborne_2D_Shoulder_Refinement.blend`: current working rig. Corrected shoulder weights, 39,045-vertex posing preview, full-resolution 982,421-vertex render surface.
- `imported_character/imported_source_snapshot.blend`: original textured character backup.
- `imported_character/mixamo_upload/Threadborne_Mixamo_Upload.fbx`: textured, unrigged T-pose upload. This is the lighter model, not final render quality. Supporting textures and the upload ZIP are retained.
- `imported_character/shoulder_preview/`: two current review images.

Keep framing fixed across frames. The equipped test retains the full-detail render model and adds 30 finger bones. Independent skirt motion, final IK, animation-specific deformation polish and gameplay integration remain incomplete.

## Weapons

- `shield_revision/Threadborne_Sword_Shield_Rear_Fix.blend`: separate sword and shield assemblies; rebuilt shield rear with raised leather loops.
- `shield_revision/Shield_Imported_Source.blend`: unchanged original import backup.
- `shield_revision/corrected_*.png`: current weapon review views.

Move the ROOT empties to place each weapon. In the equipped test, the sword is fitted inside the right hand and the shield follows the left forearm. Shield and grapple share the left arm; the intended shield slide remains to be animated. No gameplay equipment changes have been made.

## Cleanup and recovery

On 2026-09-05, 130 obsolete files (976,059,218 bytes) were moved out of the project to `C:/Users/chase/Documents/Threadborne_Art_Archive/2026-09-05-retired-blender`. Relative project paths are preserved there for recovery. This includes the rejected V3–V8 models, old previews, redundant saves, superseded starter rig, and their one-off scripts. Nothing was permanently deleted. Original source backups, reference art, and current deliverables remain in the project.

## Working preference

Use background Blender only unless Chase asks to open a window. Never steal focus from a game. Preserve live unsaved work. Current assets are experiments, not automatically approved replacements for Godot runtime assets. Confirm downloaded asset licensing before shipping.
