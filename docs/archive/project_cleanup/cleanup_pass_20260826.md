# Project Folder Cleanup — 2026-08-26

## Outcome

This pass separates runtime assets, editable art sources, media production,
documentation archives, build output, and development tools into clear roots.
It also removes superseded Blue Biome prototype art and obsolete player
animation copies while preserving every removed file in a Desktop quarantine.

- Quarantine: `C:\Users\chase\Desktop\Threadbound Cleanup Quarantine 2026-08-26`
- Quarantined files: 2,585 before adding the quarantine README
- Quarantined size: 5,406.58 MiB
- Runtime roots retained: `Assets/`, `Src/`, and `addons/`
- Authoring roots: `ArtSource/`, `Media/`, `docs/`, and `tools/`
- Regenerable export root: ignored `Builds/`

## Removed From the Runtime Tree

- Six blank or rejected individual Blue Biome cloud exports
- Superseded lake, silhouette, cloud-sheet, water-material, and vegetation-sheet assets
- The two replaced six-frame swim sheets
- Redundant individual ledge-climb source frames
- Redundant archived copies of the active run frames
- Stale import sidecars for source art moved outside the runtime asset tree
- Ignored exports, temporary review frames, and empty generated editor folders

Current buildings, keyed placeables, vegetation, reflective water, hazards,
platforms, player runtime animations, chamber assets, demo systems, merchant
icons, and supported controller glyphs were retained.

## Organization Changes

- `.codex_media/` became `Media/Development/`.
- `social_media/` became `Media/Social/`.
- `cleanup_reports/` became `docs/archive/project_cleanup/`.
- Ignored local tooling moved from `local_tools/` to `tools/local/`.
- Editable Blue Biome, player-reference, and VFX sources moved from `Assets/`
  to `ArtSource/` and are excluded from Godot imports with `.gdignore`.

## Validation

Godot 4.7.1 completed a headless import and main-project startup smoke test.
The room greybox, Blue Biome room, cloud, reflective-water, vegetation, and
building-cutaway verification scenes passed. The player-animation verifier
continues to report the existing ledge-climb forbidden-silhouette issue; the
cleanup introduced no missing-resource, parser, or startup errors.
