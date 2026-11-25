# Attack strokes V2

September 14 follow-up: the red/yellow/blue internal lines have been removed from the shader after gameplay review. The current attack strokes render white; identity color data is retained elsewhere but is no longer drawn into these strokes. The notes below record the original generation setup.

Remade from the user's September 14 attack reference using built-in ImageGen.
`attack_strokes_matte_v2.png` is a 2048 × 768 RGB luminance matte: eight 256px frames per row, three rows. It is deliberately black-backed, not an RGBA export. `Src/VFX/attack_stroke_matte.gdshader` removes the black in-game and supplies subtle identity-colored internal lines without tinting the white body.

Rows: diagonal slash, horizontal slash, overhead stroke. Existing ground strikes select these rows; neutral air uses the diagonal row. These are visual mappings, not new combat moves. Playback follows normalized source-animation time and therefore follows attack-speed changes. Left-facing strokes mirror horizontally, preserving the downward direction. Placement and reach are set in `sword_sweep_vfx.gd`.

## Generation prompts

Initial generation used the supplied reference and requested an 8-column, 3-row, 2048 × 768 transparent atlas: eight sequential buildup, peak, follow-through and fragment-dissolve frames for each diagonal, horizontal and overhead white slash. It required crisp painted strands, carved gaps, fine tapered tails, white/neutral silver only, consistent pivots, padding, and no labels or borders. Its background contained a baked checkerboard, so that output was rejected.

Final edit prompt (applied to that generated atlas):

> Edit this exact 2048x768 8-column 3-row sprite atlas. Preserve all 24 white slash frames, their positions, size, shapes and thin white strands exactly. Change ONLY the background: eliminate every gray checkerboard square, mottled mark, and ghost image outside the white effects. Replace the entire background with perfectly uniform pure RGB black (#000000) as a VFX luminance matte. Do not draw any checkerboard. Black must be 0,0,0 everywhere outside white slash strokes and shards. Keep the slash cores crisp white and their fine edge antialiasing grayscale against black. No text, no grid lines, no panels, no added objects. Do not change layout or dimensions. This is a raw black-matte game texture, not a presentation image; black will become transparent in the game shader.

Validation: Godot render captures of air and all three ground strikes; automated checks cover all 24 frame selections, upright left-facing transforms, cleanup, and the existing single-hit air behavior at multiple playback speeds and frame rates.
