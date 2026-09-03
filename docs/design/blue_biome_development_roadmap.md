# Blue Biome Development Roadmap

This document is the working source of truth for developing the playable Blue
Biome. It organizes the work without locking unresolved mechanics, enemy
designs, or final art direction prematurely.

## Development Goal

Build an interactive, readable lakeside region whose encounters and traversal
express movement, water, and disrupted balance. The level should offer more
than conventional platform jumping while preserving the approved macro route,
existing player-expression systems, and collision-first environment pipeline.

## Workstream Order

### 1. Traversal and Room Design

Return to the room greyboxes before producing final environment art.

- Playtest the new bumper blocks in representative Blue room layouts.
- Explore bumper chains, optional routes, recovery paths, combat placement,
  and interactions near water.
- Define how water changes bumper movement without committing to a full
  implementation before the prototype proves fun.
- Rework individual room geometry only after its traversal purpose is clear.
- Validate normal routes and expressive routes at player scale.

The first focused design question is: **what does entering, leaving, or moving
through water do to a bumper launch, and what does the player control during
that transition?**

Before changing bumper or water code, document the proposed behavior, affected
systems, files, edge cases, and verification plan for approval.

### 2. Blue Combat and Enemy Needs

Use existing enemies as temporary encounter actors while traversal is being
validated. Their purpose is to reveal what the rooms need, not to imply that
they are final Blue inhabitants.

- Test existing enemy archetypes against bumper and water layouts.
- Record missing combat roles rather than beginning with visual generation.
- Select one smallest useful Blue enemy or adaptation once the gameplay gap is
  understood.
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

`threadbound/level-blue-biome-development` is the integration branch for the
Blue Biome work. Focused implementation should use short-lived branches from
the latest integration branch, following the repository naming rules.

Examples:

- `threadbound/feature-blue-water-bumper-interaction`
- `threadbound/level-blue-bumper-room-pass`
- `threadbound/feature-blue-enemy-prototype`
- `threadbound/asset-blue-biome-tileset`
- `threadbound/art-blue-biome-parallax`

Each pull request should contain one reviewable outcome and include what
changed, why it changed, and how it was tested. Merge or rebase the latest Blue
integration work before starting a dependent branch. Do not mix final art,
enemy behavior, and traversal-system changes into one pull request.

## Milestones

### Milestone A: Traversal Proof

- One representative room demonstrates useful bumper play.
- Water/bumper behavior is defined and verified.
- The room has a clear baseline route, expressive route, and safe recovery.
- Existing enemies can be placed without obscuring traversal readability.

### Milestone B: Combat Proof

- Representative Blue encounters have documented gameplay needs.
- One Blue-specific enemy role is selected and prototyped.
- Encounters remain readable around water and bumper movement.

### Milestone C: Art Proof

- The terrain tileset works without obvious seams at room scale.
- One representative room has approved gameplay, background, and foreground
  layers.
- Parallax depth, palette, and gameplay-contact edges match the Blue art rules.

### Milestone D: Region Production

- Proven traversal patterns are distributed without making every room alike.
- Enemy and hazard combinations reinforce each room's purpose.
- Reusable art is extended across the macro route with room-specific landmarks.

## Immediate Next Session

1. Open a representative Blue greybox room.
2. Place and tune bumpers without changing water code.
3. Test launch direction, cadence, recovery, and optional-route potential.
4. Sketch two or three candidate water interactions from observed play.
5. Choose the smallest prototype and prepare its approval proposal.

## Scope Guardrails

- Preserve the approved Blue macro geography and established project direction.
- Keep gameplay collision authoritative and separate from finished art.
- Do not finalize art over unstable room geometry.
- Do not introduce progression gating, classes, permanent builds, or unrelated
  combat/equipment changes.
- Treat lore, major system redesigns, and asset replacements as approval-gated.
- Update this roadmap when a milestone, dependency, or decision materially
  changes.
