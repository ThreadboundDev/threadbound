# Lakeside villagers and indoor enemy concepts

October 19, 2026. Concepts for review before modeling or gameplay implementation.
These are proposed designs and working names, with no new canon or faction lore.

## Villagers

![Two villager concepts](Villagers.png)

Both belong to the existing feudal Japanese fishing village: weathered indigo
cloth, flax wraps, warm brown work aprons, rope and simple craft tools. Adult
proportions, readable silhouettes and detailed painted materials should match
the existing player and village buildings.

| Design | Where it fits | Work idle | Interaction |
| --- | --- | --- | --- |
| A — Net Mender | Fisher house or net workshop | Small shuttle movements, checking a knot, breathing and an occasional glance up | Pauses the work, turns toward the player, settles into a relaxed talk idle |
| B — Boatwright | Workshop or boat slip | Inspects a timber offcut, adjusts a hand plane or shifts weight at a bench | Lowers the tool safely, turns toward the player, gives a small acknowledging nod |

Start with two models on a compatible humanoid rig. Shared breathing, look,
turn and talk loops can support both; their hand-work loops and props give each
a separate identity. A standing work loop is the simplest initial animation;
the seated net-mending study is an optional variation.

Interaction idea: normal work idle → pause work → smooth turn toward the
player's position → talk idle → turn back and resume. Keep small head/shoulder
motion during talking. Props remain attached to the appropriate hands or work
surface during transitions. Small timing offsets between villagers keep a room
from moving in unison. Dialogue content is a separate future decision.

## Indoor wall hunters

![Three indoor enemy concepts](Indoor_Enemies.png)

The movement reference is the wall-leaping pressure the user described. The
characters, tools and materials are original village-themed explorations.
All three share an indoor wall-jump premise, with different silhouettes and
projectile roles. Their concepts can be mixed before selecting a model.

| Design | Jump attack | Projectile | Intended feel |
| --- | --- | --- | --- |
| A — Eave Runner | Braces on a wall, locks aim, then commits to a fast diagonal slash and a low recovery landing | One iron throwing spike with a short pale-blue cloth tag | Nimble, direct and easy to read; my pick for the first prototype |
| B — Thread Skimmer | Rebounds to a beam or opposite wall, pauses briefly, then makes a longer drifting cut across the room | A shallow three-needle fan, with short blue thread trails | More aerial pressure and spacing; lighter cloth silhouette |
| C — Tile Fang | A stronger knee-tucked wall launch into a shorter, heavy descending chop | A flat triangular roof-ceramic shard | More grounded weight, larger attack tell and a longer landing opening |

### Suggested first behavior: Eave Runner

1. Reposition to a reachable real wall or beam with room to launch and land.
2. Brace visibly: compressed legs, planted hand and a small blue weapon glint.
3. Lock the target position before launching so the player can bait the line.
4. Commit to a diagonal jump slash with a short, readable active window.
5. Land low and recover long enough to give the player an attack opening.
6. When space allows, choose a separate spike-throw attack with its own hand
   windup, then reposition. Start by alternating the throw and jump decisions.

Let wall positions shape the encounter: a tight room produces short rebounds;
a taller chamber permits longer jumps. Keep perches, launch paths and landings
inside usable room geometry. A small repeat limit before returning to the floor
would keep the fight moving toward the player instead of staying on a wall.

Existing combat conventions should supply the eventual hurt response, health
bar, hit effects, death and reset behavior. Any jump, projectile, block/parry or
grapple interactions should be integrated and tested after the design choice.
The concepts here do not change the current combat system.

### Proposed animation sets for later approval

- Villagers: work idle per profession, breathe, look, turn, talk idle, return.
- First enemy: idle, ground reposition, wall attach/perch, launch tell, jump
  slash, land/recover, projectile windup/release, hurt and death.

Strong cloth folds, repaired fabric, worn wood and ceramic texture carry the
detail. Small fabric tails and practical accessories should keep the eventual
geometry and rig manageable. Fit NPC scale to the existing player and doorways
when the actual models are built.

## Review choices

My starting combination is **both villagers + Eave Runner**. Tile Fang's ceramic
mask or shoulder detail could also be adapted to A if that village-material
connection is preferred. Pick the looks and attack flavor before making rigs.

## Files and generation

- `Villagers.png`: two villager designs, back views, material details and idle/turn studies.
- `Indoor_Enemies.png`: three enemy designs, wall-perch poses, projectile details
  and a four-pose wall-attack study for A.
- `generation-prompts.json`: exact prompts, reference paths and built-in tool mode.
- `provenance.json`: output hashes, dimensions and reference-image records.

Generated with the built-in image generation tool using the current house
review and in-game player view as visual references. These images are concept
sheets; the pose studies are illustrative rather than animation frames or 3D
model files. No scene, character asset or gameplay script was changed for this
concept pass.
