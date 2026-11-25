# Blue Biome assets

- `Art/TerrainPaintTests`: the current authored 3x3 terrain atlas and TileSet used by the production Blue Biome room.
- `Art/Clouds`, `Art/Rooftops`, `Art/Vegetation`, and `Art/Water`: current reusable environmental art.
- `Prototype/Placeables/Buildings`: retained house artwork. These remain available while their runtime scenes are used in the level library.
- `Prototype/Placeables/Ground`, `Hazards`, and `Platforms`: retained reusable sheets still referenced by authored scenes.
- `Prototype/CodexPass`: only shared materials/shaders still referenced by retained placeables. Superseded panorama, vegetation-sheet, painted-water, and paintover experiments were removed from the runtime project.
- `Materials/Terrain`: shared terrain rendering materials used by the production greybox.

When placing a reusable object, prefer its ready-made scene under `res://Src/Environment/BlueBiome/` instead of dragging the raw image into a room. The scene already carries the intended scale, material, draw order, and—where appropriate—gameplay behavior.

Files ending in `_source` are retained source sheets. Use the non-source version through its corresponding scene.
