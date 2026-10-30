# Gameplay and visual direction review — October 30, 2026

Review baseline: `6babe095`. Chase supplied this feedback after playing the
separate 3D trial and replaying the production 2D demo. This records his
preferences and follow-up proposals, not a new implementation authorization.

## Chase's feedback

Chase personally prefers 3D games and can imagine a Prince of Persia / Dark Souls
influence for a future 3D Threadbound. He still considers the present 2D game a
good fit for its lore and intended movement/equipment play. The current 3D trial
remains parked; this conversation does not reopen conversion work.

The trial's problems were more than unfinished graphics. Combat felt slow and
unrewarding. Enemy reactions moved between two unsatisfying extremes: repeated
attacks could suppress enemies completely, or enemies armored through attacks.
Hitstun, recoil and knockback did not create convincing control or impact.

The 2D demo still feels good. Chase likes quick attacks, strong horizontal air
control, short engagements and abilities that change the flow of movement.
Traversal, combat movement, extra equipment and hot swapping remain important.
He does not want extended precision-platforming or mandatory pogo corridors to
become the main experience. Platforming can remain optional flavor. This is a
level-design preference, not authorization to remove pogo or existing routes.

Chase likes the detail and equipment potential of the current 3D character and
wants to preserve it while bringing motion/feel closer to the successful 2D
reference. He has not accepted the trial's character feel as equivalent to that
reference. Earlier sprite-animation roughness does not invalidate good controls.

The demo's outlined 2D enemies are a positive visual reference. Their clear,
almost Paper Mario-like presentation appeals to him; this comparison does not
request literal paper materials, comedy, or a change to the game's tone. He is
interested in collaborating on 2D enemy animation without relying on more Game
Lab Studio credits. This does not select a whole-roster replacement workflow.

Blue is improving but lacks the demo's depth, visual variety and cohesion. The
transition currently feels like moving between different games. Its village
could belong to many other Metroidvanias: the region needs visible Threadbound
identity even when the player is absent. Adding lighting alone has not solved it.

## Interpretation and bounded proposals

The following are recommendations for discussion. They do not change approved
combat, equipment, lore, assets or scene structures.

### Combat: preserve responsiveness and make resistance legible

Separate immediate input response, visible impact and enemy interruption. Longer
player recovery is not the only way to make a hit feel substantial. Enemy pose,
sound, brief impact pause and a controlled displacement can establish contact
while the player retains useful movement.

A useful future target is a basic opponent that reacts reliably to ordinary
strikes with little enough displacement to keep the next strike reachable.
Any protected attack window should be specific and visibly telegraphed, with a
clear opportunity to reposition or punish recovery. Heavy enemies may resist
interruption while still visibly taking a hit. Avoid an invisible universal
armor timer or a fixed number of hits after which every enemy ignores attacks.

Assess pressure through spacing, other opponents and readable actions before
assuming every small enemy must escape every combo. Do not import the trial's
stance/armor implementation into 2D on the strength of its automated checks.

Judge a future small encounter by whether Chase can enter, chain a few hits,
move out and re-enter naturally; whether the next strike stays in reach; and
whether an enemy's resistance is understandable at normal speed. No numerical
timing changes are selected here. The existing
[combat foundation](../gameplay/combat_foundation.md) already distinguishes
move-owned feedback and target-weight responses.

### Level design: movement freedom with forgiving travel

For a later reviewed room, propose a main route built from comfortable landings,
exploration and encounters with room to reposition. Reserve precision chains
and extended pogo for optional routes or expression. A missed optional move
should preferably recover to useful space rather than force repeated resets.
This supports mastery without making exact traversal execution the admission
price for the story. It does not add progression gating or revise existing
regional unlock decisions.

### Character and equipment: prove one visual swap

Keep the detailed live 3D character within the 2D game. A shared skeleton can
support differently shaped garments, but a texture swap alone cannot create a
new armor silhouette. Flexible clothing needs fitted meshes and skin weights;
rigid pieces can attach to appropriate bones. Both need motion checks for
clipping and clear silhouettes at the gameplay camera.

Recommend a later isolated comparison of the existing outfit with one alternate
equipment piece through run, jump, attack and grapple. Establish visible fit
before investing in many sets or expanding the equipment system. No model or
rig compatibility audit was performed in this documentation task.

### Enemies: one complete animation sample before a roster

Use a current demo enemy as the style reference and an existing Blue enemy as
the candidate; choose the specific candidate in the later scope. First compare
silhouette, contour weight, palette and scale. Then author one complete action:
anticipation, contact and recovery, plus a hurt reaction. Keep feet/body anchors,
weapon reach and frame scale consistent. Existing attack timing should guide
the animation rather than stretching combat to accommodate an attractive clip.

Possible workflows are layered 2D cutout animation with selected drawn poses,
or rendering an existing rigged model into sprites and cleaning the contours.
Both avoid dependence on new Game Lab Studio generations. Generated stills may
help with design, but independent generated frames do not guarantee consistent
anatomy, registration or timing. Some hands-on pose/drawing cleanup remains
necessary; this is not a promise of finished animation from a single prompt.

The existing [painted comparison](../art/lakeside_painted_2d_comparison.md) already
showed why a few key poses are insufficient: painted enemy transitions jittered
and enemies returned to the 3D default. A new sample must pass normal-speed
motion review, not just a still-image comparison. A live 3D player and 2D enemies
are a plausible mixed presentation if contour, values, contact and scale agree.

### Blue: express the established world through construction

Use the existing [Blue direction](blue_biome_direction.md): **a weaving machine
mistaken for a peaceful lakeside village**, with Balance forced into stagnation.
The [environment guide](../art/environment_art_style.md) already calls for shared
contours, grouped values and restrained background detail. Preserve Blue's open,
lush lakeside character rather than copying the Chamber's cave palette.

For one future composition study, consider visible load-bearing cord bindings,
interlaced structural members and loom-like frames incorporated into useful
docks or workshops. Give woven construction a structural purpose rather than
adding decorative thread symbols everywhere. These are visual proposals, not
new claims about the settlement's origins or magical machinery.

Pair inhabited craft spaces with established evidence of stagnation: unused
water wheels, boats sitting idle, dry channels and the dry waterfall in the
distance. Keep existing faction distinctions: woven guardians have cord limbs,
ceramic faces and binding marks; villagers remain human. Native wildlife need
not all become woven constructs. Exact makers remain unspecified.

Compose near framing, a clearly readable playable plane, occupied middle depth
and pale lake/distant architecture. Match the demo's contour and value hierarchy
while giving Blue its own materials and atmosphere. Review the same view with
the character hidden: the environment should still communicate Threadbound.

## Suggested next discussion and checkpoint

The current work-list priority remains T33's lighting/jump retest, followed by
the outstanding T20 review. Positive overall demo feedback does not accept
those fixes or the delivered background.

After that review, recommend choosing **one** follow-up: a Blue composition
study, a complete 2D enemy action sample, or one equipment-fit comparison. The
composition study most directly tests the missing regional identity; do not
start all three together. Each needs its own concrete scope and applicable
approval before protected edits.

This task changes documentation only. Validation: local reference review,
relative-link checks and staged whitespace/diff review. No gameplay tests or
new art acceptance are claimed. Checkpoint subject:
`docs: record gameplay and visual direction review`.
