# Current character files

- `player.tscn`: the 2D physics/gameplay actor and its components.
- `player.gd`: movement, combat state, traversal, interaction and existing animation dispatch.
- `player_live_3d_visual.gd`: the equipped 3D model, animation blending, transparent
  viewport and 2D composite. Automatically uses the local doll when present.
- `flow_state_aura.gd` / `flow_state_vfx.tscn`: Flow presentation; prefers the live composite.
- `player_stats.gd` / `.tres`: character stat data.
- `rope_hang_anchor.gd`: traversal support.
- Shaders: outlines, legacy glow/pattern rendering and meditation presentation.

The hidden `Player Animation` sprite and the scene's old weapon animation tracks
still have gameplay callers. Their presence is obsolete architecture, but they
are not yet safe deletion candidates. The real model's upper/lower-body blends
are active behavior. Read the [file-specific cleanup proposal](../../../docs/organization/character_controller_cleanup_proposal.md)
before restructuring the player scene or equipment presentation.
