# Tonight's test — zoom, upright idle and Blue depth/bridges

Use **`threadbound/art-blue-depth-and-bridge-supports`**. It includes the saved
zoom, upright idle and the fix for delayed idle variations. Save manual editor/art
files before switching tasks. Restart the scene with F6 so current code loads.
About **5 minutes**; stop after the first two checks if tired.

1. **Demo: posture and framing (1–2 minutes).** Open
   `Src/Environment/World/Chamber Of The First Weave.tscn`. Stand for at least
   7 seconds, then turn, run/stop, jump, attack and throw the grapple. Is 0.83
   comfortably readable? Does the narrower idle feel natural? Look for floating
   boots, sliding, pose pops or sword/shield clipping. The new pose is taller:
   about 14.3% screen height at 0.83. Controls/attack timing were not retuned.
2. **Blue: depth while moving (1–2 minutes).** F6
   `Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`.
   Use the existing **Loom Heron** shortcut, then swim below the surface and
   move left/right and up/down. Far rock should drift more slowly; timber,
   ledges and collision rock should stay aligned. Look for newly exposed holes,
   distracting sliding or background rock showing above the waterline.
3. **Bridges (1 minute).** From Loom Heron, move right toward the waterline
   spans. Check float bodies at the waterline and feet on the decks. Use
   **Workshop** and look toward the higher landings to review angled braces.
   Their ends should disappear into supporting rock/tower rather than hang
   in empty space. The new assets do not bob or move the existing collision.

**Best feedback:** a 30–60 second video with camera movement, plus one sentence
about what feels better/worse. For a still art defect, a screenshot with the
location is enough. For movement, posture transitions or parallax, video is more
useful. If capturing is inconvenient, simply report keep/change and the landmark;
your feel notes are enough to continue. No full playthrough is needed tonight.

[Pose comparison](../work/framing-idle-2026-10-30/upright-comparison.jpg) ·
[Bridges](../work/blue-depth-bridges-2026-10-30/floating-comparison.jpg) ·
[High braces](../work/blue-depth-bridges-2026-10-30/high-comparison.jpg).
The new slash-VFX look is still in its separate preview; tonight's live changes
are framing, idle posture, Blue depth and structural art. Existing T33/T20
acceptance checks remain below.

## Earlier framing review notes

Chase authorized the live 0.83 camera zoom and an upright-idle attempt. Use
`threadbound/art-framing-and-idle`, which inherits earlier corrections. Compare
the demo and Blue at their saved zoom; stand, run, stop, jump, guard, attack,
throw the grapple and wait through the idle variations. Judge narrower stance,
head/torso posture, boot contact, equipment fit and the transition into action.
[Grounded comparison and checks](../work/framing-idle-2026-10-30/README.md).
The upright pose is taller, about 14.3% at 0.83; the previous-pose 13.3% figure
below belongs to the earlier camera-only study. Pose/framing acceptance is open.

## Earlier camera/VFX study and retained retests

October 30 update: Chase moved these two questions to the front. Current branch
`threadbound/vfx-scale-and-impact-study` inherits the earlier corrections. Save
manual Godot/art edits before switching tasks; the assistant handles Git.

1. Review the [camera A/B](../work/scale-vfx-study-2026-10-30/camera-comparison.jpg)
   and [posture comparison](../work/scale-vfx-study-2026-10-30/posture-comparison.jpg).
   Current idle occupies about 16% of demo height and 14.4% of Blue height;
   the runtime-only 0.83 camera preview gives 13.3%. Judge room visibility and
   character readability separately from the broad, bent-knee stance. Choosing
   an upright pose will require measuring screen height again.
2. Watch the [combo VFX comparison](../work/scale-vfx-study-2026-10-30/combo-comparison.gif),
   then check the [gameplay-scale view](../work/scale-vfx-study-2026-10-30/vfx-gameplay-scale.jpg).
   Judge the filled gesture, brightness, thread accents and clearance. Contacts
   are illustrative, with no enemy hits, hit pause or sound in this stage.
3. Review the [existing hitbox overlay](../work/scale-vfx-study-2026-10-30/existing-hitbox-overlay.jpg).
   Current damage reach is already broader than the visible swing. Select the
   visual direction before proposing a scoped live integration or combat change.

[Measurements, limitations and next-pass file scopes](design/character_scale_and_vfx_study_2026_10_30.md).
No production camera, collision, animation or VFX replacement is made by this
review package. T33/T20 acceptance remains pending. The prior retests follow.

## Demo lighting and double jump

The current branch inherits `threadbound/fix-demo-lighting-double-jump`. Chase likes the
demo's overall feel and 2D enemies; this retest covers the two reported faults.
Save manual editor/art edits before switching tasks; the assistant handles Git.

Open `Src/Environment/World/Chamber Of The First Weave.tscn` and restart with F6
so the current scripts load. About 3–5 minutes:

1. **Character lighting.** Walk from dim ground toward the opening, central
   threads, and red/blue/yellow fixtures. The character should receive their
   color and brightness along with the scenery. Judge contrast, over-bright
   areas and transitions. Its own soul glow should not wash out the model.
2. **Second-jump motion.** Jump again early during ascent, then try a second
   jump while falling. Both should replay the normal jump motion at 1.2× speed.
   Land and jump again: ordinary jump speed should return. Give keep/change
   for the faster second jump; movement strength and AP cost are unchanged.
3. **Next environment target.** After these corrections feel right, choose one
   small existing lake stretch to finish with model/texture-derived 2D stamps
   and a manual paint pass. Compare its clarity and pacing with the demo before
   proposing any layout or gameplay change.

The underwater background and T20 appearance/feel reviews remain open below.

## October 29 background review and original replay card

October 29: use `threadbound/art-underwater-rock-background`, which includes the
current accepted checkpoints. Save any manual Godot/Krita/Blender edits before
switching scenes or tasks; the assistant handles the Git checkpoint.

1. **Review the new background (2 minutes).** F6
   `Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`.
   Swim down beside the tower and across the underwater route. The new painted
   rock wall should sit behind the player, bulbs, supports and solid terrain.
   Judge player contrast, foreground/background separation and texture seams
   while moving. Give keep/change/untested; appearance is not yet accepted.
2. **Replay the demo (15–25 minutes).** Open
   `Src/Environment/World/Chamber Of The First Weave.tscn` and press F6.
   This uses the shared current player, including its live character visual.
   Play the existing route at normal speed with the controls you normally use.
   Direct F6 is the simple replay route; it does not request deleting a save.
3. **Capture three keep moments and three friction points.** For each, note the
   room/landmark, action, feeling and what you think caused it. Look at jump and
   grapple spacing, landing/contact, attack rhythm, enemy tells, camera framing,
   route clarity and the alternation of pressure, discovery and breathing room.
   These are observations to make, not confirmed causes of the demo's feel.
4. **Compare one short lakeside stretch.** Repeat a similar movement/fight there.
   What feels different with the same character? Pick the single difference
   that matters most, then propose one bounded change and its files for approval
   where required. Preserve the demo as the reference while evaluating it.

The replay is the next review task, not authorization for combat/equipment
changes, level restructuring or a new system. T20 acceptance remains open below.

## Existing October 26 corrections — retained follow-up

About 8–10 minutes. Those fixes are inherited on the current branch; no branch
switch is needed.
Restart the comparison scene with F6:
`Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`.
Do not resume an already-running instance with older scripts/resources.

Default: painted houses, villagers and bulbs; **3D tower and enemies**; existing
live 3D player. F7 compares all categories except Tower. Separate Buildings,
Tower, Villagers, Enemies and Bulbs controls allow mixed choices. Leave Tower
and Enemies on **current 3D** for this first retest.

1. **Both houses: door travel, indoor camera, exit.** Use **Fisher house**, then
   **Workshop**. Walk past the outside, stand at Enter, press Interact. Does the
   player visibly turn/walk through the same door without the old sideways snap?
   Does the indoor framing focus the house comfortably, with the exterior quiet
   and HUD readable? Walk away, greet the resident, then find the amber door cue
   and exit. Check the camera/ground restore. Try holding Interact once; it should
   enter once. Workshop's exterior table should be gone.
   October 27 handoff correction: watch the last instant of entry; the player
   should settle directly into idle without the small jump after the animation.
   Brother's follow-up: entry looks good; now check that **exit faces toward
   you and walks out**, rather than repeating the turn-away entry motion.
2. **Visible floor contact and roofs.** Stand still, walk and crouch inside both
   houses and on tower platforms. Boots should touch the surface instead of
   floating. Jump onto the exposed slopes/ridge of each house roof. The very
   outer eaves are nested in cave terrain. Fisher loft stays disabled.
   Walk down the originally reported sloped platform in both directions: the
   player should stay grounded without repeatedly flashing a falling pose.
   Jump away and check that detachment still feels normal.
3. **Tower approach from below.** After clearing the existing breakable across
   its entrance with the swordfish, swim upward into the base. The front stone
   should hide the swimmer while passing behind it; the cutaway should reveal
   the interior as you rise inside. Check for premature disappearance, trapped
   movement or body parts drawn over solid stone. No new barrier was added.
   October 27 exterior-water correction: while swimming beside the closed
   tower, water should continue across its exterior without the old dry wedge
   along the stone sides. Enter to reveal the dry interior, stand on a platform,
   then leave; the exterior should become continuously wet again.
4. **Water and rock contact.** Use **Shore**. Reflections of posts/bridge/scenery
   should meet the waterline without a detached cyan strip. Move the camera,
   swim through the surface, and compare Day/dusk. Check player contrast and
   boots sinking slightly behind solid rock contact edges. The separate Krita
   water background is still pending; this is a reflection/layering review.
   New immersion follow-up: crossing the surface should no longer fade the
   entire lake or its reflections. Submerged body pixels should pick up a cool
   veil with subtle moving light and small rising bubbles; above-water parts
   and dry air pockets should stay clear. Surface wakes are flattened ripples.
   Reflections can still fade when their source scenery leaves the camera.
   October 27 grapple correction: throw from above the water and fall in before
   the cast finishes. Rope/needle and held-arm pose should clear immediately.
   Try base/blue/red/yellow gloves, including an attached rope. Holding Grapple
   underwater should not cast again; dry pockets and throws after exiting work.
   For the approved dash correction, hold **Up alone + Dash** underwater in both
   facings: travel should be straight up. Jump also supplies upward swim aim.
   Check Down, both diagonals, releasing/changing direction during the dash,
   and an upward dash through the surface. With no direction held, dash follows
   facing. On land, dash should retain its existing horizontal behavior.
5. **Living bulbs and nested breakable stone.** Watch an idle painted bulb for
   a few seconds: the inner water should circulate/bubble while stem and sac
   attachment stay steady. Pop/grapple, watch spent/refill, then idle again.
   Breakable rocks and their cracks should nest behind regular cave faces;
   exposed cracks should remain readable and not shine through solid cave art.
6. **3D enemies and reset.** Move near fish, Eave Runner and Loom Heron. Confirm
   the current 3D models are active and movement no longer jumps between painted
   poses. Press **F2** and confirm the same 3D enemies return. Painted enemies
   remain an optional comparison; their limited key-pose transitions are not
   being accepted as the default. Villager two-pose behavior is already accepted.
   October 27 dolphin range: it should notice you from about 1,000 px and wind
   up within 850 px, while walls and dry gaps still block aggro. Damage/speed
   and the eye-flash warning are unchanged. The approved duplicate fix is now
   delivered: the added dolphin should move/stop at its own walls independently.
   Killing the original should leave it visible; F2 should restore both dolphins
   at their saved positions with 3D art. The added heron was left unchanged.

For each issue, send the **nearest landmark + action + expected/observed result**,
with a screenshot when useful. Give **keep / change / untested** for camera focus,
door pacing, water appearance, bulb motion and tower entry depth. Do not replay
all historical test cards; the current priority is this correction set.

Implementation and per-fix commits/tests:
[October 26 report](verification/lakeside_playtest_2026_10_26.md).
[Current priority list](project_status_and_worklist.md) retains T03 reset-count
reconciliation and T04 legacy/teardown diagnostics as separate open work.

**Git checkpoint before changing topics:** save manual Godot/Krita/Blender edits,
review the diff, commit and push. Routine Git work is authorized and the assistant
will handle it when available. No acceptance item closes until its result and
checkpoint are recorded. Do not merge or publish a build just to checkpoint.
