# Cleanup Pass - 2026-07-02

## What Was Archived

Moved 40 backup/scratch files into:

`Assets/_archive_unused/cleanup_pass_20260702/`

The archive contains a `_manifest.json` with each original path and archived path.

Archived categories:

- Root scratch/test files:
  - `animation.tscn`
  - `test_new_world.tscn`
  - `tmp_create_cotfw_tileset.gd.uid`
  - `tmp_create_cotfw_tileset_expanded_seamfixed.gd.uid`
  - `tmp_tileset_api_probe.gd.uid`
- Art/editor backup files:
  - `*.png~`
  - `*autosave*.kra`
  - `*.tmp`

## What Was Not Archived

These were intentionally left in place:

- `Threadbound.sln` and `Threadbound.csproj`
  - Godot Mono export has previously required the solution file.
- `icon.svg` and `threadbound_app_icon.ico`
  - Both are referenced by project/export configuration.
- `exports/`, `export_templates/`, `feature_profiles/`, `script_templates/`, and `text_editor_themes/`
  - These are local/generated folders and are already ignored by `.gitignore`.
- Real `.kra` source art files
  - These may be valuable source/editing files even when not used at runtime.

## Static Asset Audit

Generated:

- `cleanup_reports/asset_reference_audit_20260702.json`
- `cleanup_reports/delete_candidates_20260702/static_unreferenced_assets.csv`
- `cleanup_reports/delete_candidates_20260702/top_review_candidates.json`

Scan result:

- 187 active assets were found referenced by project text.
- 62 active assets were not found in project text and need review before deletion.

The largest review candidate is:

- `Assets/Audio/Music/COTFW_background.wav` at about 145 MB.

This appears likely superseded by `Assets/Audio/Music/COTFW_background_loop.wav`, but it should be confirmed in Godot/audio testing before deletion because music has been sensitive recently.

## Packaging Notes

The repo already ignores local export/build outputs:

- `exports/`
- `export_templates/`
- exported `.exe`, `.pck`, and Mono data folders

For sharing builds, keep using exported folders/zips outside source control. Before a public download flow, the likely next step is a dedicated release folder or itch.io-style upload package generated from Godot export presets rather than manually zipping the working tree.

## Recommended Next Cleanup Steps

1. Confirm whether `COTFW_background.wav` can be archived/deleted.
2. Review old standalone door PNGs now that doors use open sheets plus high/low pieces.
3. Decide whether UI example images should remain in-project during demo polish or move into an external/reference archive.
4. Move old tile diagnostic/generated-pass images out of active assets if they are no longer needed.
5. Keep `.kra` source art, but consider moving source files into a dedicated source-art archive outside runtime asset folders later.

## Follow-up Deletion

Deleted after approval:

- `Assets/Audio/Music/COTFW_background.wav`
- `Assets/Audio/Music/COTFW_background.wav.import`

Reason:

The active project text no longer referenced `COTFW_background.wav`; the game currently references the looped background track instead.
