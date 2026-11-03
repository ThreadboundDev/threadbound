# Approved Blue scene and player cleanup

November 2, 2026. Chase approves the character-cleanup proposal and asks to
retain only the Blue level currently used for testing. Implementation is in progress.

The current test card identifies `lakeside_painted_comparison.tscn`, which inherits
the older Krita playtest. Their saved content is consolidated into
`Src/Environment/BlueBiome/blue_lakeside_test.tscn`, the single Blue level in
the game scene tree. The original comparison UID is retained for editor references.
Player, houses, water, terrain, bridge and NPC components remain reusable scenes.

The [location manifest](blue_scene_locations_2026_11_02.json) lists every affected
level. Existing automated checks still need 24 old layouts; those have moved to
`tools/fixtures/blue_layouts/`, behind `.gdignore`. They are regression inputs,
not selectable game levels, and are excluded from normal Godot import/export
discovery. Their assertions remain unchanged. Tools retain their original layout
when testing a historical fixture; normal launchers use the one current scene.

Consumer changes are resource-path updates in the affected Blue helper scripts,
environment/enemy verification tools, art-authoring tools, current test guides
and character preview launcher. The runtime scene root, existing collider geometry,
water masks, room layouts, actor placement and current artwork are preserved.
Packing an inherited scene omitted four overrides; the three bridge `stamp=0`
values and Bellstriker's `start_facing=-1` are restored explicitly.

The separate player migration follows
[the approved file scope](character_controller_cleanup_proposal.md): texture-free
timing, controller-owned facing, live character effects, removal of hidden body/
glow/pattern sprites and old weapon-art tracks, preserving active attack anchors,
grapple mechanics and useful live-3D animation blends. The ongoing modular
equipment work in the shared checkout must be retained and is not part of this
task's commits.

Checkpoints are separate: Blue scene consolidation first, then the verified player
presentation migration. No new gameplay systems, tuning or asset replacements.
