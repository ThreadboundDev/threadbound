# Blue Biome assets

- `Prototype/Placeables`: production-facing, reusable authoring assets grouped by Buildings, Ground, Hazards, Platforms, Surfaces, and Vegetation.
- `Prototype/CodexPass`: exploratory room paint-over and shader sources used by the current chamber/rooftops experiment.

When placing a reusable object, prefer its ready-made scene under `res://Src/Environment/BlueBiome/` instead of dragging the raw image into a room. The scene already carries the intended scale, material, draw order, and—where appropriate—gameplay behavior.

Files ending in `_source` are retained source sheets. Use the non-source version through its corresponding scene.
