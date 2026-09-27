# Player animation inventory

Canonical Blender library: **62 actions** at 30 FPS.

## Integrated in gameplay

| Action | Frames | Current use |
| --- | ---: | --- |
| `block_1` | 17 | Standing block entry. |
| `block_idle_1` | 42 | Standing block hold. |
| `casting_2` | 32 | Directional base-grapple throw. |
| `crouch_1` | 18 | Standing-to-crouch transition. |
| `crouch_block_1` | 15 | Crouched block entry. |
| `crouch_block_2` | 22 | Crouched blocked-hit reaction. |
| `crouch_block_idle_1` | 9 | Crouched block hold. |
| `crouch_idle_1` | 72 | Crouch idle. |
| `crouching_1` | 16 | Crouch-to-standing transition. |
| `crouching_2` | 15 | Crouched-block exit. |
| `crouching_3` | 20 | Crouched hurt reaction. |
| `death_1` | 70 | Backward death. |
| `death_2` | 118 | Forward death. |
| `get_up_from_hang_1` | 35 | Ledge climb/get-up. |
| `grab_ledge_from_water_1` | 151 | Water-to-ledge transition. |
| `grapple_swinging_1` | 60 | Airborne attached-grapple swing. |
| `hanging_idle_1` | 71 | Ledge/wall hanging loop. |
| `idle_1` | 109 | Timed idle variation: look around. |
| `idle_2` | 227 | Timed idle variation: sword flourish. |
| `idle_3` | 261 | Timed idle variation: flourish/battle cry. |
| `idle_4` | 77 | Primary idle loop. |
| `impact_1` | 22 | Standing blocked-hit reaction. |
| `impact_2` | 30 | Light standing hurt. |
| `impact_3` | 22 | Heavy standing hurt. |
| `jump_1` | 26 | Running jump and ordinary airborne pose. |
| `jump_2` | 30 | Double jump. |
| `jump_into_wall_hang_1` | 40 | Wall-hang entry. |
| `jumping_into_water_1` | 37 | Downward water-entry transition. |
| `power_up_1` | 72 | Neutral sword-and-shield special with chest-centered burst. |
| `roll_1` | 36 | Dash/roll. |
| `run_1` | 22 | Normal ground locomotion. |
| `run_2` | 17 | Shielded backpedal. |
| `sit_to_stand_1` | 69 | Save-point stand-up transition. |
| `slash_2` | 107 | Three input-driven light-combo segments. |
| `slash_5` | 42 | Crouch attack. |
| `stand_to_sit_1` | 68 | Save-point sit-down transition. |
| `swimming_1` | 137 | Swimming locomotion. |
| `turn_1` | 29 | Save-point turn toward camera before sitting. |
| `turn_2` | 29 | Save-point turn back to gameplay profile after standing. |
| `water_idle_1` | 91 | Stationary water idle. |

## Downloaded and retained, but not currently used

| Action | Frames | Good candidate use |
| --- | ---: | --- |
| `attack_1` | 71 | Aerial overhead special or grapple-assisted attack. |
| `attack_2` | 40 | Running spin attack. |
| `attack_3` | 53 | Low sweep or alternate running attack. |
| `attack_4` | 31 | Pommel guard break, door knock, or contextual strike. |
| `block_2` | 16 | Alternate block entry or short guard adjustment. |
| `casting_1` | 90 | Thread magic, ranged special, or power technique. |
| `draw_sword_1` | 16 | Compare with sheath actions; likely redundant. |
| `draw_sword_2` | 24 | Compare with sheath actions; likely redundant. |
| `kick_1` | 37 | Guard break or breakable-door interaction. |
| `sheath_sword_1` | 39 | Enter a future sheathed locomotion set. |
| `sheath_sword_2` | 26 | Exit a future sheathed locomotion set. |
| `slash_1` | 46 | Standalone single slash or NPC/simple enemy attack. |
| `slash_3` | 48 | Riposte or retreating counterattack. |
| `slash_4` | 70 | Sprint, grapple, or aerial special. |
| `strafe_1` | 35 | Toward-camera cinematic movement. |
| `strafe_2` | 40 | Away-from-camera cinematic movement. |
| `strafe_3` | 21 | Fast away-from-camera cinematic movement. |
| `strafe_4` | 22 | Fast toward-camera cinematic movement. |
| `turn_180_1` | 25 | Walking direction-change transition. |
| `turn_180_2` | 26 | Sprinting direction-change transition. |
| `walk_1` | 34 | Slow forward locomotion if walking is introduced. |
| `walk_2` | 38 | Slow backward locomotion if walking is introduced. |

## Still needed

- Grapple aim/charge pose that can hold indefinitely before release.
- Grapple pull/reel-in, grapple release, and grapple-assisted attack variants.
- Air light chain plus up-air and down-air attacks.
- Wall slide/climb loop and a dry ledge-grab transition.
- Swim stop, underwater rise/dive, and water-exit variants beyond the ledge grab.
- Landing variants for short fall, hard fall, and grapple release.
- Weapon sheath locomotion/idles if sheathing becomes normal gameplay.
- Parry/perfect-block success, guard break, and guard-broken reaction.
- Sword-and-shield interaction poses for doors, levers, and pickups.

All source FBXs are retained under `ArtSource/Player/Blender/imported_character/mixamo_library/source`.
The Downloads-folder copies are disposable after byte-for-byte verification.
