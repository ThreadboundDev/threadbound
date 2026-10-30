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
