# Gameplay-scale appearance lab

Open `tools/art/appearance_lab.tscn` in Godot and press F6. Normal movement,
jump and attack controls work. The camera starts at 0.83, matching production.
Use the on-screen choices for Plain / Pattern / Mask / Both, three motifs,
three mask markings, nine Identity presets, two mixing approaches, softer
porcelain, shoulder armor and long-weapon proxies.

The lab duplicates the current rig's body mesh in memory, puts authored rest
height/depth in UV2, and applies a study material. This keeps motifs attached
when the bones move. It never replaces the GLB, equipment resources or game
scenes. Proxies change appearance only; attack reach/animation/VFX still use
the current sword. They are not finished armor or weapon assets.

- [Four looks](looks-comparison.jpg)
- [Three mask markings](mask-comparison.jpg)
- [Identity presets](identity-comparison.jpg)
- [Mixing / proxy / porcelain comparison](math-gear-comparison.jpg)

Body crops retain native capture pixels; only the lower face insets are enlarged
4x, as labelled. The neutral gray-blue lab is a controlled background, not proof
of readability in every biome. Embroidery is deliberately limited to two cloth
bands. It is a procedural placeholder, not an authored garment mask. Mask
markings use the existing pale face surface, not new sculpted porcelain shells.

The current Flow aura computes a weighted RGB average for its glow. The color
design asks for R/Y/B pair hues and a black full-absorption extreme. The lab
compares those treatments without changing either production logic or lore.
Current neutral preserves the current outfit; Spared / pale tests whitening.
The softer porcelain toggle reduces only the face material's albedo/specular
response; the bright demo's additive 2D lights still need a location-specific
review before selecting a production highlight treatment.

Validation: `Godot --path . --fixed-fps 60 --script
res://work/appearance-lab-2026-10-30/capture_lab.gd`. Ten engine checks pass,
including real running/attacking, default gear, unchanged collision, camera,
proxy selection and palette endpoints. Twenty static GPU captures support the
comparison figures. Raw PNGs are ignored intermediates, retained locally.
`build_review.py` packages them. Existing shutdown resource diagnostics remain.
