# Blue Biome authoring library

This folder is the single entry point for building the Blue Biome in Godot.

- `ArtPlaceables/Buildings`: free-place exterior building art.
- `ArtPlaceables/Background/Clouds`: individually placeable drifting cloud variants.
- `ArtPlaceables/Ground`: the paintable ground-art TileMapLayer and TileSet.
- `ArtPlaceables/Platforms`: playable wood platforms plus modular house layers.
- `ArtPlaceables/Surfaces`: free-place roof and stone overlays.
- `ArtPlaceables/Vegetation`: grass and cherry-blossom accents.
- `Buildings`: interactive layered/cutaway buildings.
- `Hazards`: reusable Threadglass gameplay hazards.
- `Prototypes/Rooms`: clean room shells for the macro route.
- `Prototypes/Experiments`: exploratory assembled rooms; preserve these while iterating.
- `References`: the scalable macro-map reference scene.

The **Room Greybox** editor dock is the fastest placement route. Gameplay geometry and artwork remain separate: grey collision defines movement, while the placeable art can be aligned freely over it.

`ThreadglassWaterlineReeds` contains no painted water below its reed line. Place its base at the live water surface so the existing animated water supplies the motion and masking.

Cloud variants share one transparent atlas but are separate scene instances.
Scale, rotate, position, and adjust `drift_speed` per instance; do not place the
entire source sheet as a single moving strip.
