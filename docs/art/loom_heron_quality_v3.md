# Loom Heron craft rebuild — October 21, 2026

Chase requested a focused bird-only quality pass. The production heron prefab
now uses `Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v3.glb`.
Villagers, Eave Runner, combat code, scene structure, collision and placement
were not changed by this pass. Earlier bird sources are retained.

The rebuild replaces the spherical head with a continuous tapered ceramic
skull and bill, a narrow eye recess, lower mandible and indigo glazed ridge.
The body has a smaller woven basket frame, overlapping shoulder and breast
cloth, fitted braided load paths and an interlaced paired-knot emblem.
Wings have individually cambered indigo panels, separate cloth primaries,
stitched flax repairs, rolled hems, frayed edges, split walnut spars and fitted
crossed lashings. Bound hip sockets, tension cords, curved talons and layered
tail cloth complete the construction. Tube seams are welded for smooth
lighting while retaining independent UV corners.

## Editable source and runtime

- `ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v3.blend`: packed,
  editable source with 153 named components, studio camera and lights.
- 573,520 source triangles; 291,599 source vertices. Runtime has the same
  triangle count and 323,027 vertices after UV/tangent seam splitting.
- 18 original bones and all 11 original clips, including the ranged sequence.
- 15 materials. Ten imported surfaces use 4K albedo and normal maps; the
  remaining surfaces include lacquer, metal, eye glaze and charged thread.
  Existing approved 4K shared maps are reused with corrected UVs and palette
  factors. No generated concept image is substituted for a model render.
- The 3.51m wing span, approximately 1.81m rest height and 96 game pixels per
  metre remain consistent with the established bird. The prefab retains its
  1536-square viewport, 4x MSAA and original orthographic camera settings.

Build with background Blender using `tools/art/build_heron_quality_v3.py`.
Then run `tools/art/import_heron_quality_v3.py package`, `prepare`, a headless
Godot editor import of `work/loom-heron-v3/import_project`, and `install`.
Install verifies source checksums before copying the scoped import caches.
Preview generation is `tools/art/render_heron_quality_v3.py`.

## Verification and visual review

- Source verifier: **835 checks passed**: UVs, normals, packed images, skin
  weights, bone names, all clips, loop continuity and sampled pose bounds.
- Imported real-prefab art verifier: **167 checks passed**: mesh fidelity,
  textures, material filtering, charge response, camera, collision and beak
  marker projection for both facings.
- Existing guardian behavior fixture: **134 checks passed**, including the
  locked ranged shot, one-hit projectile, terrain obstruction, interruption,
  vulnerable low recovery and reset/death cleanup.
- Existing actual lakeside room fixture: **19 checks passed**, including the
  real player, repeated encounters, projectile blocking and F2 enemy respawn.

Review images and the motion loop are renders of the saved Blender source.
The camera-scale view matches the prefab's camera geometry but uses Blender
lighting; it is not an in-game screenshot. No app window or desktop control
was used. Godot checks ran headlessly, so GPU appearance and frame time still
need the usual hands-on playtest. Art acceptance belongs to Chase.

The bird remains a ranged Hermit guardian: quiet hover, blue charge, one locked
needle, then a low vulnerable recovery. Its behavior was preserved.
