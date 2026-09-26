# Player 3D Animation Gameplay Map

This catalog records the first gameplay interpretation of the 59 imported
Mixamo actions. Canonical action names match `Threadborne_Animation_Library.blend`.

## Initial gameplay set

| Action | Proposed gameplay role | Status / notes |
| --- | --- | --- |
| `idle_4` | Base idle | Primary neutral loop. |
| `idle_1` | Idle variation | Look-around variation. |
| `idle_2` | Idle variation | Sword flourish; trigger only after a longer idle delay. |
| `idle_3` | Idle variation | Flourish/battle-cry; rare longest-delay variation. |
| `run_1` | Normal run | Primary ground locomotion. |
| `run_2` | Shielded backpedal | Keep authored direction for moving backward while blocking. |
| `walk_1` | Forward walk | Useful for slow/cinematic locomotion. |
| `walk_2` | Backward walk | Useful for slow shielded backpedal or cinematics. |
| `jump_1` | Running jump | Primary moving jump. |
| `jump_2` | Stationary/double jump | Candidate double-jump visual; test takeoff readability first. |
| `crouch_1` | Enter crouch | Standing-to-crouch transition. |
| `crouch_idle_1` | Crouch idle | Loop while crouched. |
| `crouching_1` | Exit crouch | Crouch-to-standing transition. |
| `crouching_3` | Crouched hurt | Unblocked crouching damage reaction. |
| `block_1` | Enter standing block | Transition into guard. |
| `block_2` | Alternate enter block | Retain for comparison before choosing or contextualizing. |
| `block_idle_1` | Standing block idle | Loop while guarding. |
| `impact_1` | Standing blocked impact | Guard hit reaction. |
| `crouch_block_1` | Enter crouched block | Crouch-to-crouched-guard transition. |
| `crouch_block_idle_1` | Crouched block idle | Loop while crouched and guarding. |
| `crouch_block_2` | Crouched blocked impact | Guard hit reaction while crouched. |
| `crouching_2` | Exit crouched block | Return from crouched guard to crouch idle. |
| `impact_2` | Light standing hurt | Light unblocked damage reaction. |
| `impact_3` | Heavy standing hurt | Heavy unblocked damage reaction. |
| `death_1` | Backward death | Choose based on incoming hit direction. |
| `death_2` | Forward death | Choose based on incoming hit direction. |
| `slash_1` | Reference single slash | Retained for comparison and possible later use. |
| `slash_2` | Ground light combo | Runtime divides this continuous performance into three input-driven strike segments. |
| `slash_5` | Crouch attack | Primary crouching light attack. |
| `casting_2` | Base grapple throw | Left-arm throw with runtime directional shoulder aiming. |
| `sheath_sword_1` | Sheath weapon | Leads into a future sheathed locomotion/idle set. |
| `sheath_sword_2` | Unsheath weapon | Return to equipped state. |

## Traversal additions imported September 8

| Action | Runtime use |
| --- | --- |
| `roll_1` | Dash/roll visual. |
| `grapple_swinging_1` | Airborne motion while the active grapple restricts movement. |
| `water_idle_1` | Stationary swimming/water idle. |
| `swimming_1` | Moving through prototype water. |
| `jump_into_wall_hang_1` | Entry into wall or ledge hang, followed by hanging idle. |
| `hanging_idle_1` | Loop while hanging. |
| `get_up_from_hang_1` | Ledge climb/get-up. |
| `grab_ledge_from_water_1` | Water-specific ledge-grab entry, followed by hanging idle. |

## Candidates requiring gameplay decisions or animation editing

| Action | Current interpretation | Recommendation |
| --- | --- | --- |
| `attack_1` | Jumping overhead attack | Reserve for an aerial special or grapple-assisted overhead attack. |
| `attack_2` | Spinning light attack | Candidate running attack; less readable as the default opener. |
| `attack_3` | Longer, lower spin variant | Candidate low sweep or later combo branch. |
| `attack_4` | Pommel strike | Strong guard-break/interact candidate. |
| `casting_1` | Large special/cast | Reserve until ranged or thread-special behavior is defined. |
| `kick_1` | Kick | Candidate guard break or breakable-door/wall interaction. |
| `power_up_1` | Power-up | Reserve for a progression, Flow, or scripted moment. |
| `slash_3` | Riposte/backpedal attack | Candidate counterattack or defensive retreat strike. |
| `slash_4` | Forward flipping attack | Candidate sprint, grapple, or aerial special. |
| `strafe_1` | Walk toward camera | Cinematic/3D staging; not required for normal side-on gameplay. |
| `strafe_2` | Walk away from camera | Cinematic/3D staging; not required for normal side-on gameplay. |
| `strafe_3` | Run away from camera | Cinematic/3D staging; not required for normal side-on gameplay. |
| `strafe_4` | Run toward camera | Cinematic/3D staging; not required for normal side-on gameplay. |
| `turn_1` | Turn toward camera | Candidate lead-in for Blossom/save-point sitting sequence. |
| `turn_2` | Turn away from camera | Candidate cinematic counterpart. |
| `turn_180_1` | Walking 180-degree turn | Direction-change transition at low speed. |
| `turn_180_2` | Sprinting 180-degree turn | Direction-change transition at high speed. |
| `draw_sword_1` | Sheathing toward left hip | Appears functionally equivalent to `sheath_sword_1`; compare before retaining both. |
| `draw_sword_2` | Drawing from sheath | Appears functionally equivalent to `sheath_sword_2`; compare before retaining both. |

## Initial combat behavior direction

- Standing and crouched blocking mitigate 75% of incoming damage only when the
  damaging source is on the facing side of the player.
- Block mitigation is its own multiplicative stage and does not add to the
  resistance-stat percentage.
- Rear hits bypass block mitigation.
- Perfect block and parry timing are intentionally deferred.
- The basic ground chain uses `slash_2` as one continuous source performance.
  Runtime boundaries at approximately 0.00, 1.15, 2.33, and 3.57 seconds expose
  its three attacks as separate input-driven strikes. This avoids a seam between
  two independently authored clips.
- The current preview plays those segments at 1.45x speed. Playback speed and
  strike windows remain exported values so they can be tuned after playtesting.
- Existing double-hit assumptions must be replaced by animation-event windows
  matching the visible weapon contacts of the chosen 3D actions.

## Missing animation inventory

- Grapple aim, launch, pull, release, and grapple-assisted attacks.
- Clean aerial light chain, upward/downward aerial attacks, and aerial specials.
- Dedicated dry ledge-grab entry and a wall-slide loop remain candidates; the
  current runtime now has wall-hang entry, hanging idle, water-to-ledge grab,
  and get-up-from-hang actions.
- Swim idle, swim movement, dive, surface, and water attacks if supported.
- Dash, stop, landing, hard landing, and clean locomotion transitions.
- Sheathed idle/run/jump/crouch variants if sheathing is regular gameplay rather
  than a cinematic-only action.
- Blossom/save-point sit, seated idle, and stand-up sequence.
- Optional perfect block, parry, riposte, guard break, and knockdown reactions.

## September 14 gameplay revision

- `air_light_1` is the new authored neutral aerial slash: one hit window at source frames 9–14 (zero-based, 30 fps). It is stored in `Threadborne_Air_Light_v1.blend` and exported as `threadborne_equipped_air_light_v1.glb`. Godot owns world movement. The legacy `Air_Double_Attack` name remains only as a compatibility key; the controller no longer has a second air strike window.
- `attack_1` remains available as a future overhead-special candidate. No special behavior has been assigned.
- Standing forward guard movement plays `run_2` backward; backpedaling plays it forward. The looping boundary is initialized just before its end when reversing.
- The test basin’s bank prompt starts `jumping_into_water_1` before surface contact. Automatic falls enter swimming without replaying an above-water takeoff.
