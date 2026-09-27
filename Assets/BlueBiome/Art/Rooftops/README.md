# Blue Biome Rooftop Modules

These rooftops are free-placeable scenes rather than TileMap tiles. Drag the
matching scene from `Src/Environment/BlueBiome/ArtPlaceables/Rooftops/` into a
room and position it without grid snapping.

| Scene | Standard span |
| --- | ---: |
| `blue_rooftop_short_01.tscn` | 320 px |
| `blue_rooftop_medium_01.tscn` | 640 px |
| `blue_rooftop_long_01.tscn` | 960 px |

The root origin is centered on the landing surface. Each module includes a
one-way landing strip, solid climbable end caps, and a grapple target covering
the complete visible platform mass. Scale uniformly when variation is needed;
avoid non-uniform scaling because it also distorts the collision shapes.

