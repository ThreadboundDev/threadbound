# Project Folder Cleanup - 2026-07-25

## Outcome

The cleanup branch starts from the completed combined-playtest commit:

- Branch: `threadbound/chore-project-folder-cleanup`
- Base commit: `23333330545f6a0c8c0e1221a22125f75c05a63b`
- Desktop quarantine: `C:\Users\chase\Desktop\Threadbound Staged for Delete`
- Quarantined files: 1,503
- Quarantined size: 165.39 MiB

Files were moved out of the Godot project rather than permanently deleted.
`MANIFEST.json` in the Desktop quarantine preserves every original project-
relative path, byte count, SHA-256 hash, and staging reason. A copy is tracked
at `cleanup_reports/quarantine_manifest_20260725.json`.

## What Was Quarantined

| Category | Files | MiB |
| --- | ---: | ---: |
| No remaining static project reference | 409 | 112.74 |
| Non-runtime concept art | 54 | 49.39 |
| Unsupported or unused controller glyph families | 878 | 2.25 |
| Phantom Camera example content | 91 | 0.84 |
| Obsolete rigging system | 56 | 0.14 |
| Previous delete-candidate staging folder | 8 | 0.02 |
| Obsolete archetype archive | 7 | 0.02 |

The obsolete rigging category includes the Threadborne deform-rig scene,
editor handle, archived rig scene, and the complete SoupIK addon. SoupIK was
also removed from the enabled editor-plugin list.

The previous `cleanup_reports/delete_candidates_20260702/` staging folder was
folded into the Desktop quarantine as requested.

## Explicit Keeps

The following were protected even when not currently reachable from the main
scene:

- Blue, red, and yellow decoration atlases and their editable source files
- Red brazier sprite sheet and source image
- Supported dynamic input-glyph families:
  - Keyboard and mouse dark glyphs
  - PS5
  - Xbox Series
  - Switch
  - Steam Deck
- Current player-animation normalization inputs and generated authoring sheets
- The two canonical player proportion/palette/weapon reference images
- Runtime and export icons

## Audit Method

`tools/project_cleanup/audit_unused_resources.ps1` performs a repeatable audit
that:

- Resolves `res://` paths and Godot `uid://` references.
- Traverses the main scene, autoloads, export configuration, and resource
  dependencies.
- Accounts for dynamically assembled supported input-glyph paths.
- Separates runtime reachability from project-wide tool/document references.
- Finds unused `ext_resource` declarations.
- Includes `.import` companions with quarantined sources.
- Applies the explicit keep list above.

The audit was rerun after each quarantine batch so newly orphaned second-order
dependencies were also found. The final reduced-project audit reports:

- 0 statically unreferenced assets
- 0 dead `ext_resource` declarations
- 0 additional quarantine candidates

The remaining resources that are not reachable from the main scene are all
intentional keeps: protected decoration/brazier art, supported dynamic glyphs,
current animation-authoring inputs, and canonical player reference art.

## Validation

Godot 4.7.1 completed a full editor import and parser scan after quarantine.
The scan completed with 487 filesystem actions and 388 imports.

The following checks passed after the final quarantine batch:

- Playtest feedback regression:
  - Ledge grab, pull-over, and jump
  - Directional grapple facing
  - Meditation hold
  - Combo finisher scale
  - Enter activation
- Player animation regression:
  - 16 corrected clips
  - Atlas cells and normalized scale
  - Frame textures
  - Three-hit forward chain
- Base grapple regression:
  - Self/trigger filtering
  - Collider-sized surface clearance
  - Deterministic stalled-pull release
- Main scene startup smoke test for 300 frames

All validation commands exited successfully. Existing ObjectDB/resource leak
warnings still appear when the short-lived verification scenes exit. The
Godot 4.7.1 editor also logged two null-access errors in Phantom Camera's
viewfinder panel while closing; the retained game/runtime plugin and all
gameplay tests continued to pass.

## Recovery and Permanent Deletion

Do not permanently delete the Desktop quarantine until a manual playtest is
complete. To recover a file, copy it from:

`Threadbound Staged for Delete/project_relative_paths/<original path>`

back to the same relative path in the project. Use `MANIFEST.json` to verify
the restored file's SHA-256 hash.
