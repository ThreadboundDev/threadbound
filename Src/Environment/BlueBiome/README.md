# Blue Biome authoring library

This folder is the single entry point for building the Blue Biome in Godot.

- `ArtPlaceables/Buildings`: free-place exterior building art.
- `ArtPlaceables/Background/Clouds`: individually placeable drifting cloud variants.
- `ArtPlaceables/Ground`: the paintable ground-art TileMapLayer backed by the current 512-pixel authored atlas.
- `ArtPlaceables/Platforms`: playable wood platforms plus modular house layers.
- `ArtPlaceables/Rooftops`: current free-place rooftop pieces.
- `ArtPlaceables/Vegetation`: grass and cherry-blossom accents.
- `Buildings`: interactive layered/cutaway buildings.
- `Hazards`: reusable Threadglass gameplay hazards.
- `Prototypes/Rooms`: clean room shells for the macro route.
- `References`: the scalable macro-map reference scene.

Superseded full-room paintovers, modular terrain generations, preview scenes, and
the first grid-based generation pass have been removed from the runtime project.

The **Room Greybox** editor dock is the fastest placement route. Gameplay geometry and artwork remain separate: grey collision defines movement, while the placeable art can be aligned freely over it.

`ThreadglassWaterlineReeds` contains no painted water below its reed line. Place its base at the live water surface so the existing animated water supplies the motion and masking.

Cloud variants share one transparent atlas but are separate scene instances.
Scale, rotate, position, and adjust `drift_speed` per instance; do not place the
entire source sheet as a single moving strip.
