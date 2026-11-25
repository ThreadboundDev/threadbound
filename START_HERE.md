# Where to find Threadbound files

Current cleanup: [November 25 deeper asset cleanup](docs/organization/cleanup_2026_11_25_pass2.md), following [the first review](docs/organization/cleanup_2026_11_25.md).
The new review folder is **inside this repository**: `Staged for Delete/2026-11-25-pass2/`; open `START_HERE.md` there.
Nothing from this pass has been permanently deleted.

These are the game-file locations previously recorded in `C:\Users\chase\Documents`:

| Folder | What belongs here |
| --- | --- |
| **threadbound** | The actual Godot game, current editable art, project documents, checks and retained development media. Open `project.godot`. |
| **threadbound/Staged for Delete/2026-11-25** | Current deletion review: old scene experiments, unused assets, superseded deliveries and art backups. |
| **Threadbound - Potential Use** | Downloaded packs, future character/clothing candidates, recovery files and the independent third-person prototype. Nothing here is installed merely by being retained. |

Inside the actual game:

- **Play/edit the game:** `project.godot`, then `Src/` for scenes and scripts.
- **Current demo:** `Src/Environment/World/Chamber Of The First Weave - Demo 2.0.tscn`.
  Keep the original Chamber scene because Demo 2.0 inherits it.
- **Blue reference level:** `Src/Environment/BlueBiome/blue_lakeside_test.tscn`.
  One hidden water fixture remains under `tools/fixtures/blue_layouts/` for the bank-dive regression.
  The 23 obsolete fixture layouts are in deletion review.
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
- **Chamber Krita sources:** `ArtSource/Chamber/Krita/`.
- **Current shore painting and atlas:** `ArtSource/Deliveries/WovenPaintingKit/`.
- **Other editable art and retained deliveries:** `ArtSource/`, including `Deliveries/`.
- **Current priorities:** [work list](docs/project_status_and_worklist.md).
- **Design/lore and verification reports:** [docs index](docs/README.md).
- **Devlogs, trailer and recent feedback:** `Media/RecoveredLocal/`.
- **Private/local records:** `LocalOnly/`; these must not enter public Git.
- **Verification inputs and evidence:** `work/`; [folder guide](work/README.md).
- **Runnable maintenance and checks:** `tools/`; scratch results go in ignored `tmp/`.

`RecoveredLocal`, `LocalOnly`, recordings, potential assets and the review folder's
`LocalOnly/` and `Uncommitted/` portions are local files, **not backed up by a Git push**.
The review folder's `Tracked/` portion is versioned. Existing untracked doll work is also local. Copy these to a separate backup device before permanent deletion or
machine replacement. The organization report distinguishes local moves from
the committed source/documentation checkpoint.

[Organization report and deletion review](docs/organization/organization_2026_11_02.md).
[Completed player/Blue cleanup and validation](docs/organization/runtime_cleanup_2026_11_02.md).
