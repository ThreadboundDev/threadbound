# Next hands-on test — October 26 corrections

About 8–10 minutes. Use branch `threadbound/fix-lakeside-playtest-feedback`.
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
