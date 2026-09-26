# Your aerial attack workspace

Open `ArtSource/Player/Blender/ManualAttacks/Threadborne_Aerial_Attacks_Workspace.blend`.

This separate copy starts in Pose Mode, side-on, with the sword-hand control selected. The current game export and original equipped source are untouched. The posing mesh is the lighter preview; the full-resolution character is retained but hidden. Three held-pose templates are included, not completed attack animations:

- `air_attack_forward`: east when facing right; can mirror for west in-game.
- `air_attack_up`: north-facing arc.
- `air_attack_down`: south-facing arc / eventual pogo strike.

Choose an action with the action dropdown in the Action Editor below the viewport. All three have keys at frames 1 and 24, at 30 FPS. Existing attack libraries were removed from this copy's dropdown to keep the workspace focused.

## First animation, step by step

1. Stay in **Pose Mode**. Select the green wire cube, `CTRL_SwordHand`.
2. Click frame **5** in the Action Editor. Press **G** over the 3D view to move the hand into a windup. Click to accept, or Esc to cancel. The arm follows using IK.
3. Press **R**, then **X**, to rotate the hand/sword in the side-view gameplay plane. Click to accept. In this particular rig, screen-right is world **-Y**, and screen-up is **+Z**. `G`, `Z` moves vertically; `G`, `Y` moves horizontally in this view.
4. With the changed control selected and the pointer over the 3D view, press **I**. The workspace has **Location, Rotation & Scale** as its active keying set. This records the pose. Auto Key is off, so key before changing frames.
5. At frame **8**, pose the contact point, then press I again. At frame **12**, pose the follow-through and key it. At frame **18**, ease back toward the ready pose and key it. Frame 24 already holds the original airborne pose.
6. Press **Space** to play/stop. Adjust the poses or timing. In the Action Editor, select keys and use **G** to shift their timing.
7. **Ctrl+S** saves this working file. Use **Ctrl+Shift+S** for another version before a large experiment.

The yellow diamond, `CTRL_SwordElbow`, determines where the elbow bends. Move and key it if the elbow starts pointing the wrong way; keep it away from the straight shoulder-to-hand line. The wrist control moves the arm and rotates the blade. Do not pose the right upper arm/forearm directly while their IK is active.

The visible chest/pelvis/head and left arm bones can be rotated for weight and balance. Key each bone you change. Avoid rotating only the wrist to make the entire cut: move the hand through a broad arc and let the chest support it. Fingers and weapon grip start from the existing equipped pose. Do not move the entire rig/root object to create jump or dash travel; Godot owns that movement.

Use the middle mouse button to orbit and the wheel to zoom if needed. The initial orthographic view is the gameplay side view. The Blend also contains a **START HERE - Aerial Attacks** text block with these essentials.

## Starting timing, not a requirement

| Frame | Intent |
| --- | --- |
| 1 | Airborne ready pose |
| 5 | Windup / anticipation |
| 8 | Contact |
| 12 | Follow-through |
| 18 | Recovery |
| 24 | Back to airborne ready |

Start with forward, then make distinct up/down arcs. West can use a mirrored forward animation, as the current player already mirrors when facing left. These authored arcs can overlap slightly without rotating the entire arm toward every aim angle.

## Returning to the game

### Forward attack body pass

`ArtSource/Player/Blender/ManualAttacks/Threadborne_Aerial_Attacks_FullBody.blend`
contains the user's saved `air_attack_forward` sword animation with added torso,
head, shield-arm and leg support. The original workspace remains untouched.
Sword-hand and elbow control curves, including their handles and timing, are
preserved exactly. Up/down actions remain the original templates.

The support anticipates at frame 5, drives into contact at 8, follows through
at 10–12, and settles through 18 back to the matching frame-24 pose. The pass
was checked across half-frame samples for finite transforms and an exact loop
pose match. The unstretched IK hand can still fall short of the authored target
by up to 0.088 model units during the sweep; the target keys were retained.
An untextured motion preview is saved beside the Blend as
`air_attack_forward_full_body.gif`. This pass has not been exported to Godot.

### Directional attack set

`ArtSource/Player/Blender/ManualAttacks/Threadborne_Aerial_Attacks_Directional.blend`
contains the approved forward action unchanged plus authored `air_attack_up`
(rising slash) and `air_attack_down` (downward stab). Choose the action in the
Action Editor. Both use the same 1–24 frame, 30 FPS cadence: anticipation at 5,
contact at 8, follow-through at 10–12 and recovery by 18. Each returns to the
same ready pose at 24. Up/down have supporting torso, shield and leg motion;
the torso is not rotated wholesale to aim the attack.

All half-frame samples passed finite-transform and IK reach checks (maximum
hand-target error below 0.000002 model units), and both endpoint poses match.
Rendered frame sequences were reviewed. The previews alongside the Blend are
`air_attack_up_preview.gif` and `air_attack_down_preview.gif`. These are Blender
animations only; runtime selection, baking, hitboxes and VFX timing are not
integrated yet. Earlier workspaces are preserved.

The revised `Threadborne_Aerial_Attacks_Directional_v2.blend` supersedes that
first directional study. Up now chambers with a bent elbow and an upright
blade, then thrusts vertically, without the previous rising slash. Down
extends the arm farther and tucks both legs so the blade leads the feet.
Evaluated preview-mesh foot vertices sit approximately 0.50 model units above
the sword tip at contact frames 8–10. Both clips passed half-frame IK reach
checks and matching endpoint checks. Forward remains unchanged. Previews are
`air_attack_up_v2_preview.gif` and `air_attack_down_v2_preview.gif`.

### In-game authored attack integration

The v2 air set is now active in `player_live_3d_visual.gd`, using the baked
animation donor `Assets/Threadborne/Player/Equipped3DTest/threadborne_authored_attacks.glb`.
The existing equipped model and locomotion library remain in use. No procedural
shoulder aiming or leg replacement is applied over the authored air clips.
Live damage and sword-sweep timing use source frames 7–11 on the imported
zero-based timeline. Base attack playback is 1.0; momentum attack-speed
modifiers still apply. Grounded attacks and the spin special are unchanged.

`Threadborne_Water_Attacks_Workspace.blend` contains `water_attack_idle` and
`water_attack_move`, alongside the approved air clips. Idle copies the approved
forward attack. Move samples the existing swimming body/legs and places the
same hand/elbow target path relative to the swimming shoulder. These editable
IK actions are baked only in the disposable export process. In-game, their
poses blend over swim speed (fully moving at 120 px/s), with both clips sampled
at the same attack time. The moving display retains swim-direction tilt.
Water slashes hit ahead along swimming direction, or facing direction at rest;
independent vertical aim is not represented by this forward-only water pass.

The exporter is `tools/art/export_authored_player_attacks.py`; it refuses to
overwrite the water workspace. Previews beside the Blend are
`water_attack_idle_preview.gif` and `water_attack_move_preview.gif`.
The combat verification script checks directional clip selection, actual
up/down sword orientation after import, active damage windows, duration,
water idle/moving/vertical travel and forward hit direction, and existing
spin/neutral-special behavior. Godot completed with the existing certificate,
user-log access and shutdown resource warnings, without script failures.

Playtest: air left/right, up, down/pogo; water attack while still, horizontal
and vertical swimming; start/stop swimming during a swing; cancel into dash;
then verify grounded combos and the directional spin still feel unchanged.

Saving the Blend does **not** change the game. Once an action is ready, bake the IK's evaluated motion onto the deformation bones, export the chosen clips, and align damage/VFX windows to the authored contact frames. Integration must replace the current runtime directional arm rotation for these attacks; otherwise it would distort the newly authored poses. Water will still need a separate blending review.

Do not run `prepare_manual_aerial_workspace.py` to update your animations. It is a one-time setup script and refuses to overwrite an existing manual workspace.

Blender reference: [Posing](https://docs.blender.org/manual/en/latest/animation/armatures/posing/index.html), [keyframe editing](https://docs.blender.org/manual/en/latest/animation/keyframes/editing.html).
## 2026-09-26 attack feedback pass

- Grounded attack one and spin silver strokes unchanged.
- Second grounded hit moved from source frames 46–56 to 37–42. Sampled the actual sword path: the front sweep is at 37–42; by 46 the tip crosses behind the player. Damage and effect share the corrected window.
- Third grounded hit uses 1.65x stroke width, slightly wider blade sampling, and larger but still narrow silver ground-contact streaks.
- Forward air/water trail samples source frames 4–10 to capture the arc before contact. Damage remains 7–11.
- Up/down imported animations are retimed at library installation: extend at 1/30 second, hold through 0.17, withdraw by 0.27, end 0.32. Active damage frames 1–5. Existing momentum speed modifiers apply. This changes runtime copies only; approved Blender sources remain intact.
- Up/down effects add a narrow translucent silver cone with outlined edges beyond the blade. Hitbox radius remains unchanged; no sword mesh/material edits.
- Headless combat checks passed for actual up/down blade orientation at the new contact time, pre/post hit windows, duration, water attacks and existing special attacks. Existing certificate/log-access and shutdown resource warnings persist.

Playtest: compare grounded 1/2 timing, third overhead/contact weight, forward-air arc, and rapid up/down pogo response and recovery. Sword brightness/material pass remains deferred.

## 2026-09-26 player and water readability

- Composite outline width reduced from 4 to 2 source pixels; sparse alpha coverage reduces outlining of isolated coat fringe strands.
- Sword-only runtime material keeps its texture and geometry, with brighter cool albedo, roughness 0.25, metallic 0.35 and GGX highlights. Other equipment/cloth retains toon shading.
- Removed Run fallback from submerged animation selection. A stationary blocked swimmer uses Swim_Idle.
- Polygon water and pockets use the player's collision center consistently, including delayed area overlap transitions. Legacy rectangular volumes retain signal-driven membership.
- Wakes require wet-body state and a wet spawn point. Drawing clips ring segments against polygon water and air pockets.
- Air-pocket fill uses absolute z=-2, behind greybox collision tiles.
- Passed verify_lake_readability.gd and verify_lake_attack_refresh.gd. Headless checks validate state/material configuration, not final on-screen art. Existing certificate/log and shutdown resource warnings remain; swim-idle legacy glove animation warning also observed.

## 2026-09-26 final blade alignment and silhouette pass

- Outline is now 3 source pixels, between the original 4 and the reduced 2; fringe coverage filtering remains.
- Main idle rotates the sword wrist 14 degrees to separate the tip from the head. The composite alpha outline cannot draw an internal edge between overlapping opaque parts.
- Sword trail anchors now use measured mesh-local blade centerline points instead of a bounding-box corner. This also aligns the blade-shaped up/down effects.
- Third-hit trail covers frames 71–90, including the overhead arc. Unqueued combo completion resets to hit one. Forward aerial recovery is shortened; vertical effects use a 1.3x blade silhouette instead of the earlier cone.
- Increased viewport height preserves pixel scale while giving up-stab tip clearance.
- The knee protrusion existed in the mesh without the outline. A localized position/normal patch rounds that fold; animation, skin weights, UVs and materials are retained. Original runtime GLB is backed up in `ArtSource/Player/Blender/ManualAttacks/threadborne_before_knee_cleanup.glb`.
- `tools/art/apply_player_knee_patch.py` and `player_knee_vertex_patch.json` retain the correction. Authoring Blend files remain unchanged: a fresh full mesh export would require reapplying the correction. The patch refuses to run when its backup already exists.
- Re-ran `tools/combat/verify_lake_attack_refresh.gd` successfully after blade alignment and mesh reimport. Reviewed knee correction in a Blender render; in-game visual review remains necessary.
