# Central tower: retain 3D and polish the roof — October 24, 2026

Chase authorized choosing between improving the existing 3D tower and rebuilding
it as layered 2D art. Choose **3D for the central tower**. Actual platform
thickness, wall returns and the recessed base opening already exist in the model;
they share the existing cutaway/lighting pipeline. Layered 2D would require new
front/rear/platform art and registration work to reproduce that depth. This choice
does not settle the presentation of houses, enemies, villagers or bulbs.

Branch: `threadbound/art-central-tower-roof-polish`, from `5cae90e0`.

## What changed

- `central_tower_3d.tscn` now loads the versioned `central_tower_v4.glb`.
  The original `central_tower.glb` and v1–v3 source deliveries remain available.
- Timber fascia no longer follows the ceramic tile ripple. The broad eave curve
  stays intact, while the wood edge becomes continuous instead of jagged.
- Roof tiles use one UV projection per face across the hips, with tile spacing
  matched to the modeled corrugation. The former per-vertex axis choice could
  twist UVs across a single face. Roof normal strength is reduced from .45 to .22.
- The roof has its own copied material. Original shared texture files and the
  material behavior of non-roof structure remain intact.
- The comparison defaults to **3D Tower** alongside the painted assets. F7 and
  Buildings/Actors/Bulbs do not change that choice. A separate **Tower** checkbox
  allows the retained painted version to be compared explicitly.

Editable source: `outputs/central-tower-model-v4/CentralTower_Editable.blend`.
That source folder has `.gdignore`; Godot consumes the exported GLB and does not
need to invoke Blender on the editable source. Builder:
`tools/art/polish_central_tower.py`. No new raster art or texture repaint is used.

## Verification

- Blender source checks preserve the geometry, UVs, smoothing and transforms of
  all **12 non-roof meshes**. Vertex/face counts are unchanged throughout.
- `tools/art/verify_central_tower_v4.py` independently compares installed GLBs:
  expanded non-roof triangle positions/UVs match; mesh identities and model bounds
  match; all six upper-roof cutaway clearances remain valid; original shared
  texture references are identical; UVs/tangents exist and positions are finite.
- The actual comparison room passes **31 focused GPU checks**, including real
  player sweeps landing on all nine existing tower platforms, foot contact within
  .2 px, the open base crossing, facade/inner-return visibility, the independent
  tower toggle and keeping the tower 3D through F7 switches.
- The broader comparison passes **149 headless checks**, including both houses,
  original collision invariance, enemy/bulb binding and F2 respawns. Its painted
  tower envelope is still tested after explicitly selecting that alternative.
- Forward+ / Vulkan, Godot 4.7.2, RX 6800 XT. Captures include exterior, crown,
  cutaway, platform depth, base opening, dusk, hybrid default and before/after
  angled roof views. See `work/central-tower-polish-2026-10-24/` for the images,
  source/export reports and `after.json` / `comparison_regression.json`.

The first import attempt hit Godot's headless Blender-path prompt for the new
editable source. Ignoring the source-only output folder resolved it; the final
GLB import succeeds. The capture fixture now fails if expected roof meshes are
missing. Intermediate failed/import captures were replaced by the final run.
Existing T04 texture RID, six ObjectDB/three resource GPU teardown diagnostics,
ten ObjectDB/five resource headless teardown diagnostics and Camera2D
interpolation warnings remain open.

## Review next

Restart the comparison scene with F6. Leave **Tower: current 3D** selected and use
the Tower landmark. Check roof edges outside and in the cutaway, jump across the
platforms, then inspect the base entry under daylight and dusk. Roof silhouettes
and material readability still need Chase's visible acceptance. Fine texture
noise, ceramic course detail and lighting remain possible later polish; this is
a focused roof correction, not a complete architecture redesign.
