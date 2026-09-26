# Sword and Shield Animation Source Library

This folder preserves the original animation downloads before retargeting or
editing them in Blender.

## Contents

- `source/`: 51 Mixamo animation-only FBX files, with their original filenames.
- `source_archives/Pro Sword and Shield Pack.zip`: the original downloaded pack.
- The pack's duplicate `mixamo_upload.fbx` was not extracted here. The retained
  skinned upload/master lives in the adjacent `mixamo_upload` source folder.

Do not edit the FBX files in `source/` directly. Import or link them into a
working Blender file and save retargeted actions separately. Keeping the
downloads untouched makes it possible to redo the import with different scale,
root-motion, or cleanup settings later.

## Provenance and licensing notes

- Animations were downloaded from Adobe Mixamo for the Threadborne project.
- The character mesh supplied to Mixamo originated from Tripo and must remain a
  prototype-only asset unless its commercial rights are independently cleared.
- Preserve account receipts, generation/download dates, applicable license
  terms, and any written permissions alongside release records.

This note records provenance only and is not legal advice.

## Blender review library

Open `Threadborne_Animation_Library.blend` to review the full set. It contains:

- 51 retargeted actions on `Threadborne_Rig`, using names such as `attack_1`,
  `casting_1`, `death_1`, `idle_1`, and `slash_1`.
- One sequential NLA track named `REVIEW_REEL_51_CLIPS`.
- Timeline markers at the beginning of every clip.
- The same equipped sword, forearm shield, orthographic camera, 900 x 1200
  render canvas, and 30 FPS settings used by the live 3D test.

`animation_inventory.csv` is the human-readable review list. Record the desired
gameplay name or decision beside each canonical action before Godot integration.
The JSON inventory contains the same source mapping plus vertical-motion data.
