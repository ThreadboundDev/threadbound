# Modular painted bridges

Chase rejected the simple geometric rails and requested components matching the
Krita stamp style. These assets sample the **existing approved PNGs directly**.
No source PNG is replaced, repainted or regenerated. Painted post caps, grain,
seams and outlines come from `J03_Japanese_Veranda.png`; decks retain their
selected stamp and float/brace grain retains `B04_Simple_Plank_Crossing.png`.

All assets are under `Src/Environment/BlueBiome/ArtPlaceables/Platforms/`:

| Scene | Purpose |
| --- | --- |
| `bridge_deck_2d.tscn` | Standalone deck, with left `WalkPlane` anchor |
| `bridge_railing_2d.tscn` | Standalone painted rail/post strip |
| `bridge_pontoons_2d.tscn` | Separate twin float bodies/bindings |
| `bridge_braces_2d.tscn` | Separate load-bearing triangles and anchor socket |
| `pontoon_bridge_2d.tscn` | Convenience assembly for the waterline spans |
| `braced_landing_2d.tscn` | Convenience assembly for elevated landings |

Drop individual parts into a level for custom placement. They contain no physics.
Their origin is the left end of the walking plane; the existing level supplies
collision. The assemblies retain the original nine node paths, walking anchors,
span widths, stone overlaps and support-anchor positions.

For an assembly, edit `Span Width`, stone insets, `Rail Detail Scale`,
`Front Center Opening` and `Front Rail Offset`. Rear rail, front rail, floats
and braces each have a separate visibility control. Floats are selected only
for the floating assembly and braces only for the elevated one. Individual part
scenes can also be moved/layered independently outside the assembly.

Rear rails draw at Z -6. Front rails draw at Z 4, with a default center opening
and a 12-unit offset to show depth while leaving combat visible. Their end caps
are assembled from the same stamp, including on the short front sections.
The rail shader excludes the PNG's deck plane while preserving painted posts.

[High span](../../work/overnight-playtest-2026-10-30/modular-Deck01-comparison.jpg) ·
[Tower landing](../../work/overnight-playtest-2026-10-30/modular-Deck06-comparison.jpg) ·
[Floating span](../../work/overnight-playtest-2026-10-30/modular-Deck08-comparison.jpg).

Validation: 32 standalone/assembly checks pass, plus the existing 78 room checks.
All 148 captured world collision polygons match the previous review baseline.
GPU captures verify the painted rail cutout, front/rear layering and actual
room placements. The captures use 1x building supersampling; the player/camera
remain at production settings. Existing inherited-enemy ownership and shutdown
resource diagnostics persist. Appearance/feel awaits Chase's review.

Checkpoint: `art: build modular bridges from approved painted stamps`.
