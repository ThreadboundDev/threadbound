# Character and sword outline review

Reviewed report `2026-11-05T14-24-34_29744_106532_2`, captured November 5,
2026 at 09:24 America/Indianapolis. The report includes a screenshot and
sampled player, camera, equipment, and diagnostic state. No recording is
attached. Base gloves, boots, and Head / Chest are equipped at camera zoom
0.83. Diagnostics contain zero errors and one warning.

Chase prefers the firm black edge baked into the older player and enemy
sprites by expanding their silhouettes by approximately three image pixels.
The screenshot shows the enemy's stronger edge beside a softer player.
Chase also requests a separate sword edge where the blade crosses the body,
with the shield included in the character silhouette. Sword sheathing is a
future topic.

The player already uses `player_live_3d_outline.gdshader` on the sprite that
displays its transparent 3D viewport. The shader expands the composite alpha
edge, with its runtime width set to approximately 1.5 world pixels before
camera zoom. At 0.83 zoom that is approximately 1.25 screen pixels. Its
coverage weighting further softens the edge. The screenshot alone cannot
establish how much animation quality contributes to the perceived difference.

The sword and body share the same opaque render. Their overlapping boundary
is inside the composite silhouette, so increasing that silhouette outline
cannot establish a black line along the sword there. The existing idle
presentation offsets the sword hand to separate the blade tip from the face,
but this cannot provide an edge through all animation poses.

## Proposed implementation for approval

Start with a roughly three-world-pixel near-black character outline and
compare it to the current setting at normal zoom. Use the existing composite
shader to include the shield and fitted clothing. Judge the edge on idle,
run, grapple, and an attack frame with the player next to the screenshot's
enemy. Check that fine cloth and wicker edges retain readable shapes.

Give only the sword meshes a second material pass that draws an expanded,
front-face-culled dark shell in the same 3D viewport. Fit its projected width
to the camera and retain depth testing so the outline follows the visible
blade and hilt while the torso can occlude the sword. Test the blade crossing
the chest, passing behind the body, and separating from the character.
This is the proposed first rendering experiment. Its visual acceptance is
open until those comparisons are rendered.

The planned runtime files are

- `Src/Characters/Player/player_live_3d_outline.gdshader` for the character edge.
- `Src/Characters/Player/player_live_3d_visual.gd` for outline widths and applying
  the sword pass when the weapon mesh loads or changes.
- New `Src/Characters/Player/player_sword_outline.gdshader` for the sword shell.

Use `tools/player_animation/verify_base_blue_equipment.gd` for a scoped
verification update if necessary. Existing shared-checkout edits in the
visual script require a selective checkpoint.

The report is feedback, and AGENTS.md requires approval before architectural
changes. The separate sword material pass is proposed here for approval.
The report remains open, with runtime rendering edits pending.
