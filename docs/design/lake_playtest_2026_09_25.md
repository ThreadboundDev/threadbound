# Lake playtest — September 25, 2026

Updated October 5, 2026 against runtime commit `5f42ee0b`. The original feedback date is retained; current implementation notes and test items below supersede the original pending-work descriptions. No checks were rerun or acceptance decisions made during this documentation update.

For priorities use [the Away and At-computer queues](../project_status_and_worklist.md). For a short ready-to-play list use [Next hands-on test session](../next_test_session.md). Independent discussion, investigation and approved implementation can proceed while hands-on review waits.

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn` and press F6. Three enemies are saved in this scene:

- Tide Duelist: `(640, 760)`, underwater below the first dive.
- Reedhook: `(1408, 370)`, on the deck to the right; settles onto Y=384.
- Bellstriker: `(2500, 820)`, farther along the lake. The lake also now includes Water Bulbs.

Historical notes recorded passing checks for the earlier fish/Reedhook and player work. Those results do not certify the October 5 revision. The unchecked items below still need human judgment of feel/readability; they are not a list of confirmed current bugs.

## Feedback and current review needs

### Feedback received after the first pass

- Traversal feels good: preserve the current feel while making targeted fixes.
- Lighting is substantially better: preserve the brighter direction.
- Player appears too large relative to the world: compare character/world scale before changing collision or movement dimensions.
- Enemy art is acceptable as placeholder geometry for testing; do not spend the next pass polishing it.
- Original fish feedback: the dash should read as a blinkstrike rather than slow pursuit. Current code now uses a 1050 px/s committed dash with living hover/glide motion. Review whether its tell and release satisfy that feedback; the speed change itself is no longer pending.
- Reedhook is understated, which is acceptable for a basic enemy.
- Original aerial feedback: erratic arms needed authored forward/up/down arcs. The authored v2 air set is now integrated, without the old procedural shoulder aiming over those clips. Up/down have later runtime retiming. Review the current result; authoring/integration is no longer pending.

See [manual animation guide](../art/manual_aerial_animation_guide.md) for the current donor and historical workspaces, and [water combo notes](../art/water_combo_v1.md) for the live combo/special adaptation. Player/world scale still needs a hands-on decision.

- [ ] **Fish encounter.** Watch its station-holding hover and turning, then approach from each side and above/below. Is the head-to-tail curl and eye flash readable? Can you dodge after recognizing the lock? Does the 1050 px/s committed release feel fair, and is recovery long enough to punish? Check size, damage and visibility against the water.
- [ ] **Fish interruption and boundaries.** Hit during windup and during dash. Check that it visibly recoils and stops attacking. Lure it toward terrain, the surface, and a dry pocket. It should stay in water and stop at obstructions. Its committed straight dash does not navigate around walls or between disconnected pools.
- [ ] **Reedhook encounter.** Watch the walk, turn, and two-handed grip. Approach from both sides. Judge the raised windup, forward hook sweep, short step, reach, and recovery. Dodge behind him during windup; he should commit to his original facing. Touching either enemy while it is idle should not damage you.
- [ ] **Reedhook interruption and edges.** Interrupt his windup, fight beside a wall, and lure him toward a deck edge. Check hurt reaction, wall obstruction, and ledge stopping. He does not jump gaps or chase between platforms.
- [ ] **Bellstriker encounter.** Judge jab/cross/smash tells, locked release, harmless gaps, escape and punishable recovery. Check upright water guard, attached wrists, moving feet, wall occlusion, hurt interruption, and water/land leaps. Use `Src/Enemies/Bellstriker/bellstriker_test.tscn` for an isolated repeatable setup.
- [ ] **Current authored air attacks.** Jump and attack left/right, then up/down. Judge body/arm motion, VFX alignment, hit timing, return to the jump and the retimed up/down response. Downward aerial hits should still pogo. Do not use the superseded `air_light_1` or early reused-opener clip as the acceptance target.
- [ ] **Current water combo.** Attack while still, swimming horizontally/vertically/diagonally and touching the lake floor. Tap-buffer all three hits, compare holding Attack, turn between strikes, dash-cancel and exit the surface. Review the grounded upper-body/flip with dynamically swimming legs, locked facing per strike, handoffs and return to swim. Downward underwater attacks should not pogo.
- [ ] **Underwater specials.** Use neutral Special and left/right spin underwater. Check AP cost, steering, radial contact, wall stopping, cancellation where allowed, and water/land transitions without restarted windows or extra AP spending.
- [ ] **Directional ground special.** Hold left/right and press Special on dry ground. Judge the spin, short dash, circular reach, hit timing, resource cost, wall stopping, and recovery. Try enemies on both sides. Release direction and use Special to confirm the neutral explosion still works.

## Requested fixes to recheck, rather than new features

- [ ] **Ground combo VFX.** Compare the current second-hit timing and third-hit overhead/ground-contact weight in both facings. Judge the effect against the actual blade path and contact; historical requested sizes are feedback context, not a statement that the old version remains live.
- [ ] **Swim presentation.** Dash should use swimming rather than rolling. Up/down/diagonal movement should tilt the player appropriately. Idle sword should stay out of the head. Movement ripples should render under the player. Wall contact underwater should not engage wall cling.
- [ ] **Water handling.** Try rest-to-swim, abrupt reversal, releasing input, slow and fast surface exits, and immediate re-entry. Enter and leave dry pockets from multiple directions. Look for abrupt speed changes, unwanted boosts in pockets, stuck transitions, or loss of control.
- [ ] **Lake readability.** Check sky/clouds above water, solid-looking underwater backdrop, transparency from above versus below, air-pocket caustics, and enemy/player silhouettes. Houses and decorative terrain remain disabled for this greybox pass.
- [ ] **Editor authoring.** All three enemies should be visible before running. Move/duplicate one and undo. On a temporary copy, reshape a water polygon and dry pocket, then verify the in-game boundary matches the editor. Avoid overwriting the authored room with temporary test edits.

## Wider regression before accepting a playable candidate

- [ ] Kill the enemies, restart the room, and check restoration. Also test save-point reset in a room that actually contains a save point; restarting this lake alone does not test that system.
- [ ] Check jump, dash, grapple, blocking, neutral special, action-point recovery, pause/menu, controller interaction and Flow presentation. Include shared-system regression even when the immediate change was an enemy fix.
- [ ] Test melee recoil, boosted dash-through and remote bulb pop without momentum change. Check directional spray and refill. Lake bulbs now exist; use `blue_bulb_choice_room.tscn` for the designed upper/lower/return route proof.
- [ ] Watch for slowdown with live 3D enemies on screen and note any new Godot debugger errors during normal play. Record hardware/settings with a frame-time observation rather than inferring performance from source.

Use feedback entries like: **item / keep or change / what happened / expected result / screenshot or clip timestamp**. Prioritize broken controls, incorrect hits, and blocked routes before animation polish.

## Current animation references

The live player model/locomotion source is `Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb`. Air attacks come from the separate `threadborne_authored_attacks.glb` donor in that folder; see the manual guide for its source/export workflow and runtime retiming.

Water combo clips are generated from grounded `slash_2` with swimming-leg adaptation inside `PlayerLive3DVisual._install_water_combo`. Underwater specials adapt `power_up_1` / `attack_2`. The older `threadborne_water_combo.glb` and manual water workspaces are preserved studies, not the current live-combo donor. Editing/exporting those studies alone does not change the live combo.

Judge the game result as well as the source: root compensation, swim presentation and runtime retiming affect the display. `air_slash_v3.md` and `air_water_and_spin_combat.md` describe superseded air/water implementations.

## Historical September Git audit and follow-up

The following audit and staging plan describe the September 25 workspace, not today's working-tree state or an outstanding instruction to stage/delete these files. September 26 checkpoints and October 5 commit `5f42ee0b` subsequently preserved development work. For current priorities and Git/release follow-up use the main work list.

Audit snapshot before this checklist: branch `threadbound/level-blue-biome-development`, HEAD `5ee389c6`, 32 modified tracked files, 733 untracked files totaling about 2.99 GiB. This includes source art, runtime assets, tests, previews, and duplicate Blender revisions/backups. Counts increase as documentation is saved.

1. Record the keep/change decisions and fix playtest blockers. Keep current work on the existing development branch while sorting it.
2. Inventory source assets, runtime dependencies, useful tests, and historical/generated outputs. Preserve needed art sources and the user's manual edits. Inspect references before archiving anything.
3. Decide large-file storage for retained binary sources and exports before staging. Audit Blender backups and alternate versions individually; do not bulk-add the whole workspace.
4. Split commits by coherent dependency groups: lake authoring/water; player model and animation integration; player combat/VFX; enemy models and behavior; level encounter placement; remaining input/equipment/Flow changes and documentation. Split shared-file changes by hunk where possible; preserve required source/export/script dependencies together.
5. Run the relevant checks for each group, review the staged diff and file sizes, then commit with the repository's type prefixes. Prepare a reviewed PR describing the final scope and playtest results before any merge/release.

No commits, pushes, or bulk deletions were performed as part of preparing this checklist.
