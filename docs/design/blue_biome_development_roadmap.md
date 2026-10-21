# Blue Biome Development Roadmap

This document holds Blue Biome design direction and longer-term workstreams.
Use the [current work list](../project_status_and_worklist.md) for task order,
status, acceptance and commit checkpoints. It supersedes the dated priorities
below without approving unresolved mechanics, enemies or art changes.

October 21, 2026: the saved baseline is `16b3bd3c` on
`threadbound/chore-october-development-checkpoint`. Resolve the current lakeside
floor/NPC and verification issues before broader room production. See the
[checkpoint](../checkpoint_2026_10_21.md) for passing and failing checks.

## Current checkpoint — October 5, 2026

Reviewed against `5f42ee0b` on `water-cleanup`. Water Bulb interactions, water traversal, authored air attacks, the water combo/specials, Tide Duelist, Reedhook and Bellstriker are implemented prototypes. Lake, village, painted terrain, pavilion V2 and deck-module experiments exist. This documentation review did not rerun verification or accept them by playtest.

October 10 follow-up: current local work now includes swordfish-fracturable greybox walls and art attached to each bulb. [Six focused fish/bulb/room-authoring checks passed](../verification/focused_checks_2026_10_10.md), including those additions. That updates the October 5 prototype/verification status below; barrier teaching, live-editor placement, visuals and feel still need review.

The next milestone is one accepted representative Blue room: useful baseline and optional routes, recoverable mistakes, readable combat, coherent player/world scale and an observed performance baseline. Broader region production follows that proof. Swordfish friendly damage, fracture barriers, multi-dash elite and the tortoise encounter remain future ecosystem prototypes rather than completed content.

Use [Project status and work list](../project_status_and_worklist.md) for priorities and [Next hands-on test session](../next_test_session.md) for the ready-to-play handoff. Development has two availability queues:

- **Away:** discuss systems and intended feel, audit source, investigate errors, run relevant automated checks, prepare file-specific proposals and make authorized focused changes. These tasks can progress while Chase cannot physically play.
- **At-computer:** judge controls, tells/contact, route usefulness, scale, art integration and the exported candidate. Automation does not close those decisions.

Availability changes which ready task we pick; it does not change the existing approval rules or mean all work must stop for a playtest.

## Development Goal

Build an interactive, readable lakeside region whose encounters and traversal
express movement, water, and disrupted balance. The level should offer more
than conventional platform jumping while preserving the approved macro route,
existing player-expression systems, and collision-first environment pipeline.

## Workstream Order

### 1. Traversal and Room Design

Return to the room greyboxes before producing final environment art.

- Playtest the existing Water Bulbs in representative Blue room layouts.
- Explore bumper chains, optional routes, recovery paths, combat placement,
  and interactions near water.
- Review the implemented melee recoil, boosted dash and remote clear around
  water. Define changes from observed play rather than treating the initial
  interaction implementation as still missing.
- Rework individual room geometry only after its traversal purpose is clear.
- Validate normal routes and expressive routes at player scale.

The current focused design question is: **do entering/leaving water and bulb
launches preserve useful control, readable direction and safe recovery in a
representative room?** Intended behavior and edge cases can be discussed while
away; the answer about feel still needs hands-on review.

#### Exploratory Bumper Art Concept: Water-Pod Flower

The current visual idea for a finished Blue bumper is a large, single-stemmed
flower with a hanging bell or pod silhouette. Its pod is translucent and holds
visible water, potentially rendered with the existing Blue water texture or
material. Striking the pod makes it pop, releases a splash, and propels the
player. The pod later reforms or refills when the bumper regenerates.

This is a promising direction because it gives the launch a readable source of
stored pressure, connects the traversal object directly to Blue's water
identity, and supports a clear ready-to-use versus spent silhouette. It remains
an exploratory concept until bumper playtests establish the required size,
orientation, timing, regeneration, and readability. The visual design should
avoid resembling an ordinary enemy or safe background flower, especially when
placed near hazards and dense vegetation.

#### Traversal Reference: Ori's Burrow and Sand Balls

Reference: [Making Ori and The Will of the Wisps' Best Level](https://www.youtube.com/watch?v=gIdHTL18kTU&t=415s),
especially the discussion of burrow, hanging sand balls, backtracking, and
difficulty layering from roughly 2:37 through 9:24.

The intended lesson for Blue is broader than copying a launch object:

- Treat water as an active traversal medium, analogous to how sand supports
  movement throughout the referenced level rather than acting as scenery.
- Let the player approach compact water-filled bulbs from useful angles and
  leave with a decisive, readable trajectory.
- Preserve directional continuity and player agency. The reference sand balls
  can be entered from any side and send the player straight through; Blue
  should prototype that behavior alongside the current opposite-attack recoil
  before choosing the final input model.
- Use water volumes and bulbs together. A bulb can bridge gaps between water,
  redirect a route, extend height or distance, create an optional mastery path,
  or provide a return route through a space.
- Combine the mechanic with established elements instead of exhausting every
  bulb variation in isolation. Bumpers, hazards, enemies, disappearing or
  changing routes, and water geometry should produce distinct situations.
- Design for backtracking. A room-changing traversal element must leave a
  legible return path or regenerate so the player is never stranded.
- Layer difficulty gradually: first enter or strike a safe bulb, then aim a
  launch, then chain bulbs, and only later add hazards, enemies, or demanding
  route choices.

The design target is the reference's feeling of flow, control, and mechanical
reuse—not its desert presentation, exact controls, or art assets. Blue's water
pods, still-water theme, player attacks, and existing movement kit should give
the system its own identity.

The greybox prototype consolidates these actions into one non-solid Water Bulb:

- **Attack:** pop and recoil opposite the strike direction.
- **Dash:** pop on contact, continue forward at 1.2 times incoming velocity, and gain upward lift (default 1000 px/s).
- **Grapple or ranged damage:** pop remotely without changing player momentum, clearing the
  bulb's contact response for passage.
- **Ordinary contact or spawn overlap:** gently eject the player through the
  nearest edge without consuming the bulb.

The bulb cannot be stood on or used as a ledge. Its action-dependent response
keeps one recognizable environmental object while preserving distinct player
choices.

Before changing bumper or water code, document the proposed behavior, affected
systems, files, edge cases, and verification plan for approval.

### 2. Blue Combat and Enemy Needs

Tide Duelist, Reedhook and Bellstriker are now reusable first-pass encounter
actors. Review their existing roles alongside traversal before expanding the
roster or treating the prototype art as final.

- Test existing enemy archetypes against bumper and water layouts.
- Record missing combat roles rather than beginning with visual generation.
- Review fish commitment/recovery, Reedhook reach/ledges and Bellstriker boxing
  and amphibious pursuit. Record keep/change decisions for each.
- Select the smallest useful ecosystem prototype after the current encounter
  decisions; swordfish friendly damage and one fracture barrier precede the
  tortoise encounter.
- Prototype behavior and silhouette readability before commissioning or
  generating final art.
- Keep new enemy mechanics compatible with established combat foundations.

This allows enemy design to progress through mechanics, placeholder art, and
small reusable visual requirements even when image-generation credits are
limited.

### 3. Environment Art Production

Begin final room art only after representative traversal and combat spaces are
stable.

- Finalize or rebuild the collision-free Blue terrain tileset.
- Verify tile seams, repetition, contact-edge readability, and room-scale use.
- Produce parallax assets by depth role: sky, far geography, distant village,
  midground framing, and foreground silhouettes.
- Keep buildings, vegetation, platforms, hazards, and water as separate
  reusable layers where the existing pipeline calls for them.
- Validate each art pass in-game at native scale before expanding it across the
  region.

The existing Krita 3x3 terrain kit and runtime 512-pixel TileMap atlas are the
starting point. They are prototypes to evaluate, not an obligation to preserve
visible seams, repetition, or unsuitable rendering.

## Branch and Pull Request Strategy

`threadbound/level-blue-biome-development` was the earlier Blue integration
branch; the September checkpoint preserved that work and the October 5 review
is on `water-cleanup`. Verify the intended current base before starting a
dependent branch rather than assuming the historical integration branch is
current. Focused new branches follow `threadbound/<type>-<description>`.

Examples:

- `threadbound/feature-blue-water-bumper-interaction`
- `threadbound/level-blue-bumper-room-pass`
- `threadbound/feature-blue-enemy-prototype`
- `threadbound/asset-blue-biome-tileset`
- `threadbound/art-blue-biome-parallax`

Each pull request should contain one reviewable outcome and include what
changed, why it changed, and how it was tested. Merge or rebase the latest Blue
integration work as needed before starting a dependent branch, using the
verified intended base. Do not mix final art,
enemy behavior, and traversal-system changes into one pull request.

## Milestones

### Milestone A: Traversal Proof

Status: interaction prototypes exist; representative-route usefulness and feel await hands-on acceptance.

- One representative room demonstrates useful bumper play.
- Water/bumper behavior is defined and verified.
- The room has a clear baseline route, expressive route, and safe recovery.
- Existing enemies can be placed without obscuring traversal readability.

### Milestone B: Combat Proof

Status: three enemy roles and water combat are implemented prototypes; encounter acceptance and ecosystem interactions remain work.

- Representative Blue encounters have documented gameplay needs.
- One Blue-specific enemy role is selected and prototyped.
- Encounters remain readable around water and bumper movement.

### Milestone C: Art Proof

Status: several art/rendering studies exist; one coherent room, scale, contact edges and performance await review.

- The terrain tileset works without obvious seams at room scale.
- One representative room has approved gameplay, background, and foreground
  layers.
- Parallax depth, palette, and gameplay-contact edges match the Blue art rules.

### Milestone D: Region Production

Status: macro-room prototypes exist; expansion of accepted encounters/art depends on representative-room proof.

- Proven traversal patterns are distributed without making every room alike.
- Enemy and hazard combinations reinforce each room's purpose.
- Reusable art is extended across the macro route with room-specific landmarks.

## Immediate next sessions

**Away:** the bounded fish/bulb/room-authoring pass is now complete (October 10).
Discuss intended fish/Bellstriker/water-combat feel, and prepare
small ready items or investigate reproducible problems. Keep manual retests
written into the handoff. Room and ecosystem proposals can progress in
conversation without prematurely accepting their gameplay.

**At-computer:** start with the prepared H1 lake movement/attack session, about
30 minutes. H2 reviews enemy encounters next; H3 covers bulb routes and scale;
H4 covers pavilion/deck presentation/performance. Use separate sessions instead
of asking Chase to complete the entire backlog at once. Shared-system/demo and
export regression follows before accepting a playable candidate.

## Scope Guardrails

- Preserve the approved Blue macro geography and established project direction.
- Keep gameplay collision authoritative and separate from finished art.
- Do not finalize art over unstable room geometry.
- Do not introduce progression gating, classes, permanent builds, or unrelated
  combat/equipment changes.
- Treat lore, major system redesigns, and asset replacements as approval-gated.
- Update this roadmap when a milestone, dependency, or decision materially
  changes.

## Bulb Choice Room (September 19)

The approved action-based bulb replaces the retired speed threshold. Open
`Prototypes/Rooms/blue_bulb_choice_room.tscn` with F6 for the isolated proof.
It provides a safe lower route, a dash gap, a downward-strike perch, an optional
upper chain, and a remote-clear choice. The existing macro route remains intact.
See `docs/design/blue_bulb_choice_room.md` for controls, checks, and tuning.
