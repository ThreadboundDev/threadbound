# October 21, 2026 development checkpoint

This checkpoint preserves accumulated work after the project chats were archived.
Branch: `threadbound/chore-october-development-checkpoint`.
Starting revision: `5f42ee0b` on `water-cleanup`, already one commit ahead of its
locally recorded upstream. That existing commit is retained in this branch.
No history was rewritten, assets switched, or gameplay redesigned for this cleanup.
The complete branch is the checkpoint; topic commits group the review, rather
than promising that every intermediate commit runs independently.

## What is preserved

| Area | Work and current state |
| --- | --- |
| Existing foundation | The inherited history contains the demo/chamber systems, live 3D player, movement and combat, water combo/specials, bulbs, Tide Duelist, Reedhook, Bellstriker revisions, lake greybox, pavilion/deck work and earlier design notes. The September checkpoint and demo-to-current devlog remain the longer historical records. |
| Player contact fixes | Capsule body collision with stance/headroom support, foot registration for both shape types, hand-height wall/ledge qualification and projected 3D hand anchoring. The bumper and defense/feedback checks were adapted for the capsule. |
| Swordfish/environment interaction | Committed damaging fish dashes can fracture marked walls; breakable wall/rock scenes, staged fracture visuals, restoration, bulb art depth/state fixes and the Room Greybox Breakable Wall button are preserved. Ordinary terrain remains solid. |
| Lakeside room | Krita artwork import, rock collision, water/air pockets, art-preparation and playtest scenes, 3D buildings with cutaways, landmark navigation, HUD and enemy restoration. Map extraction/build/import scripts, reference inputs and reports remain available under `work/`. |
| Villagers | Net Mender and Boatwright sources, v1/v2 exports, shared material maps, workstations, work/talk animation, greeting behavior and reusable scenes. Existing interaction/floor checks currently fail; see below. |
| Woven guardians | Eave Runner wall attacks and fallback pin; ranged Loom Heron with locked needle and low recovery; shared visuals/projectile code, authored room placement and art review tools. EnemyBase protects revived enemies from an older death timer. |
| Character revisions | Packed Blender sources and v1/v2 exports are retained. Active Eave Runner and villagers use v2. The active heron uses v3. Eave Runner v3 source, export, fitting studies and diagnostics are retained as unfinished work; gameplay still selects v2. |
| Building/concept deliveries | Lakeside building package, junction/character/guardian concepts, central tower concept iterations and tower models v1-v3 with textures, exterior/cutaway GLBs, editable Blender sources, roof corrections, previews and verification reports. The tower packages are standalone art deliveries, not a newly installed game-scene replacement. |
| Planning and handoff | Status/work queues, next play session, faction/world-context notes, enemy/art documentation, updated water/air attack history and dated verification reports. Proposals remain proposals; checkpointing them does not approve new systems or lore. |

## Fresh verification of the checkpoint working tree

Engine: local Godot `4.7.2.stable.mono.official.ed1daf0bf`.
All runs were background/headless with `--audio-driver Dummy --fixed-fps 60
--quit-after 2400 --path .`. SceneTree scripts use `--script`; `.tscn` fixtures
are passed as the scene argument. `APPDATA` was redirected to
`tmp/checkpoint_2026_10_21` so the normal save/settings were not used.
Full logs remain in that ignored local folder.

| Fixture | Fresh result |
| --- | --- |
| `tools/environment/verify_capsule_ledge_contact.gd` | PASS: 49 checks; both projected hand contacts within 0.08px, stance, headroom and ledge cases. |
| `Src/Tests/PlayerCombat/player_defense_test.tscn` | PASS: front/rear defense and capsule crouch. |
| `tools/enemies/verify_tide_duelist.tscn` | PASS: all success markers, including containment, interruption, collision and reset. |
| `tools/environment/verify_greybox_walls_and_bulb_art.tscn` | PASS: 26 checks. |
| `tools/enemies/verify_woven_guardians.gd` | PASS: 134 checks. |
| `tools/enemies/verify_woven_lakeside.gd` | PASS: 19 checks against the authored room and real player. |
| `tools/art/verify_heron_quality_v3.gd` | PASS: 167 checks. |
| `tools/art/verify_eave_quality_v3.gd` | FAIL: 2 of 147 checks. The actual prefab uses v2, so v3 model-selection and topology expectations are unmet. V3 is not installed or accepted by this checkpoint. |
| `tools/art/verify_character_quality_v2.gd` | FAIL: 1 of 97 checks. The old v2 heron topology expectation no longer matches the installed v3 bird. |
| `tools/environment/verify_lakeside_villagers.gd` | FAIL: 12 of 48 checks, including greeting/selection/facing and Boatwright floor contact. Needs focused reproduction; do not infer that current NPC interaction works from older reports. |
| `tools/environment/verify_lakeside_hud_and_breakables.gd` | FAIL: 6 of 65 checks. The fixture still expects three enemies while the newer guardian fixture validates five; the authored wall-restoration expectation also fails. Classify the remaining mismatch before changing runtime code. |
| `tools/environment/verify_lakeside_krita.gd` | FAIL: 4 assertions: Fisher house and Workshop player-floor and facade-entry cases. Tower floor/cutaway and sampled artwork/collision registration pass. Cause not established by this checkpoint. |
| `tools/environment/verify_lakeside_preview_resize.gd` | UNSUPPORTED: requires real Forward+ rendering; headless prints an error even though the process exits 0. This is not a passing check. |

Several passing runs still emit the previously documented ObjectDB/resource
shutdown diagnostics. Passing assertions do not establish clean resource
ownership, GPU appearance, frame time, full-demo behavior or export readiness.
Older delivery reports describe their dated revisions and are not current passes.
No graphical windows were opened for this checkpoint.

## Repository contents and storage

New source/runtime work, named art versions, concepts, review stills, diagnostic
scripts and reports are committed. Large 3D sources/exports and delivery/reference
images use Git LFS; repeated identical payloads can share LFS storage. The tower
v1 `.blend@` file is preserved too because it differs from its `.blend` neighbor.
Existing history and older binary tracking rules were not migrated.

Reproducible isolated import projects, engine binaries, test user data, logs,
temporary Blender build directories, and explicitly named raw animation capture
sequences stay local/ignored. Packaged GIFs and deliberate stills remain tracked.
No source files were deleted to make Git status clean. The original layered
Krita input is referenced by the import tools at its original external path;
the extracted map assets and import records present in this repository are saved.

## Next work, in order

1. Reproduce the Fisher house/Workshop floor and villager greeting failures in a
   focused task, distinguishing fixture assumptions from runtime defects.
2. Reconcile the older three-enemy/v2-art fixtures with current authored content
   and confirm the wall-restoration mismatch. Keep historical results dated.
3. Review the retained Eave Runner v3 work before any asset switch. Its presence
   in Git does not make it the active or approved model.
4. Use `docs/next_test_session.md` for the short visual/feel checks and H1 water
   controls session. Then continue H2-H5 as listed; full demo/export/performance
   acceptance remains outstanding.

Continue from this branch. For each subsequent focused task: inspect status,
make the authorized change, run relevant checks, commit the coherent result,
and push before moving to another direction. This recovery checkpoint is not a
reason to repeat large mixed-work checkpoints as the normal workflow.
