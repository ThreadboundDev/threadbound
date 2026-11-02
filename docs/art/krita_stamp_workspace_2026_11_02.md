# Krita stamp workspace — November 2, 2026

Chase requests importing the recent cavern and modular village stamps, putting
the current stamps in one editable file, and leaving the room painting open.

## Ready in Krita

- Existing **Blue Village Slate Library**: 61 painted art brushes.
- Imported **Threadbound Modular Buildings v1**: 36 presets, including 22
  existing library pieces and 14 new building components.
- Imported **Threadbound Carved Cavern v1**: six new flat-top outcroppings.

All three bundles are active in the normal Krita profile, verified through the
resource-library UI and a read-only resource database query. The filter menu
shows **Village - All**, **Village - Modular Buildings**, the modular category
filters, and **Cavern - Carved Walkways**. The six cavern presets are visible;
S01 was selected without painting onto the room.

The current room **Blue_Village_Connections_Review.kra** is left active, with the
new stamp reference open in the adjacent tab. The drawing was not saved or
painted over. Its original and final SHA256 match:
`d4c42b4445a52ca2a2a75ad195c69d8254fc5a28d48979d9168de384f568d78a`.

## Combined editable file

Under `ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack/all_current_stamps_2026_11_02/`:

- **All_Current_Stamps.kra** — native Krita document, 81 unique stamps on separate
  layers, plus background and labels (83 layers total), 3000 × 6900 pixels.
- **All_Current_Stamps.ora** — layered portable source.
- **All_Current_Stamps.jpg** — quick visual reference.
- **manifest.json** — source bundles, dimensions and pixel hashes.

Each piece is fitted proportionally into a reference cell. The installed brushes
retain source resolution. Duplicate art was removed by comparing original RGBA
pixels and dimensions, not just names. Background and labels can be hidden;
each art layer can be copied or moved independently.

The builder is [tools/art/build_all_stamp_reference.py](../../tools/art/build_all_stamp_reference.py).
Run with Python and Pillow. It reads the current three bundles and writes the
ORA, JPEG and manifest into the existing local painting workspace. Open the ORA
in Krita and Save As KRA to reproduce the native version.

Validation: all GBR headers and pixel lengths, original-pixel duplicate hashes,
ORA ZIP integrity and independent layer recomposition pass. The ORA was visually
reviewed in Krita and saved as KRA. The KRA ZIP passes integrity checks, contains
83 layers, and its merged RGBA image exactly equals the ORA merged image.
Resource import is confirmed; actual brush painting is left for Chase.

The consolidated KRA/ORA/JPEG and room painting are local-only under the existing
ignored RecoveredLocal workspace. The Git checkpoint backs up this builder and
setup note, not those local artworks or the personal Krita resource database.
No game asset replacement, scene changes or completed gameplay acceptance is
claimed. Save and checkpoint the painting before switching art tasks.
