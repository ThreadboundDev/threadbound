# Blue Biome Painted Room Workflow Experiment

## Goal

Test whether large painted rooms can retain player-scale detail without relying on a conventional repeated tileset.

## Proof scenes

- Full-size enlargement: `blue_chamber_exit_paintover_proof_of_concept.tscn`
- Retired: the 50% world-scale and three-strip scenes were deleted after both proved too soft for production.

The working rooftops scene now shows its collision greybox again. Production art experiments use overlapping native-resolution terrain assets and independent seam-cover overlays rather than room-sized paintings.

## 50% scale test

The artwork and polygon collision are scaled together from 7500×4300 to 3750×2150 world units. The player stays at normal scale. This tests whether the concept's large features become believable gameplay-scale forms and whether the enlarged source texture reads more sharply when sampled down.

## Chunk test

The approved room was divided into three vertical source strips with 25% overlap. Each strip was independently repainted with the full room supplied as a continuity reference. Mathematical crop boundaries were then used to create three adjacent 2500×4300 runtime pieces.

### Result

Local texture and edge detail improved substantially, but independent generation changed geometry inside the overlaps. Exact placement exposes discontinuities at both joins. A global grade or lightweight shader can unify hue, contrast, and atmospheric haze, but it cannot repair mismatched cliff silhouettes, bridge endpoints, or platform heights.

This makes independent full-height room strips unsuitable as final collision-driving art unless their shared edges are fixed by hand or edge geometry is supplied as immutable transparent assets.

## Recommended production workflow

1. Block gameplay at real world scale with editable collision polygons.
2. Keep collision silhouettes authoritative and split them into manageable contiguous pieces.
3. Generate large reusable transparent terrain assets rather than complete independent room strips:
   - convex and concave grass-topped rock banks
   - smooth slope faces in several lengths and angles
   - arch and overhang pieces
   - cliff columns and room-mouth surrounds
   - bridge endpoints and bridge spans
4. Hand-place and overlap those pieces in Godot so seams fall inside foliage, rock occlusion, or foreground dressing.
5. Use a cohesive distant backdrop separately from gameplay terrain.
6. Apply one restrained room-level color grade to unify the assembled pieces.
7. Add separate animated water, grass, trees, particles, and foreground silhouettes.

## Palette and contour lock

Every generated gameplay-terrain asset should use the same small palette family:

- dark blue-gray foundation stone
- one cool midtone stone family
- restrained yellow-green vegetation
- pale pink blossom accent
- warm amber light accent
- sky colors reserved for background layers

Gameplay silhouettes keep a consistent dark contour/value edge. Interior texture must not become darker than the outer collision silhouette. Generated pieces require generous transparent padding and overlap-safe ends.

## Polygon and slope rules

- Prefer several medium `CollisionPolygon2D` pieces over one room-wide polygon.
- Avoid self-intersections, tiny sawtooth edges, and near-vertical micro-segments.
- Keep visual decoration more irregular than physical collision.
- Approximate decorative bumps with smoother collision arcs.
- Test slopes at multiple run speeds, during dash, grapple release, wall cling, and pogo landing.
- Use dedicated one-way polygons for bridge and rooftop spans; never fold one-way surfaces into solid terrain polygons.
