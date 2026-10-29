# T30 — existing run cleanup and shield-hand grapple

Chase rejected T29's replacement gait and requested the previous library run,
a single default run and tighter legs. He also specified the shield hand as the
grapple origin. Appearance/feel acceptance remains pending his retest.

The separate 3D model now uses its preserved `run_1` take, formerly played with
Shift. Only the thigh, shin and foot curves on each side are adjusted. Lateral
ankle offset from the hip is reduced to 45% of the original offset, reducing
mean ankle spacing from 34.1 cm to 26.8 cm. Leg lengths, forward/vertical foot
trajectories, pelvis/torso/arm curves and the original 0.667-second cycle remain.
The original Momentum-based playback cadence is restored. Holding Shift keeps
the same run. The rejected `demo_run` clip and its procedural authoring report
are removed from the current demo.

`source/Threadborne_3D_Demo.blend` retains the untouched library action beside
the leg-cleanup action. `run_cleanup_authoring.json` records exact equality of
non-leg curves, leg-length error below 0.000001 m and forward/vertical foot
error below 0.000001 m. The original reference GLB is unchanged. No production
2D model, animation library, controller, scene or project settings were edited.

`grapple_origin()` now follows `hand.L`, the hand on the shield's left forearm.
The same origin drives clearance/range tests, needle launch and visible rope.
The existing casting and grapple library clips are retained.

Validation: 61 level/asset checks, 60 combat checks, 20 movement checks and
46 demo checks pass in source and installed projects: **187 total per copy**.
New checks cover default/Shift clip selection, removal of the rejected clip,
shield-hand tracking in four poses, needle launch and rendered rope endpoints.
GPU frames compare the untouched library take and edited take on the same
character at matched phases, from front and side.

[Animated run comparison](../../work/third-person-study-2026-10-28/run_library_comparison.gif)

Retest: run and turn without Shift, hold Shift and confirm the same animation,
then E at a wall and check that thread launches from the shield hand. The
installed demo remains `C:/Users/chase/Documents/Threadbound 3D Study`.
