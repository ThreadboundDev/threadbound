# Underwater combo: downward / upward / two-handed flip

Current runtime notes reviewed October 5, 2026 against `5f42ee0b`. Source workspaces below are retained history. No automated checks or hands-on acceptance were performed during this note cleanup. Use [the next test session](../next_test_session.md) for player review and [the work queues](../project_status_and_worklist.md) for priorities.

## Current runtime: grounded attack motion with dynamic swimming legs

The live player derives all three water strikes from the grounded `slash_2` combo (segments starting at 0.00, 1.15, 2.33 seconds), not the separately authored water donor. Pelvis/root, torso, arms, sword and the complete spin/front flip are unchanged. Only thigh/shin/foot/toe rotations are adapted: a continuously sampled `water_idle_1` leg pose carries 65% of each grounded joint's motion relative to its whole-combo initial pose, and the grounded leg rotation blends 75% toward that moving water pose. This produces tucked, floating legs that still bend/kick with the attack, rather than a planted stance or frozen swim pose. A common reference and swim phase across all three hits prevent handoff snaps. All bone positions/scales stay authored.

`water_attack_swim_leg_blend` (default 0.75) controls the standing-to-swimming leg mix; `water_attack_leg_motion_strength` (default 0.65) controls how much attack articulation is carried onto the swimming base. These values build the generated clips when the visual initializes; restart the scene after tuning. The display still leans forward by 10 degrees toward the strike's locked facing, pivoting around the collision center rather than the feet. `water_attack_forward_tilt_degrees` controls the lean. Model-root compensation cancels net pelvis travel so swimming physics still owns movement without attack-frame jumps. This presentation is generated in `PlayerLive3DVisual._install_water_combo`, so future grounded-animation updates feed the water attacks too. No Blender files or animation exports are changed.

Playback defaults to 2.5x, matching the current grounded effective playback rate. Active windows are rebased to segment-local frames: 16–24, 3–8, 10–20 (30 FPS, zero-based). Tap-to-buffer, swimming movement, per-strike facing lock, existing VFX, damage profiles, and finisher coverage are retained. Automated verification checks every unchanged bone against the grounded clip at every sampled frame, the dynamic swim/attack leg rotations, moving thighs, and handoff continuity, plus 3D/projected pelvis anchoring in both facings, forward tilt, timing, movement, damage deduplication, buffering, interruption, and water exit. Underwater special abilities retain their existing swim-leg adaptation; this revision changes only the basic combo presentation. Verification can run headless without opening a game window.

## Underwater abilities

The existing `SpecialAttack` input now works underwater: no horizontal input uses the neutral explosion; holding left/right uses the corresponding directional spin. Both keep the existing 2-AP cost, damage, hit windows, cooldowns, audio, hitstop, and VFX. Dry airborne initiation remains unavailable.

`water_neutral_special` derives from `power_up_1`; `water_spin_special` derives from `attack_2`. They reuse authored upper-body motion with `water_idle_1` legs, preserving the special's body rotation while canceling root translation. Facing is held for the ability, without tilting to the swimming direction. No Blender files or exported animation assets are changed.

Neutral allows normal swimming throughout. Spin allows normal steering during windup/recovery, with its existing horizontal burst during the active window and vertical swim control throughout. Water hitboxes and neutral charge/impact effects are centered on the swimmer rather than projected onto a floor. Crossing a water surface swaps between the adapted and original animation at the same clip time, without restarting damage windows or spending additional AP.

`tools/combat/verify_water_specials.gd` checks all three inputs, source motion/swim legs, frame-by-frame pelvis anchoring, movement, AP, radial coverage, single hits, water entry/exit, cancellation, and cleanup. `tools/combat/render_water_specials.gd` generates a neutral/spin pose contact sheet for visual review.

## Current runtime verification

Run Godot with `--headless --path . --script` and:

- `res://tools/combat/verify_water_combo.gd` for the live grounded-to-swimming adaptation, handoffs, both facings, hit windows, buffering, coverage, cancellation and anchoring.
- `res://tools/combat/verify_water_specials.gd` for underwater neutral/spin adaptation, AP, movement, hits and surface transitions.
- `res://tools/combat/verify_lake_attack_refresh.gd` for the wider air/water/ground-special regression.

The `render_water_combo.gd`, `render_water_combo_motion.gd` and `render_water_specials.gd` tools capture current game poses. In-game control, contact and normal-speed readability still require hands-on review; inspect the runtime result before editing a preserved donor.

## Earlier authored version (historical)

All prior manual Blender workspaces and water exports are preserved. The documentation below describes that earlier authored version, no longer used for live water-combo animation.

The earlier authored basic attack used three swim-idle-based clips. Its timing and presentation below are historical, not current tuning. Tap once for the opener;
tap again during each strike to buffer the next. Holding attack does not auto-chain.
Each strike can queue only one follow-up; the finisher ends the chain. Swimming
movement remains available. Movement does not tilt the authored attacks; facing is held
for each strike, with the next strike able to face the new input direction.

| Action | Blender frames (30 FPS) | Active frames (Godot, zero-based) | Coverage |
| --- | --- | --- | --- |
| water_combo_1 | 1–23 | 6–14 | 140-degree forward downward cut |
| water_combo_2 | 1–23 | 4–14 | 140-degree upward return cut |
| water_combo_3 | 1–39 | 12–30 | 360-degree two-handed front-flip slash |

The first cut raises the sword, cuts downward, and settles at the right hip.
At that stage playback used `water_combo_playback_speed = 1.25` on the player (25%
faster than the authored clips), multiplied by the existing momentum attack
speed. Strike duration follows that playback speed; damage and VFX windows
remain tied to the current animation frame.
The second reverses from that hip pose to above the head. The third raises the
shield hand to the hilt, loads both arms overhead, and carries the downward cut
through a full front flip. Torso lean, shoulder rotation, and leg tuck support
the swings. Adjacent clips have matching endpoint poses.

Existing sword-sweep effects, flow effects, hitstop, and hit receivers are reused.
Each enemy can be hit once per strike. Damage uses existing profiles: basic,
moving-finisher-second, stationary-second (base 25/25/30 before normal modifiers).
Dashing or leaving the water cancels the chain.

## Editing the preserved Blender study (historical donor)

This workflow edits/exports the older water donor. The live combo is now generated from the grounded source at runtime; exporting this study does not update it. Reintroducing the donor would be a separate approved integration change, not a routine export.

Open `ArtSource/Player/Blender/ManualAttacks/Threadborne_Water_Combo_v4_IK.blend`.
Select `Threadborne_Rig`, use the Dope Sheet's Action Editor, and select one of the
three actions above. Set the playback end to its last frame. In Pose Mode, move
and rotate the `CTRL_SwordHand` square to pose the sword arm as one unit. Move
the `CTRL_SwordElbow` diamond to change the elbow bend. `CTRL_LeftHand` and
`CTRL_LeftElbow` do the same for the free arm. `CTRL_LeftFoot` / `CTRL_LeftKnee`
and `CTRL_RightFoot` / `CTRL_RightKnee` control the legs. The pelvis bone moves
and rotates the body. All limb controls have keys in all three actions. When
rotating the whole body, move the limb controls with the pelvis so the IK targets
travel with it. Keep the pelvis anchored and preserve the handoffs from hit 1's
last frame to hit 2's first, and hit 2's last to hit 3's first.

On hit 3, `CTRL_SecondGrip` follows the sword hand and places the shield hand on
the lower hilt. Its attachment is controlled by the keyed influence of the
`Second hand follows sword grip` constraint on `CTRL_LeftHand`. It reaches full
influence at frame 8, stays attached through frame 31, and releases by frame 35.
Move `CTRL_SecondGrip` to adjust the second hand while attached. Both sets of
fingers hold a fixed closed pose; no finger editing is needed.

### Resetting a tangled sword arm

The installed **Threadbound Pose Tools** add-on adds a **Threadbound** tab to
the 3D View sidebar (`N`). Select `Threadborne_Rig`, enter Pose Mode, and pause
playback. Click **Reset Sword Arm** to return the right arm and its hand/elbow
controls to swim-ready, relative to the current shoulder. This keeps the body
pose, finger grips, frame, active action, and existing keys unchanged. It does
not auto-key, even with Auto Key enabled. Undo with `Ctrl+Z`.

After posing, click **Key Sword Arm Pose** to save only that arm and its controls
at the current frame. Do this before changing frames if you want to keep the
reset. While the two-hand grip constraint is active, the left hand will follow
the sword as usual; the reset does not change the grip constraint.

The source is `tools/art/threadbound_pose_tools.py`. To install on another
machine, run `tools/art/install_threadbound_pose_tools.py` through Blender
without `--factory-startup`; it preserves existing settings and backs up user
preferences before enabling the add-on. Restart Blender if it was already open.
No character `.blend` files are rewritten by installation or testing.

The v3 body pass uses torso/shoulder rotation from `slash_2`, finisher motion
from `attack_1`, and continuously sampled `water_idle_1` leg motion. These are
retained as `BODY_REFERENCE_GroundCombo`, `BODY_REFERENCE_OverheadAttack`, and
`BODY_REFERENCE_SwimIdle`. The sword elbow bends during loading, extends through
the cut, and folds back on recovery with an animated elbow pole.

The v4 revision preserves every saved v3 body, leg, finger and grip curve. It
only changes the sword hand/elbow controls and calibrates the right elbow pole.
At the top of the cut the elbow points forward with a modest bend; the arm
then extends to about 174–177 degrees through the cut and follow-through.
Targets follow an arc around the shoulder rather than cutting through it.
Hit 3 borrows bounded, smoothed axial wrist roll from the overhead reference
while preserving the downward blade direction. Sword controls now have keys
each frame to preserve the direction/reach during torso movement.

All controls remain editable IK. Saved v3 actions are retained as
`reference_v3_water_combo_1/2/3`; all earlier Blender files are preserved.
The preserved donor contains the v4 actions; later Blender edits need another
export to update that donor, which is no longer selected for the live combo.
Saved v3 hand rotation discontinuities are not propagated:
the continuous preserved v2 blade path is used with the existing v3 body.

Save your edits, then run from the repository root (adjust Blender's path if needed):

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python tools/art/export_water_combo.py
```

This exports only the combo clips into
`Assets/Threadborne/Player/Equipped3DTest/threadborne_water_combo.glb` without saving
changes back to the Blender source. Godot can import this preserved donor, but
the current `_install_water_combo` does not load it. Exporting it does not
change the equipped mesh, live combo, damage windows or current tests.

`tools/art/revise_water_combo_arms_v4.py` is the current generator, not the editing export
path. It refuses to replace an existing workspace unless explicitly passed
`-- --replace-generated`; that flag discards edits in the generated workspace.

## Historical source verification and current render tools

The Godot checks listed in Current runtime verification above exercise the
current generated clips, not acceptance of this historical Blender donor.

`tools/art/verify_water_combo_v2.py` runs in Blender and checks matching clip
handoffs, fixed finger poses, pelvis anchoring, and both hands reaching their
grip targets during the two-handed section. Pass
`-- Threadborne_Water_Combo_v4_IK.blend` to verify the preserved v4 source.
`tools/art/verify_water_combo_v4.py` additionally verifies exact preservation of
non-sword-control curves, the forward elbow plane, extended follow-through,
and bounded frame-to-frame wrist rotation. Near-straight arms in v4 are
intentional; the previous v3 maximum-175-degree check does not apply.

For a GPU-rendered pose sheet, run with `--path . --rendering-method gl_compatibility
--script res://tools/combat/render_water_combo.gd -- <absolute-output.png>`.
The sheet shows the equipped character poses, not the separate 2D sword effects.
In-game feel, enemy contact, and VFX readability still need a playtest.

`tools/combat/render_water_combo_motion.gd -- <absolute-output-directory>` renders
each frame of the full chain for motion review using the equipped game character.
Append `detail` to render a full-body side view and a larger front wrist inset.
