# November 2 file organization and deletion review

**Organization delivered; permanent deletion and controller migration await approval.**
Start with [the file-finding guide](../../START_HERE.md). Nothing has been
permanently deleted. Moving files to staging has not freed disk space yet.

## The three locations

| Location in `C:\Users\chase\Documents` | Purpose |
| --- | --- |
| `threadbound` | Actual game, editable sources, documentation, retained checks and development media. Open this folder's `project.godot`. |
| `Threadbound - Staged for Delete` | Retired material grouped into the seven review batches below. |
| `Threadbound - Potential Use` | Download library, character/clothing candidates, recovery files and independent prototype. |

The actual game's indexed files now occupy approximately **21.3 GiB**, including
the consolidated painting workspace and retained media. That inventory excludes
Git storage and tool dependency/cache directories. The complete deletion batches
include discarded tool dependencies and contain **34.46 GiB**, excluding their
Git storage; potential use contains **4.52 GiB**. These are logical file bytes
at a snapshot in time. Godot/test caches can grow again.

## Deletion batches

| Batch | Files / approximate GiB | Why staged | Review decision |
| --- | --- | --- | --- |
| **01 Exact Duplicates** | 230 / **2.71** | SHA-256 matched a retained game file before moving. Includes repeated Blender sources, delivery copies and downloads. | Recommended for approval. Canonical sources are retained. |
| **02 Generated Work Files** | 39,195 / **20.48** | Isolated import projects, generated sandboxes, extracted temporary inputs, test scratch data, redundant engine copies, unused source-side import metadata and **4.23 GiB of orphaned main-project import cache**. | Recommended for approval; retained sources/manifests rebuild the workspaces. |
| **03 Retired Art** | 1,109 / **1.46** | Previously retired September Blender experiments, old Bellstriker/water review frames, early pavilion/ground references, superseded October 19 deliveries and the old Desktop asset collection. | Recommended if these historical studies are no longer wanted. Current user paintings and original design references are retained in the game. |
| **04 Retired Project Copies** | 18,152 / **4.23**, plus their `.git` storage | `threadbound - precodex`, `threadbound-(4.5)`, `threadbound-(4.6)`. All remain intact with Git history and working changes. | **HOLD for separate approval. Historical hand edits remain; see below.** |
| **05 Installers** | 3 / **0.55** | Two downloaded Godot ZIPs and the Blender installer. Installed applications remain intact; tooling now reuses the installed editor. | Recommended for approval if offline reinstallation copies are not wanted. |
| **06 Old Playtest Recordings** | 65 / **3.17** | Visually confirmed July-September gameplay/test captures of older presentations. | Recommended if raw historic footage is not wanted. Trailer, devlogs, current feedback and the three captures used by the progress-short builder are retained. |
| **07 Automatic Art Backups** | 24 / **1.87** | Blender/Krita automatic backups with a named primary source at least as recent. These are not deliberately named source versions. | Recommended if these older automatic saves are not wanted. Newer/orphaned backups are retained in Potential Use/Recovery. |

The duplicate copy in staging retains its original SHA-256. Of the retained
counterparts, one README subsequently received the required `outputs/` to
`ArtSource/Deliveries/` path update; its otherwise unchanged text was checked.
All retained binary counterparts remain byte-identical.

### Hold: old checkouts have uncommitted changes

These projects are not the live game, but their edits have not been reconciled
as unique versus superseded work. The directories were preserved, not reset,
stashed or cleaned. Do not include batch 04 in blanket deletion approval.

- **Pre-Codex:** old world-scene changes, rig-image changes, untracked chamber
  assets, an untracked character image and an environment-style document.
- **4.5:** modified red-platform tiles, PhantomCamera theme and project settings.
- **4.6:** project-setting changes and deleted legacy C# project/plugin files.

Their original HEADs were `71a6db2`, `ec7c540` and `763227b`, respectively.
The 4.5 checkout also points to the older repository owner. Their branch histories
and hand edits need a separate recovery decision before permanent removal.

## What remains available

- **Current doll and gameplay export:** original `PaleDollStudy/GameReadyDoll`
  and `Assets/Threadborne/Player/LocalDoll` paths remain. Rigify and source studies
  remain separate. The bundled equipped player and authored attack exports remain.
- **Current editable paintings and stamp builders:**
  `ArtSource/RecoveredLocal/BlueBiome Painting Workspace/` now contains the
  complete existing workspace. Its own AGENTS.md requires preserving user
  paintings and historical builder inputs; their relative layout is retained.
  The slate library and `Blue_Village_Connections_Review.kra` are easy to find
  through the root guide. Current modular building stamps retain their existing path.
- **Delivered source packages:** former `outputs/` is now `ArtSource/Deliveries/`.
  Duplicate Blender files point to retained sources through each affected
  package's `SOURCE_LOCATIONS.md` and the portable
  [source-location manifest](source_locations_2026_11_02.json).
- **Media:** completed trailer/devlogs, current October 30/31 feedback and
  source clips used by the social-video builder are in `Media/RecoveredLocal/`.
  New movie-writer output goes to ignored `Media/Captures/`.
- **Private records:** local editable document originals and publishing records
  are in `LocalOnly/`. Their contents were not published. The Markdown design
  documents remain authoritative; no lore was rewritten.
- **Future stock:** Potential Use separates the ten previously cataloged CC0
  packs, golem review originals, environment packs lacking saved license evidence,
  generated clothing/models, loose animation, reference art, fonts, audio and
  the standalone third-person study. Retaining a candidate does not install it.
- **Regression fixtures:** tracked `work/` inputs/reports remain. One painted
  comparison scene actually reads its source manifest there at runtime; folder
  age or an experimental name was not treated as proof of disuse.

Recovered local source, private records, raw recordings, potential assets,
deletion staging and the existing untracked doll artwork are **local only**.
The Git push backs up committed source/documentation, not these external or
ignored originals. They need a separate device/cloud backup if they are to be
protected against drive failure.

## Scope, integrity and recovery

The inventory covered Documents, Desktop, Downloads, Pictures, Videos, Music,
OneDrive, other user project locations and relevant generated-art/attachment
locations, with the C: root also inspected. The first pass indexed 79,632 files.
The final three-location scan reported zero read errors after adding long-path
support. Unrelated games, personal documents/photos, installed software, Codex
app databases/plugins/image cache and the registered Codex worktree remain in
their managed locations. Application internals are not loose game deliverables.

Windows held some old Codex directories open. Their files were moved individually
with the same relative layout rather than forcing a directory rename. All
171 verified-empty former task directories were subsequently removed with
nonrecursive deletion; no original files were permanently deleted.

Every successful move is journaled. The mover performs same-volume renames,
checks path boundaries and file identity, refuses links/overwrites, and flushes
intent/completion records. Exact duplicates additionally check both hashes.
The local evidence is under `docs/organization/local/2026-11-02/`: plans,
journals, integrity results and engine logs. These records are intentionally
excluded from the public repository. A move's original location and current
location are recorded; restore selected source files using that mapping, in
reverse order, after checking that their original paths have not been reused.
Do not overwrite newly regenerated caches or current files during recovery.

## Validation

- 24,836 completed rename records checked: no missing final destinations.
- 230 staged duplicate originals and retained counterparts checked; the one
  explicit README path edit is recorded separately. No binary mismatch.
- 57 changed/relocated Python utilities parsed, new folder-guide/source-pointer
  links checked and PowerShell utilities parsed before checkpointing.
- Godot 4.7.2 isolated-profile import completed with exit 0 and no script/parse
  errors. The first non-isolated attempt could not save sandboxed editor settings;
  the disposable workspace profile resolved those setup errors.
- Fitted-doll suite: **875 checks across 320 poses, zero failures**, headless.
- Actual Chamber scene: local doll and `--original-player` each start and run
  120 physics frames, exit 0, no script/parse errors. This is a startup/state
  check, not visual or controls acceptance.
- The game checks report the same shutdown diagnostics: six leaked ObjectDB
  instances and three resources still in use. Both Chamber runs also warn about
  Camera2D switching to physics processing. These remain recorded; this pass
  does not claim clean object teardown or investigate unrelated camera behavior.

The pre-existing character-resolution fix is checkpointed separately. No scene
tree, combat/equipment mechanics or active artwork is replaced by organization.

## Next approval

Approve deletion by batch number; keep **04 on hold** unless its historical
working changes and Git history have been explicitly considered. Until then,
all staged originals remain recoverable locally.

The [controller migration proposal](character_controller_cleanup_proposal.md)
lists the exact runtime, equipment, fixture and new timing files. It separates
the useful current 3D renderer/blends from the obsolete hidden sprite pipeline.
[AGENTS.md](../../AGENTS.md) requires: **"Wait for approval before editing"**
architectural changes. No migration work starts before that approval.

Organization source checkpoint: `2900ff9f` -
`chore: organize project sources and stage retired local files`, pushed and
remote-verified. The separate rendering checkpoint is `09e193e6`. The shared
checkout was switched to `threadbound/art-carved-cavern-stamps` by another chat;
its debug/art work is excluded from the isolated organization commit.
Acceptance: folder organization delivered for review; permanent deletion and
controller restructuring remain unapproved.
