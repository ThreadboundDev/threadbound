# Underwater rock background and return to the demo — October 29

October 30 follow-up: the source pixels below are retained, but runtime
presentation now uses independent far-rock parallax and fixed waterline clipping.
Timber remains world-locked. See the
[depth/bridge delivery](../art/blue_depth_and_bridges_2026_10_30.md) for current
behavior and validation; the original no-parallax integration below is historical.

Chase requested integrating his single `Underwater background` Krita layer and
returning attention to the established 2D game. He wants to replay the original
demo with the new character to identify the feel that the lake has not captured.
The 3D trial remains parked. No new gameplay direction is inferred from this.

## Background delivery

- Source: `Blue_Village_Connections_Review.kra` in the external
  `Documents/Codex/2026-10-07/ri/outputs/blue_village_stamp_pack/cave_connections_v1`
  directory. The editable KRA remains there, unchanged; it is not included in
  this repository checkpoint. The exported painted pixels are backed up in Git LFS.
- Exact source hash, layer UUID, bounds and section positions:
  `Assets/BlueBiome/Art/LakesideMap/underwater_background_manifest.json`.
- Export: 25 transparent PNG sections, each at most 1024 × 1024, using the
  existing 6912 × 5888 canvas, world origin (-1408, -2560) and 1:1 scale.
  Authored bounds are (0, 2890)–(6912, 5888) in source-canvas pixels.
- Integration: appended decorative group in `lakeside_krita_artwork.tscn`,
  z = -8, behind rear supports (-7), cave walls (-5), bulbs and player.
  Existing water rendering supplies the underwater tint. No additional color
  treatment, collision, gameplay or existing artwork replacement is included.
- Reimport only this layer with
  `uv run --with pillow --with numpy python work/krita-map-import/extract_map.py --underwater-only`.
  Do not run the legacy full room rebuild. Texture imports use the existing
  map convention of VRAM compression and mipmaps.

## Validation and acceptance

- Decoded source sections reconstruct the layer pixel for pixel before texture
  compression. Named layer, paint type, blend format and canvas are checked.
  Repeating the scoped import produces the same scene bytes.
- Godot 4.7.2 asset import completed. Forward+ comparison-scene review loaded
  the new 25-section group behind the existing art and captured Cave, Shore and
  an underwater swimmer near the tower. Underwater layering and the retained
  open-air cave view were visually inspected.
- Capture: [underwater swimmer](../../work/krita-map-import/underwater_swimmer.png).
- The original Chamber demo also completed a 120-frame headless boot with the
  shared current character. This checks loading, not playable feel.
- Existing scene ownership messages from `lakeside_krita_playtest.gd:61`,
  camera interpolation warning and six ObjectDB/three-resource shutdown
  diagnostics remain visible. The review is not a claim of a clean project-wide
  diagnostics run. No gameplay regression suite or hands-on playthrough was run.
- **Delivered; Chase's appearance/feel acceptance pending.** Checkpoint:
  `art: add painted underwater rock background` on
  `threadbound/art-underwater-rock-background` (resolve exact hash in Git history).

## Next review and candidate work

Use the [current test card](../next_test_session.md). The demo scene already
instances `Src/Characters/Player/player.tscn`, whose live character visual is
enabled by default. No character migration is required for this replay.

Recommended order, pending Chase's observations:

1. Record the demo's strongest movement, encounter and pacing moments. Separate
   the feeling observed from theories about why it works.
2. Choose one short lake route to carry that feeling: clear destination, a
   satisfying movement sequence, an encounter and a moment to breathe. First
   compare the existing route; layout changes require a scoped proposal.
3. Address the largest observed control/contact or enemy-readability problem,
   then replay the same route. Combat and equipment changes require approval.
4. Review water/background separation and selected contact/environment sounds
   in that route. Use the existing sound audition library before installing or
   replacing audio. Finish T20 acceptance with explicit keep/change decisions.

These are candidate next steps, not additional active implementation tasks.
T03 reset reconciliation and T04 diagnostics remain open on the single work list.
