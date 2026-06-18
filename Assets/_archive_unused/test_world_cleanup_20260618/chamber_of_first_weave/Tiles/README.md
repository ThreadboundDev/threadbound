# Chamber Tile Folder

The root of this folder is reserved for the current gameplay TileSet resources:

- `cotfw_chamber_tileset_128_current.tres`
- `cotfw_chamber_tileset_256_current.tres`
- `new_tiles_atlas.png`: active 256px world tile atlas used by `cotfw_chamber_tileset_256_current.tres`.
- `cotfw_chamber_tileset_atlas_128_current.png` and `cotfw_chamber_tileset_atlas_256_current.png`: compatibility copies kept in sync with the active atlas.

Subfolders:

- `layer_atlases/`: active non-colliding 128px TileSets for far background, midground, loom shrine, and foreground hand placement.
- `singles_current/`: the current individually cut platform, corner, T, and convex tile PNGs.
- `source_sheets/`: source sheets used to cut individual tiles, including the original 256px `new_tiles_atlas_256_source.png`.
- `_archive/`: older generated passes, diagnostics, and retired source experiments.
