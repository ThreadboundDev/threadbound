# Blue Chamber Exit Paint-over Proof of Concept

## Purpose

This isolated scene tests a painted-room workflow: the room artwork is displayed at its native 7500×4300 size while gameplay collision remains editable independently.

## Scene

Open:

`res://Src/Environment/BlueBiome/Prototypes/Experiments/blue_chamber_exit_paintover_proof_of_concept.tscn`

The retired 50% and independent three-strip comparison scenes were deleted after testing. Both remained too soft at gameplay scale, and the strip approach introduced visible geometry drift at its joins. See `docs/art/blue_biome_painted_room_workflow_experiment.md` for the retained findings.

The existing Blue Chamber Exit and Chamber scenes are not modified.

## Drawing irregular collision

1. Expand `Geometry/PolygonTerrain`.
2. Duplicate an existing polygon terrain node and rename it for the painted feature it traces.
3. Expand that node and select its `CollisionPolygon2D` child.
4. In Godot's 2D toolbar, choose the polygon point tool.
5. Click around one contiguous painted solid and close the polygon by clicking its first point.
6. Run the scene and test movement, wall cling, and grapple.

The visible collision polygon automatically mirrors into the grapple-target collision layer. Never edit `GrappleTarget/CollisionPolygon2D` manually.

Use multiple medium-sized polygons instead of one room-sized outline. Avoid self-intersections and extremely tiny edges, which can create movement snags. The rope bridge remains its own `one_way` polygon so the player can jump through its underside and land on top.

## Current starter collision

- Approximate lower boundary
- Approximate left bridge bank
- Approximate right bridge bank
- One-way rope bridge span

These are intentionally starter shapes for workflow testing and should be refined directly against the final full-scale artwork.
