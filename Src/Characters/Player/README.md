# Current character files

- `player.tscn`: 2D physics/gameplay actor, health, hitboxes, light and equipment mount.
- `player.gd`: movement, combat state, traversal, interactions, facing and action dispatch.
- `player_animation_clock.gd`: texture-free frame events, playback and completion signals.
- `player_animation_timing.gd`: the 24 preserved action timelines; no sprite-sheet dependency.
- `player_live_3d_visual.gd`: equipped 3D model, useful animation blends, transparent
  viewport and visible `Live3DComposite`. Uses the local fitted doll when present.
- `flow_state_aura.gd` / `flow_state_vfx.tscn`: Flow effects using the live avatar.
- `player_stats.gd` / `.tres`: character stat data.
- `rope_hang_anchor.gd`: traversal support.
- Outline shader: current character presentation. Pattern shader: still used by GameMenu.

`AnimationClock` owns logical timing; the live avatar owns rendered poses.
`AttackPoseAnimationPlayer` retains only RESET/quick-attack hitbox-anchor tracks.
Grapple world-space rope/needle behavior and authored equipment poses remain active.
Retired sprite sheets and unused shaders are in deletion staging batch 08 outside
the project. See [cleanup and validation](../../../docs/organization/runtime_cleanup_2026_11_02.md).
