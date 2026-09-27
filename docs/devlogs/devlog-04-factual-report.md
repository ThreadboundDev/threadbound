# Demo 0.1.0 to the current working project — factual change report

Reviewed September 26, 2026. This is a repository/history review, not a new gameplay test or release certification.

## Comparison boundary and confidence

There are **no local Git tags** identifying the published Demo 0.1.0. The first explicit version marker is commit `9dd792b6` (August 14), which sets `config/version="0.1.0-rc1"`. Commit `9bc22046` that evening changes it to `0.1.0-rc2`. The current project still reports `0.1.0-rc2`; that string does not identify a new release.

This report uses **`9bc22046bf537f504758c35b8a94fd17f26994a2` as a provisional demo baseline**, not as a verified public-build commit. An upload date or build manifest is still needed to establish precisely what Itch players received. August 15–16 fixes may have been included in the public demo and must not automatically be advertised as later additions.

Current committed endpoint: **`5ee389c6d8181bf46b9f55b31e821fb99f98638c`**, September 4, on `threadbound/level-blue-biome-development`. Current working files also contain extensive **uncommitted September work**, including the live 3D player, lake, enemy prototypes, and authored aerial attacks. Those files are included in this review, explicitly as development work rather than a published update.

The tracked baseline-to-HEAD comparison reports 549 changed files, 11,944 insertions and 348 deletions. This includes art and file organization; it is not a feature count. History contains parallel/reconciled commits and merges, so counting commit subjects would exaggerate the work.

Three labels below distinguish the evidence:

- **Earlier development:** present before the provisional August 14 baseline. Useful retrospective context, not established post-demo work.
- **Committed after baseline:** verified in the Git comparison; public release inclusion remains uncertain around August 15–16.
- **Current experiment:** present in local working files but uncommitted and not established as shipped.

Evidence priority is current code/scene wiring, then the latest dated notes, then historical documents. Several documents retain superseded descriptions. A design proposal or a verification script's existence alone is not proof that a feature works in a public build.

## 1. Combat and the attack animation overhaul

### Earlier development: making sprite combat readable

The July work substantially revised the sprite player's attack presentation. Moving attacks use an opener followed by a double-sweep finisher, giving a three-hit sequence across two attack inputs. Stationary attacks use a complete double hit; backpedaling has its own takes. The visual variant is selected at swing start, preventing a release of movement input or a collision from swapping sprite sheets halfway through a swing.

The normalization work corrected inconsistent character scale, clipped weapon tips, atlas-cell errors, opacity, and frame registration. It restored anticipation and added deliberate impact holds. Upward ground input was routed into the frontal combo with a wider sector; directly overhead targets required an aerial attack. These were concrete readability and continuity changes, not merely new artwork.

Combat also gained move-specific hit pause/shake and receiver-specific enemy responses. Threadlings, Loomkins and Tensioners can react with different apparent weight, while rapid combo strikes are less likely to be swallowed by an overly long damage gate. This supports the project's stated aim of connecting movement and combat.

**Evidence:** `18cc4c8a`, `caee7fd1`, `329b14f7`, `185c22cb`, `3c0895b6`; [animation normalization](../art/player_animation_normalization.md); [combat foundation](../gameplay/combat_foundation.md). These changes precede RC2.

### Committed after baseline: dedicated pogo presentation

The August 26 downward-strike pass gave pogo its own 11-frame animation with a vertical weapon commitment and ivory smear instead of borrowing the air-double-attack artwork. The changelog explicitly says this visual replacement preserved damage, active frames, AP behavior, rebound, and recovery. Do not describe this art pass as the invention of pogo or as a pogo damage buff.

**Evidence:** `3eb0c6fd`; [pogo changelog](../changelogs/player_pogo_attack.md); baseline/current player sprite resources.

### Current experiment: rigged attacks, directional air moves and blocking

The live model uses a continuous `slash_2` performance divided into **three input-driven grounded strikes**. This differs from the older sprite opener/double-finisher structure. Current timing and effects follow the model animation; the September 26 second-hit correction moves its contact window to source frames 37–42 because the later window followed the sword behind the player.

Aerial work has gone through several revisions: the old double-hit mapping, custom `air_light_1` studies, reuse of the ground slash with runtime arm aiming, and finally **authored forward/up/down attacks**. The current code imports `threadborne_authored_attacks.glb`, selects separate directional actions, and does not apply the old procedural shoulder aim over those aerial clips. Up is now a thrust rather than the earlier rising-slash study; down leads with the blade and supports pogo. Vertical attacks have a quick extension/hold/recovery treatment; forward recovery has also been shortened.

Water has separate idle/moving attack poses blended by swimming speed. The current pass attacks along swimming direction, or facing direction at rest. It is not a complete independently aimed underwater attack set. Downward water attacks do not pogo; water combos and water specials are not added by this pass.

Holding a horizontal direction and using Special on dry ground selects a traveling spin. It uses the existing two-AP special cost, normal wall collision, one hit per target, and radial knockback. Neutral Special remains the explosion. Standing/crouched guard is implemented with facing-side damage mitigation; rear hits bypass it. Perfect blocks/parries remain deferred. These are working gameplay experiments, not a claim that a final shield equipment system has shipped.

The current sword effects use measured blade positions and move-specific strokes. Recent fixes address second-hit timing, third-hit overhead/floor coverage, up/down blade alignment, and sword visibility. The September 25 note saying directional attacks were awaiting integration is superseded by the September 26 integration notes and current code.

**Evidence:** `Src/Characters/Player/player.gd` (`_start_ground_combo_attack` vicinity, `get_attack_sweep_data`, `_get_air_attack_active_frames`, damage filtering); `player_live_3d_visual.gd` (`play_ground_combo_strike`, `play_air_attack`, `_install_authored_attacks`); `Src/VFX/sword_sweep_vfx.gd`; [manual aerial animation guide, especially its later updates](../art/manual_aerial_animation_guide.md); [air/water/spin notes](../art/air_water_and_spin_combat.md). Earlier numerical timings in the latter document are superseded where the current code differs.

**Player effect:** clearer differences between grounded, airborne and submerged attacks, more explicit control over individual grounded strikes, and stronger correspondence between the visible weapon and contact. Final feel and visual acceptance remain playtest work.

## 2. Flow State and feedback

### Earlier development: the July presentation overhaul

The July 27 overhaul replaced generic aura presentation with a live-silhouette treatment, ivory/gold structure, distinct red/blue/yellow Thread accents, entry/exit presentation and action effects. The specification explicitly preserves Flow mechanics, activation, statistics and drain. Its stated goal is to communicate earned momentum and attunement while keeping poses, enemies and platforms readable.

Collected demo Threads drive the colored accents as a temporary identity proxy. This is not evidence that the final Absorb/Spare identity system exists, or that collecting all three constitutes canonical full absorption.

**Evidence:** `26ec8077`, merged through `26bdc4ba`; `58fc582b` fixes left-facing silhouette; [Flow specification](../art/flow_state_vfx.md).

### Current experiment: simplifying Flow around the live model

The current aura resolves the live 3D composite instead of sampling only the hidden legacy sprite. Pose snapshots form short afterimages. Default trail capacity falls from 22 to 5, lifetime from 0.58 to 0.30 seconds, and opacity from 0.38 to 0.20, with greater spacing and a capture interval.

Several old effects are deliberately retired: detached attack crescents, separate jump/dash/landing emissions, active ambient/buildup updates, transition sprites and Flow light energy. The code comments identify the mismatch between the old crescent and the live weapon and describe movement feedback as pose-matched afterimages. The silhouette aura remains; it would be inaccurate to say all Flow visuals were removed.

**Evidence:** working diff of `Src/Characters/Player/flow_state_aura.gd` and `Src/VFX/Flow/flow_multimesh_trail.gd` against HEAD. The older Flow document is historical direction, not an exact inventory of the present enabled effects.

**Player effect:** the current approach concentrates feedback on the actual player pose and weapon instead of layering every earlier effect together. No measured frame-rate improvement or new Flow-stat system is established by this review.

## 3. Movement and traversal

**Earlier development:** July grapple fixes addressed false attachments, range/tow behavior and input transitions; ledge presentation gained a bridge from cling through pull-up into landing. August 14 ledge-capture and camera-composition tuning also precede RC2. These are context, not new September mechanics.

**Committed after baseline:** August 15 added controller grapple aim assistance: candidate surfaces near the stick direction gently influence aim, with assistance fading at the edge of a narrow cone. It is not a hard lock. Colored grapple artwork was aligned to the wrist. August 16 separated controller jump and interaction.

Late August/early September introduced Blue-region swim and water experiments, a full-frame sprite swim animation, polygon water and launch objects. Water preserves and redirects momentum; fixes specifically prevent ordinary air input immediately erasing a breach launch. The September 4 endpoint is itself a breach-momentum fix.

**Current experiment:** bank-side Dive prompts stage the entry above water, while ordinary falls still work. Polygon lakes and dry pockets use consistent player-position sampling; wakes are restricted to actual wet regions. Swimming should retain its own animation underwater instead of falling into running or wall-cling presentation. The current code/notes address slow exits, overlapping volumes, boundary transitions and air-pocket rendering.

Water bulbs now distinguish actions: melee pops recoil the player opposite the strike; dash carries incoming momentum forward with lift; remote grapple/ranged pops clear the bulb without propelling the player. Ordinary contact gently ejects without consuming it. Bulbs regenerate. The choice-room test offers alternate approaches and a safe recovery floor, consistent with the documented emphasis on expressive routes and backtracking.

**Evidence:** `aaf164f6`, `fa3e96f5`, `3eb0c6fd`, `370fd7cf`, `1015e7ec`, `54cd30e1`, `5ee389c6`; [water prototype](../design/blue_water_momentum_prototype.md); [bulb choice room](../design/blue_bulb_choice_room.md); latest manual-animation guide; `Src/Environment/BlueBiome/Water/`, `Src/Environment/Greybox/greybox_polygon_water.gd` and player water methods.

**Player effect:** water is being tested as an active part of a traversal chain, with controllable transitions back to air and grapple. These rooms are prototypes; the full Blue region is not demonstrated as finished or publicly available.

## 4. Environment art, decoration and level polish

**Earlier development:** July wing-content and world-polish passes developed the chamber's themed foliage, props, encounters, lighting and interactive presentation. The merchant room and boss presentation were already present before RC2.

**Committed after baseline:** Blue-region prototype rooms and art arrived in late August, including cloud placement, lake-slate terrain and modular rooftop platforms. Follow-up fixes corrected collision, terrain reconstruction, water depth and cloud/camera anchoring. These matter because a decorative platform must still represent the actual landing surface.

**Current experiment:** Still Village studies combine painted houses/platforms and layered backgrounds with rendered water bulbs. Bulb petals pulse, open and refill; directional droplets distinguish activation. Building-water contact uses tint/occlusion and restrained rings to make supports sit in the lake. Material studies seek broad wood grain, muted slate and worn structural edges, but the notes explicitly say final parity with the approved painted house style remains unresolved.

The polished hybrid preview is a composition test. The lake greybox is a different playtest scene; recent notes intentionally disable decorative houses/terrain there to judge movement and encounters. Do not caption a village art study as the final playable level, or interpret its cosmetic water-contact shader as new swimming physics.

**Evidence:** `7a7ba4ec`, `846e49f3`, `ff668484`, `55f89840`, `2afb9302`, `3af10a15`; [Blue roadmap](../design/blue_biome_development_roadmap.md); [hybrid village review](../art/hybrid_village_review.md); [water/attack feedback](../art/water_and_attack_feedback.md); [lake playtest](../design/lake_playtest_2026_09_25.md).

**Player effect:** a more specific lakeside visual identity and clearer relationships between platforms, buildings and water. Final region layout and art cohesion are still being tested.

## 5. Enemies and the boss

**Earlier development:** the Proto-Weaver received encounter/arena tuning, traversal-intermission work, presentation updates and an August 14 death cinematic. The July combat pass also developed enemy hurt responses, Tensioner behavior and enemy health feedback. These are substantial development-history topics but predate the provisional demo baseline.

There is **no post-RC2 tracked change under `Src/Enemies/ProtoWeaver`** in the reviewed endpoint comparison. Do not claim a new post-demo boss overhaul based on older commits.

**Committed after baseline:** shared enemy code prevents enemies physically balancing on the player's head and refreshes target availability when player targeting is suspended. Contact damage respects that suspension. These fix awkward overlap and invalid targeting behavior.

**Current experiment:** two Blue-region enemies are instantiated in the lake greybox:

- **Reedhook:** a dry-platform enemy with a planted hook windup, short forward sweep and punishable recovery. Facing locks, hurt interrupts the attack, walls block hits, and edge probes keep it from intentionally walking into water. No passive idle-contact damage.
- **Tide Duelist:** a swordfish-like underwater enemy that holds position, curls into a draw, flashes its eye and commits to a fixed-direction dash. Windup/recovery are harmless, damage interrupts it, and containment checks keep it inside connected water rather than crossing banks or dry pockets. It does not perform maze navigation.

Both reuse existing death/reset foundations and remain first-pass enemies. The September 25 request for a sharper blinkstrike feel is an unresolved playtest item, not a completed improvement merely because a dash exists.

**Evidence:** `dc22da46`; [Reedhook](../art/reedhook_behavior.md); [Tide Duelist](../art/tide_duelist_behavior.md); `Src/Enemies/Reedhook/`, `Src/Enemies/TideDuelist/`; lake scene instances. Boss history: `a32a7109`, `3c0895b6`, `a88d463c`, `5f3ddef4`, `ccd51015`, `1691cce0`, `e58b3c93`.

## 6. UI/UX, guidance and reliability

**Committed after baseline, release-window caveat:** August 15 work adds/cleans up the lore index and notifications, Thread guidance glyphs and trial timer; improves inventory selection/tab navigation and merchant spacing/re-entry; presents follower dialogue in a lower-third layout; prevents cancelling a menu from also dashing; and restores camera follow after merchant/save interactions.

Death handling gained repeated-death fallback and recovery from orphaned game-over state. These are player-visible reliability fixes: being able to resume control matters more than their internal implementation.

**Current experiment:** controls documentation includes Block and the updated interaction mapping; Dive uses the existing interaction binding. The review does not establish a wholly new menu redesign after the demo.

**Evidence:** `cc892dc4`, `cb59eff0`, `c281c2e6`, `a8981843`, `4275d790`, `e25d05ee`, `327ac1e5`, `6bb9c1af`, `ef6dcddc`; baseline/current changes under `Src/UI/` and `Src/Global/input_binding_manager.gd`.

## 7. Audio

The central audio manager, separate volume categories, music layering and enemy/boss attack sounds were developed in June, with additional combat/boss registry work in July and early August. They already precede RC2.

The confirmed post-baseline audio-manager change adds `stop_game_over_music()`, clearing the death-music state and stopping that track when appropriate. There is no tracked audio-registry delta or newly established soundtrack overhaul between RC2 and HEAD in the reviewed paths. Current attack work coordinates strike feedback with animation, but that is not evidence of newly authored sound assets.

**Evidence:** `git diff 9bc22046 HEAD -- Src/Global/audio_manager.gd`; history of `Src/Global/audio_registry.tres` (including `3c0895b6`, `a88d463c`). Safe public wording emphasizes feedback/recovery fixes rather than promising a new soundtrack.

## 8. Equipment, currency and progression

**Earlier development:** the Pattern concept and merchant Pattern equipment were introduced in July (`7c090e78`, `687dcd10`). They should not be represented as new since an August demo. The project continues to emphasize expression and base-kit completion; design text about future identity/progression is not implementation evidence.

**Committed after baseline:** Thread Knot recovery was added August 22. Held currency and the recovery pile's amount, scene and position are saved; a recoverable pile can be claimed. This changes the consequences and continuity of death, rather than introducing a new class or permanent-build system. Release-window merchant changes also trimmed offerings and adjusted lore pricing.

**Current experiment:** the model carries sword/shield/grapple artwork and the controller implements guard. The presence of these meshes does not establish a complete new equipment economy, unlock tree or finalized equipment replacement. Water-item references and prototype/debug access must not be presented as a completed region-wide progression quest.

**Evidence:** `d0c9c559`, `ef7ffd5e`, `b5f4bdd0`; `Src/Global/demo_progress.gd`, `Src/Pickups/recovery_thread_knot_pile.gd`; [equipment slots](../gameplay/equipment_slots.md), [progression](../design/progression_and_choices.md), current player guard code.

## 9. Technical work with a player-facing consequence

- **Earlier animation memory reduction:** normalization reduces raster dimensions by half, retaining intended on-screen size. The documented raw RGBA estimate falls from approximately 800 MiB to 200 MiB for that sprite folder. This is a historical texture-memory estimate, not a benchmark for current overall RAM or the live 3D version.
- **Post-baseline reliability:** death recovery, camera restoration, collision corrections and controller input separation directly address interruptions to play.
- **Authoring tools:** reusable room greyboxing, polygon editing and preview tooling make it possible to test routes before committing finished art. This is a development benefit; a faster content-production rate or FPS gain has not been measured here.
- **Current hybrid rendering:** transparent orthographic 3D rendering feeds a 2D composite while Godot's existing controller owns world movement. Recent outline, sword-material and mesh corrections target legibility. Snapshot effects have bounds, but this does not establish acceptable performance on all hardware.

**Evidence:** normalization document; `abb6a9b0`, `647dbbd3`, `cfa4166f`, `e35f0687`, `02a3648d`; [greyboxing workflow](../design/room_greyboxing_workflow.md); current live-player code and September 26 notes.

## 10. The 3D / 3D-to-2D player experiment

The pipeline explored both rendered sprites from a rigged character and a live 3D model rendered into the 2D game. The initial equipped sprite test exported 125 frames at 30 FPS on fixed canvases, removed baked jump travel, and tested lighting/outline treatments. A parallel live-model test uses real normals, stylized lighting and a transparent viewport composite.

Early pipeline notes say these are isolated tests that do not replace the production player. **That describes an earlier stage.** The current working `player.tscn` references `player_live_3d_visual.gd`, which loads the equipped model, hides legacy visuals and installs the authored attack library. The experiment is now integrated into the local player scene, though uncommitted and not demonstrated as released.

The work includes shoulder/arm deformation, fingers, sword grip, shield mounting, side-on framing, transferred Mixamo actions, authored aerial poses, swimming blends, ledge animation, hurt/death and save-point transitions. A large animation library is not equivalent to that many finished gameplay moves; many catalog entries are explicitly candidates.

The documented practical problems are consistent proportions, coherent transitions, readable weapon contact and agreement between character rendering and painted environments. Using a rig offers an editable basis for those problems; it is an experiment rather than proof that the final art pipeline has been settled. Current work still needs normal-speed feel review, environment scale/cohesion judgment and performance observation. A local knee-mesh patch also needs reapplication after a fresh full mesh export.

**Evidence:** [Blender pipeline](../art/player_blender_pipeline.md); [animation map](../art/player_animation_gameplay_map.md); [September 14 review](../art/gameplay_review_2026_09_14.md); [manual guide and September 26 updates](../art/manual_aerial_animation_guide.md); actual current player scene/script and GLB references.

## Editorial decisions for Devlog #4

1. Describe this as a development catch-up, not a patch announcement. No new downloadable version was established.
2. Separate the earlier sprite/Flow/boss work from post-baseline prototypes. Until the public demo commit is identified, do not say all July–September work occurred after launch.
3. Give combat, Flow simplification, water traversal, Blue-region art and the character experiment the most space.
4. Mention audio honestly as a smaller maintenance/feedback topic. Do not pad it into an unsupported overhaul.
5. Label screenshots by date and prototype stage. Earlier recordings do not show today's attack implementation.
6. Keep design intent distinct from demonstrated effect: readability and expressive traversal are supported aims; claims that everything is now smoother, balanced or faster require playtesting.

## Review method and limits

Inspected Git version changes, first-parent history, relevant feature commits, baseline-to-HEAD diffs and current uncommitted scripts/scenes/docs. Reviewed 172 screenshot thumbnails from July 23 onward and 16 sampled frames from two local recordings (September 14 and September 26). Selected images were then packaged with provenance. This is not exhaustive frame-by-frame review of every local video.

No game code, scenes, source artwork, existing design documents, saves or Git history were changed for this report. Existing verification results are attributed to project notes; the gameplay test suite was not rerun for this writing task. No public release/tag fetch or Itch publication was performed.
