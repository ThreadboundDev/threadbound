# Blue blockout workspace

Open `blue_blockout.tscn` and press **F6** to test. This is the fresh Blue level; `blue_lakeside_test.tscn` is the old finished reference.

- Select **Geometry**, then use the existing **Room Greybox** bottom panel to add blocks, one-way platforms, polygon water, hazards or water bulbs.
- **Terrain Tiles** selects `Geometry/GreyboxTerrain`. Paint or erase with the existing solid/one-way tile palette. Only a 50-cell starter floor is prepainted.
- Move **Spawn** to set the start. **R** returns there during play; falling far below it also resets the player.
- The player, modular doll, HUD and tile palette inherit current shared resources. The HUD stays hidden in the editor and appears during play.
- Existing far-cliff, lake-village and cloud backgrounds sit in a locked **Backgrounds** group. Unlock that branch to reposition them. The parallax layers remain separate from collision.

No enemies, puzzles, route layouts or old Woven Shore scenes were restored. Build the new layout here, save the scene, then checkpoint before switching art or level tasks.

Validation: 12 headless checks passed for starter collision, one-way tiles, textures, player model, reset/fall recovery, camera and HUD. Forward+ playback rendered the Blue background, current doll and starter floor correctly. Existing shutdown resource warnings remain. This was verified in the current development checkout; pre-existing implementation edits remain separate from the level checkpoint.
