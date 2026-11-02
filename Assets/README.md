# Assets loaded by the game

Game-ready models, textures, sprites, audio, fonts and UI resources live here.
Scenes/scripts are under `Src/`; editable originals are under `ArtSource/`.

The current local doll export is `Threadborne/Player/LocalDoll/`.
`Threadborne/Player/Equipped3DTest/` remains the bundled player fallback and a
source of shared equipped animations. Its historical name does not mean it is unused.
Old `Normalized_V2` sprites are still referenced by the current player scene's
hidden timing pipeline. They cannot be deleted before the proposed migration.

Keep downloaded packs outside this folder, in `Threadbound - Potential Use`.
Only install selected dependencies as part of a reviewed game change.
