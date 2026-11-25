# Carved cavern walkway stamps v2

November 2, 2026. Chase likes the shapes but requests cave-wall color matching
and working flips. This revision uses C07_Inset_Cave_Face directly as the color
reference. Six generated color edits preserve the original overall silhouettes;
they are not pixel-identical recolors. M01 and S02 received a second correction
after the first edit made highlights too yellow. Built-in image_gen prompts and
selected cache source locations are recorded in generation_prompts.json and
selected_outputs.json. Original v1 artwork remains available in the sibling kit.

- [Krita bundle](Threadbound_Carved_Cavern_v2.bundle)
- [Catalog](catalog.jpg)
- [PNG stamps](generated/)
- [Palette diagnostics](palette_validation.json)
- [Existing flip-plugin checks](flip_validation.json)

The v2 bundle is imported and active in Chase's normal Krita profile. V1 is
deactivated, not deleted. Choose **Cavern - Carved Walkways v2** in Brush Presets.
All preset names now start with **Village Cavern**, because the existing Stamp
Controls plugin only accepts full-color GBR presets whose name starts with
`Village `. This fixes compatibility without changing or reinstalling the plugin.
Flip X and Flip Y buttons, Shift+X / Shift+Y and Reset are available. A live
S02 check confirms X ON, combined X/Y ON, and Reset to both off; size is retained.
Normal S01 stamping was also visually checked in a separate scratch document.
All six presets pass 24 mirror-state/parameter-preservation checks using the
existing plugin's XML functions. The brush pack verifies exact serialized RGBA
pixels, resource hashes, links, alpha range and primary silhouette margins.

`check_palette.py` requires NumPy and Pillow. It compares opaque-pixel median
chroma in six brightness bands against C07; all six revised stamps score closer
than v1. This diagnostic is not proof of exact palette equality. Chase reports
that the placed stamps look decent but the colors still need refinement; visual
acceptance remains open. A measured existing-pixel color correction has been
proposed for a subsequent pass. Brush updates do not recolor already-painted
marks. No current drawing pixels are replaced as part of importing this kit.

`build_kit.py` shares the v1 packer with explicit v2 names. It reads the existing
local Stamp Controls source to run compatibility checks. The v2 combined atlas
is produced by tools/art/build_all_stamp_reference.py in the existing ignored
painting workspace's all_current_stamps_2026_11_02_v2 folder. It still has 81
unique art layers plus background and labels; the old atlas is retained.

The room drawing had unsaved user edits when this pass began. It was saved
before kit changes; later user edits and painting remain intact. The corrected
kit is separate from game assets and changes no scenes or collision.
