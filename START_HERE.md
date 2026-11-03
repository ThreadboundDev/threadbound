# Where to find Threadbound files

These are the three game-file locations in `C:\Users\chase\Documents`:

| Folder | What belongs here |
| --- | --- |
| **threadbound** | The actual Godot game, current editable art, project documents, checks and retained development media. Open `project.godot`. |
| **Threadbound - Staged for Delete** | Approved non-video cleanup is complete. Remaining: old checkouts on hold, preserved recordings/animations, and batch 08 retired player sprite files staged November 3. Read its `START_HERE.md`. |
| **Threadbound - Potential Use** | Downloaded packs, future character/clothing candidates, recovery files and the independent third-person prototype. Nothing here is installed merely by being retained. |

Inside the actual game:

- **Play/edit the game:** `project.godot`, then `Src/` for scenes and scripts.
- **Current Blue test level:** `Src/Environment/BlueBiome/blue_lakeside_test.tscn`.
  Historical layouts are hidden under `tools/fixtures/blue_layouts/` for regression checks.
- **Current player:** `Src/Characters/Player/`; its README explains the live 3D avatar,
  texture-free action clock, physics and equipment anchors.
- **Current doll:** `ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/`
  for Blender source; `Assets/Threadborne/Player/LocalDoll/` for the local game export.
- **Current clothing generation inputs:** `work/pale-doll-clothing-prep-2026-11-02/`.
- **Current modular building stamps:** `ArtSource/BlueBiome/Placeables/BuildingStampsV1/`.
- **Existing village Krita library and paintings:**
  `ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack/`.
  Use `slate_village_library/Blue_Village_Slate_Library.bundle`; the saved current
  painting is `cave_connections_v1/Blue_Village_Connections_Review.kra`.
  Keep this workspace's relative layout: its builders depend on their inputs.
- **Game-ready textures/models/audio:** `Assets/`. Do not replace these with downloads directly.
- **Other editable art and retained deliveries:** `ArtSource/`, including `Deliveries/`.
- **Current priorities:** [work list](docs/project_status_and_worklist.md).
- **Design/lore and verification reports:** [docs index](docs/README.md).
- **Devlogs, trailer and recent feedback:** `Media/RecoveredLocal/`.
- **Private/local records:** `LocalOnly/`; these must not enter public Git.
- **Verification inputs and evidence:** `work/`; [folder guide](work/README.md).
- **Runnable maintenance and checks:** `tools/`; scratch results go in ignored `tmp/`.

`RecoveredLocal`, `LocalOnly`, recordings, potential assets and deletion staging
are local files, **not backed up by a Git push**. Existing untracked doll work is
also local. Copy these to a separate backup device before permanent deletion or
machine replacement. The organization report distinguishes local moves from
the committed source/documentation checkpoint.

[Organization report and deletion review](docs/organization/organization_2026_11_02.md).
[Completed player/Blue cleanup and validation](docs/organization/runtime_cleanup_2026_11_02.md).
