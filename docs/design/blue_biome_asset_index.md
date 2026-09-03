# Blue Biome Asset Index

## Fast authoring route

Open a room under `Src/Environment/BlueBiome/Prototypes/Rooms`, then use the **Room Greybox** dock:

1. Paint solid movement space with **Create / Select Terrain Tiles**.
2. Add water, generic hazards, and slopes as free-place gameplay geometry.
3. Use **Ground artwork** for the repeating stone/earth finish.
4. Add playable wood platforms where movement requires them.
5. Dress the collision with Buildings, Free-place art, Vegetation, and House layers.
6. Add Threadglass only where the danger reads clearly during movement.

## Placement categories

| Need | Scene folder | Notes |
|---|---|---|
| Houses and pavilion | `Src/Environment/BlueBiome/ArtPlaceables/Buildings` | Art only; align over separate collision. |
| Repeating ground | `Src/Environment/BlueBiome/ArtPlaceables/Ground` | TileMapLayer-based and intentionally repeatable. |
| Playable wooden routes | `Src/Environment/BlueBiome/ArtPlaceables/Platforms` | Short/long platforms include collision; the other pieces are dressing layers. |
| Roof and stone overlays | `Src/Environment/BlueBiome/ArtPlaceables/Surfaces` | Free placement for matching irregular silhouettes. |
| Grass and cherry blossoms | `Src/Environment/BlueBiome/ArtPlaceables/Vegetation` | Use green and pink to keep the biome from becoming monochromatically blue. |
| Layered interiors | `Src/Environment/BlueBiome/Buildings` | Cutaway behavior for entering and leaving buildings. |
| Damage and pogo hazards | `Src/Environment/BlueBiome/Hazards` | Threadglass floor, wall, ceiling, waterline, and pogo variants. |

## Waterline hazard rule

The waterline Threadglass scene supplies only the dangerous reeds/glass and collision. It deliberately does not contain painted water. Align the bottom edge of the art with the active water surface; the water system remains responsible for animation, depth, masking, and player presentation.

## Room route

The clean room shells are collected under `Prototypes/Rooms`: Chamber Exit / Rooftops, Lakeside Village, Lower Shore, Peasant Fields, Irrigation Channel, Hidden Cistern, Shrine Approach, Old Shrine, Hermit's Lake, and Waterfall Ascent. The macro overview and scalable reference remain one level up in `Prototypes` and `References`.
