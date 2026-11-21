# Woven shoreline transition — proposed November 21, 2026

Status: prepared for approval before scene restructuring. Chase requests water,
editor-visible scenery and a left-side exit from the chamber into this level.
The chunks should read as substantial landmasses emerging from the lake, with
the route leading toward the Blue rooftops. This applies the existing regional
route (Chamber Exit -> Upper Village / Rooftops) to the woven-world audition.

## First playable pass

- Continue editing `woven_chunk_level.tscn`, preserving Chase's current chunk
  positions, decoration edits and three ground collider adjustments.
- Save backdrop, daylight, water, player/camera and entry markers in the scene.
  Use native Parallax2D/Sprite2D layers for editor-visible backdrop placement;
  reuse current sky/cliffs and distant village textures. Reuse authored nodes
  at runtime so running the scene creates no duplicate player, camera or lights.
- Promote the existing runtime ground-art registration and default platform/
  foliage choices into scene overrides. The editor should show the placement
  that will run, including usable surface depth and irregular foliage bases.
- Reuse `greybox_polygon_water.tscn` with its existing lake presentation. Begin
  with an adjustable waterline around world Y=900, below all three ground caps,
  and a basin deep enough to swim in the gaps. Author the volume as selectable
  polygon points. Keep the water quiet and compatible with Blue's still-lake
  direction. Judge the tint and landmass intersections in the actual render.
- Provide a scene-local preview-swimming setting using the player's existing
  flag. It is for testing entry, swimming and recovery, not a new unlock rule.
- Extend the left boundary for a dry chamber-mouth passage, using existing
  chamber stone and current rock/root art. Include a floor, roof/side framing,
  `ChamberEntrySpawn` and a walkable landing onto Ground A. The opening should
  read as emerging from an enclosed space into the bright lake vista.
- Mark the right side as `RooftopApproach` and retain the upper/lower traversal
  options for arranging the transition. Actual building/rooftop expansion can
  follow the first shoreline review.
- Make the local camera cover the chamber mouth, islands and useful swimming
  depth. Retain O/V comparisons and the existing grounded contact shadow.
- Adjust the test's fall recovery to distinguish swimming from leaving the
  playable basin; entering valid water must not trigger the old gap reset.

The current chamber demo uses its ending-choice flow. This first pass establishes
the physical chamber-side entrance and an explicit spawn, while leaving the main
menu, demo ending and production room routing intact. A later connection can
target this spawn once the transition layout is accepted. No combat, equipment,
player movement, regional unlock policy or lore change is proposed.

## Proposed implementation files

Modify:

- `Src/Tests/Art/WovenWorld/woven_chunk_level.tscn` — saved composition, water,
  entry/approach instances, exactly one player/camera and authored art overrides.
- `Src/Tests/Art/WovenWorld/woven_chunk_level.gd` — bind saved nodes, entry spawn,
  camera/basin bounds, preview-swimming option and water-aware verification.
- `Src/Tests/Art/WovenWorld/woven_world_review.gd` — small compatibility change
  to reuse saved lighting while retaining the older review's fallback path.
- `ArtSource/Deliveries/WovenWorldChunks/README.md` — editor controls and results.
- `docs/project_status_and_worklist.md` — current scope, review and checkpoint.
- This proposal — implementation/acceptance record after approval.

Create:

- `Src/Tests/Art/WovenWorld/woven_shore_backdrop.tscn` — editor-visible backdrop.
- `Src/Tests/Art/WovenWorld/woven_shore_water.tscn` — local configured instance
  of the existing polygon lake, retaining its established swimming behavior.
- `Src/Tests/Art/WovenWorld/woven_chamber_mouth.tscn` — local entrance assembly
  and entry/landing markers using existing art.
- `ArtSource/Deliveries/WovenWorldChunks/shore_transition/` — scoped verification
  reports and actual editor/gameplay captures, PNGs under existing LFS rules.

The existing ground placeable files already contain Chase's manual collision
edits; implementation should preserve those exact edits rather than regenerate
or overwrite them. Shared water scripts/materials and production chamber scenes
are reuse sources, not proposed edits. If implementation exposes a need to change
those systems, explain that concrete extension before expanding the scope.

## Verification and checkpoint

Check editor-visible placement against the running scene; one player/camera/light;
dry entry and dry island caps; water entry/exit and traversal in both gaps; return
to land and upper route; camera coverage; underwater visibility; recovery below
the basin; preserved grounded shadow/outline modes; and unchanged save/settings.
Rerun the older art review's fallback check after shared lighting changes.

Before staging, save the Godot scene and inspect the manual ground/level diffs.
Checkpoint only the approved task scope; preserve unrelated working-tree edits
and existing staged Blender deletions. Start implementation from the current
accepted HEAD, using `threadbound/level-woven-shore-transition` if separated
from the current art branch. Commit/push after relevant checks and record which
visual/route acceptance remains pending. No production-route publication or
merge is part of this first pass.
