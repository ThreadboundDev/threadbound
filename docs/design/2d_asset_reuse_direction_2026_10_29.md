# 2D direction and asset reuse — October 29

## Chase's decision

The current 3D trial does not look/play well enough, and the development rate and
required 3D expertise do not justify a conversion. Keep Threadbound in 2D and park
the current full-3D effort. This is a decision about the present experiment, not
a permanent prohibition on future research. Preserve the separate trial and its
sources; the production 2D game was never converted and needs no rollback.

Chase sees value in using existing free models, materials, rigs and animations,
including reskinning suitable models and learning from existing motion. This
retains the established non-chibi character identity and woven art direction;
it does not approve every downloaded model for production.

### October 30 demo replay

Chase replayed the original demo with the current character and likes the game
feel and existing 2D enemy appearance. Keep that demo as the reference for the
next 2D work. He prefers its 2D presentation to the current 3D trial and notes
that a convincing 3D version would require substantial animation work; he also
recognizes the extra manual work already invested in 2D.

The intended environment workflow is to use suitable free 3D models and textures
as sources for clean 2D art, then compose and draw levels with the established
stamp workflow. Match camera angle, scale, lighting, palette and edge treatment
before adding stamps; paint over joins and repeated details for a coherent level.
Use the existing verified asset library first. This records the production
direction, not approval to replace existing assets or every candidate's license.
No new download, art replacement or level rebuild is part of this checkpoint.

Immediate replay findings: demo lights do not reach the live character, and the
double jump should replay the existing jump animation, slightly faster. These
are tracked as T33 on the current priority list; appearance/timing retest remains
separate from the positive review of the demo's overall feel and enemies.

## What the experiment taught us

- Features and automated checks did not establish convincing game feel. The
  trial expanded before the core movement/combat passed Chase's visual review.
- A full 3D switch adds camera, environment staging, motion/grip correction and
  collision work. Asset availability alone did not remove those costs.
- Downloaded assets remain useful building blocks. Reuse needs selection,
  compatible proportions, camera-aware timing, consistent lighting/materials
  and in-game review. A new texture alone does not establish a Threadbound fit.
- Keep production 2D priorities and acceptance separate from experimental work.
  The trial's combat values and implementation are not approved 2D replacements.

## Recommended reuse workflow — proposal, not implementation

1. Identify a specific weakness in the existing 2D game before searching the
   library: one attack, work loop, prop, surface or sound.
2. Use the verified CC0 collection first and retain source/license provenance.
   Keep separately licensed exceptions separate under the already documented
   handling rules. No new license exception is decided here.
3. Treat 3D models as art-production sources when helpful. A compatible rig can
   donate animation; a model can receive woven materials and be rendered into
   sprites at the established game angle, then receive art cleanup. Match scale,
   silhouette, lighting and contact points to the existing scene.
4. Use animation libraries as motion/reference donors. Select useful anticipation,
   contact and recovery, correct retargeting/grips where needed, and judge the
   result from the real 2D camera. Do not replace approved motion simply because
   a library contains an alternative.
5. Compare one candidate against the current version inside the existing 2D
   scene. Expand the workflow only after Chase accepts the result. A single
   weak enemy attack is a suitable first motion audition after current-priority
   review; it is not a request to replace a complete enemy roster.

Audio is another practical reuse path: audition the existing sound shortlist in
context, especially contact, footsteps and environmental cues. Carry over lessons
about readable windups, recovery and impact feedback through small 2D tests;
do not copy unaccepted prototype systems or tuning wholesale.

## Checkpoint and scope

3D delivery baseline: `d1be9bbe` on `threadbound/feature-polished-3d-demo`.
This follow-up records Chase's review and direction. Only documentation changes;
no runtime/art changes, deletions, merges, new production task or release.
Current production priority remains T20 in the single current work list.
