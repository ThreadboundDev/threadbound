# Krita stamp workspace — November 2, 2026

**Current: measured-color v3 installed.** Chase authorizes direct RGB correction.
[Carved Cavern v3](../../ArtSource/Deliveries/CarvedCavernStampsV3/README.md) maps
v2 pixels to C07's RGB channel distributions without redrawing/resampling or
changing alpha. All six saved alpha channels are byte-identical. The sampled
RGB quantile error is 0.06–0.39 on the 0–255 scale. 24 flip/XML checks, native
Shift+X / Shift+Y / Reset, source/output checks and bundle integrity pass. V3 is
active; v1/v2 remain disabled, retained copies. The 81-stamp atlas is saved as
`All_Current_Stamps_v3.kra` in the local `all_current_stamps_2026_11_02_v3`
folder. ZIP, 83 layers and exact merged-image agreement pass. Room drawing saved
before setup, then unchanged at SHA256
`e1a8f0ad50c95114cdf706215ef3ae13d5b60dd84ab6568898b70580fe016506`.
The corrected brushes affect future marks; existing painted marks remain intact.
Final visual acceptance at actual joins remains for Chase. Checkpoint:
`365647c4` — `fix: color-match cavern stamps to existing cave walls`.

Later color/flip follow-up: [Carved Cavern v2](../../ArtSource/Deliveries/CarvedCavernStampsV2/README.md)
is now the active cavern bundle; v1 is disabled and retained. All six images use
C07 directly as a color reference and measure closer in the saved chroma check.
Chase still finds the color imperfect in the actual painting, so color acceptance
remains open. Preset names now satisfy the existing flip plugin's Village prefix;
24 XML checks plus live horizontal, combined/vertical shortcut and Reset checks
pass. The updated 81-stamp reference is saved as `All_Current_Stamps_v2.kra` in
the local workspace's `all_current_stamps_2026_11_02_v2` folder. Native KRA ZIP,
83-layer count and exact merged-image agreement with the ORA pass again. The
room drawing was saved before kit changes, preserving Chase's newly painted work.
The original atlas remains available. The earlier setup record below is historical.

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
