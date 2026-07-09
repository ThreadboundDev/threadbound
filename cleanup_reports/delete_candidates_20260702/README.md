# Delete Candidate Review - 2026-07-02

This folder is a review staging area only. No files listed here were deleted.

Generated files:

- `static_unreferenced_assets.csv` - active assets that were not found in current `.gd`, `.tscn`, `.tres`, `.cfg`, `.godot`, `.md`, `.json`, shader, font, or atlas text references.
- `top_review_candidates.json` - the largest 30 unreferenced candidates from the same scan.

Important caveat:

Godot projects can still use assets dynamically by filename, folder convention, editor-only workflows, or future art/reference needs. Treat these as "review before delete", not automatic proof that the asset is useless.

Highest-value review candidates:

- `Assets/Audio/Music/COTFW_background.wav` - ~145 MB. Likely superseded by `COTFW_background_loop.wav`, but confirm before removal because background music was recently repaired.
- Original separate door PNGs such as `red_wing_door.png`, `blue_wing_door.png`, `yellow_wing_door.png`, and `boss_wing_door.png`. Current door scenes appear to use the opening sheets plus high/low open pieces.
- Old reference/example images in `Assets/UI/Examples/`. Keep if they are still useful for UI iteration; otherwise archive after the current menu polish settles.
- Old base gold font assets in `Assets/UI/Fonts/base_gold_font/`. Current readable font direction appears to be Almendra.
- Large generated tile diagnostics and readable/graphic pass images under `Assets/chamber_of_first_weave/Tiles/_archive/`.

Recommended workflow tomorrow:

1. Confirm each candidate is not referenced in the editor.
2. Move confirmed keep-but-not-runtime files into `Assets/_archive_unused/`.
3. Delete only files that are both unused and not useful as source/reference material.
4. Run Godot headless validation after every batch.
