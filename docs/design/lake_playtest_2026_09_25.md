# Lake playtest — September 25, 2026

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn` and press F6. Both enemies are already saved in this scene:

- Tide Duelist: `(640, 760)`, underwater below the first dive.
- Reedhook: `(1408, 370)`, on the deck to the right; settles onto Y=384.

This checklist reflects feedback available in this conversation, not feedback that might exist elsewhere. Automated checks passed for both enemies and the recent player combat work; the items below still need human judgment of feel and readability. Freeze new features until this pass and its fixes are reviewed.

## New work without follow-up playtest feedback

### Feedback received after the first pass

- Traversal feels good: preserve the current feel while making targeted fixes.
- Lighting is substantially better: preserve the brighter direction.
- Player appears too large relative to the world: compare character/world scale before changing collision or movement dimensions.
- Enemy art is acceptable as placeholder geometry for testing; do not spend the next pass polishing it.
- Tide Duelist dash should read as a blinkstrike; current speed is too slow. Keep a readable tell, then sharpen the committed travel. This remains pending.
- Reedhook is understated, which is acceptable for a basic enemy.
- Aerial attack arms still move erratically. User will author forward/up/down arcs in the separate manual Blender workspace. Runtime integration and removal of the directional arm override remain pending.

See [manual animation guide](../art/manual_aerial_animation_guide.md). No player scaling or enemy speed changes were made while preparing that workspace.

- [ ] **Fish encounter.** Watch its swimming and turning, then approach from each side and above/below. Is the head-to-tail curl readable? Can you dodge after recognizing it? Does the committed dash feel fair, and is recovery long enough to punish? Check size, speed, damage, and visibility against the water.
- [ ] **Fish interruption and boundaries.** Hit during windup and during dash. Check that it visibly recoils and stops attacking. Lure it toward terrain, the surface, and a dry pocket. It should stay in water and stop at obstructions. It uses direct pursuit rather than maze navigation.
- [ ] **Reedhook encounter.** Watch the walk, turn, and two-handed grip. Approach from both sides. Judge the raised windup, forward hook sweep, short step, reach, and recovery. Dodge behind him during windup; he should commit to his original facing. Touching either enemy while it is idle should not damage you.
- [ ] **Reedhook interruption and edges.** Interrupt his windup, fight beside a wall, and lure him toward a deck edge. Check hurt reaction, wall obstruction, and ledge stopping. He does not jump gaps or chase between platforms.
- [ ] **Latest air attack replacement.** Jump and attack left/right, then up/down. Judge the reused slash's body/arm motion, VFX alignment, hit timing, and return to the jump. This is the replacement made after the complaint about wrist flicking, not the older rejected air-light clip. Downward aerial hits should still pogo.
- [ ] **Latest water attack replacement.** Attack while still, swimming horizontally, swimming vertically/diagonally, and touching the lake floor. The body should retain its swimming orientation and the arm should perform one readable swing. Check transitions back to swim/idle. Downward underwater attacks should not pogo; no water combo or water special was added.
- [ ] **Directional ground special.** Hold left/right and press Special on dry ground. Judge the spin, short dash, circular reach, hit timing, resource cost, wall stopping, and recovery. Try enemies on both sides. Release direction and use Special to confirm the neutral explosion still works.

## Requested fixes to recheck, rather than new features

- [ ] **Ground combo VFX.** Hit 1 remains close to its accepted appearance; hit 2 should be larger and ahead of the weapon; hit 3 should be smaller than the oversized version, with its base meeting the floor. Test both facings.
- [ ] **Swim presentation.** Dash should use swimming rather than rolling. Up/down/diagonal movement should tilt the player appropriately. Idle sword should stay out of the head. Movement ripples should render under the player. Wall contact underwater should not engage wall cling.
- [ ] **Water handling.** Try rest-to-swim, abrupt reversal, releasing input, slow and fast surface exits, and immediate re-entry. Enter and leave dry pockets from multiple directions. Look for abrupt speed changes, unwanted boosts in pockets, stuck transitions, or loss of control.
- [ ] **Lake readability.** Check sky/clouds above water, solid-looking underwater backdrop, transparency from above versus below, air-pocket caustics, and enemy/player silhouettes. Houses and decorative terrain remain disabled for this greybox pass.
- [ ] **Editor authoring.** Both enemies should be visible before running. Move/duplicate one and undo. On a temporary copy, reshape a water polygon and dry pocket, then verify the in-game boundary matches the editor. Avoid overwriting the authored room with temporary test edits.

## Regression sweep before Git cleanup

- [ ] Kill both enemies, restart the room, and check restoration. Also test save-point reset in a room that actually contains a save point; restarting this lake alone does not test that system.
- [ ] Check jump, dash, grapple, blocking, neutral special, action-point recovery, pause/menu, and controller interaction. There are pending input/equipment/Flow changes outside the enemy work, so include these in the wider regression pass.
- [ ] In a bulb-equipped room, test melee recoil, boosted dash-through, and remote pop without momentum change. Check directional spray and refill. The lake does not automatically add bulb encounters for this checklist; the existing `blue_bulb_choice_room.tscn` is the targeted bulb scene.
- [ ] Watch for slowdown with both live 3D enemies on screen and note any new Godot debugger errors during normal play.

Use feedback entries like: **item / keep or change / what happened / expected result / screenshot or clip timestamp**. Prioritize broken controls, incorrect hits, and blocked routes before animation polish.

## Player animation editing

The equipped source used for the recent combat export is:
`ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Air_Light_v3_final.blend`.

Save As a separate manual-edit copy first. The filename is historical: current air/water attacks reuse `slash_2`, not `air_light_1`. The directional special uses `attack_2`; swim clips are `swimming_1` and `water_idle_1`. Godot also applies swim tilt, idle sword stabilization, and animation layering, so judge the exported result in-game as well as in Blender.

The live player currently loads `Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb`. Editing a Blend alone does not update that GLB. The exporter supports explicit `--source` and `--output`; its defaults point to an older library/test export, so use the current paths intentionally. The old `air_slash_v3.md` describes the superseded aerial clip and should not guide current air-attack edits.

## Git follow-up after the pass

Audit snapshot before this checklist: branch `threadbound/level-blue-biome-development`, HEAD `5ee389c6`, 32 modified tracked files, 733 untracked files totaling about 2.99 GiB. This includes source art, runtime assets, tests, previews, and duplicate Blender revisions/backups. Counts increase as documentation is saved.

1. Record the keep/change decisions and fix playtest blockers. Keep current work on the existing development branch while sorting it.
2. Inventory source assets, runtime dependencies, useful tests, and historical/generated outputs. Preserve needed art sources and the user's manual edits. Inspect references before archiving anything.
3. Decide large-file storage for retained binary sources and exports before staging. Audit Blender backups and alternate versions individually; do not bulk-add the whole workspace.
4. Split commits by coherent dependency groups: lake authoring/water; player model and animation integration; player combat/VFX; enemy models and behavior; level encounter placement; remaining input/equipment/Flow changes and documentation. Split shared-file changes by hunk where possible; preserve required source/export/script dependencies together.
5. Run the relevant checks for each group, review the staged diff and file sizes, then commit with the repository's type prefixes. Prepare a reviewed PR describing the final scope and playtest results before any merge/release.

No commits, pushes, or bulk deletions were performed as part of preparing this checklist.
