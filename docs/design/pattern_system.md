# Pattern System Design (Accessory Slot)

## Status

Patterns are a long-term core pillar of Threadbound alongside Equipment and Identity.

Patterns are the equipment-combination bonus framework for single-Thread sets, hybrid sets, Neutral/Base equipment, balanced sets, and other mixed arrangements. The system is not currently confirmed for the demo, and the examples below do not establish final balance.

## Overview

A Pattern occupies one dedicated accessory slot. The player may equip only one Pattern at a time.

Patterns are not traditional RPG accessories that provide unconditional, flat stat bonuses. A Pattern evaluates the Thread alignments of the player's currently equipped armor and grants conditional benefits based on that combination.

In the world, a Pattern represents the specific method a Weaver uses to interlace the primordial Threads into their equipment. The system is simultaneously:

- a build-shaping gameplay mechanic;
- a visual customization layer; and
- an expression of Threadbound's worldbuilding.

## Three Independent Customization Systems

Player customization is divided into three independent systems. Keeping these systems separate allows them to combine without requiring unique content for every possible configuration.

### Identity

Identity controls the player's overall color palette. It represents the player's philosophical alignment with the primordial Threads.

Identity does not determine equipment or statistics.

### Equipment

Equipment determines what the player is physically wearing. Helmets, robes, gloves, boots, and other pieces change the character's silhouette, visible armor pieces, and gameplay behavior or statistics.

Each relevant equipment piece has one Thread alignment:

- Red
- Blue
- Yellow
- Neutral/Base

Patterns use these alignments when evaluating the current loadout.

### Pattern

A Pattern determines how the equipped Threads are woven together. It evaluates the equipped gear and grants conditional bonuses based on its combination of Thread alignments.

Potential conditions include:

- wearing multiple Red items;
- wearing multiple Blue items;
- wearing multiple Yellow items;
- combining Red and Blue items;
- combining any other selection of Thread alignments;
- using Neutral/Base equipment;
- using only Neutral/Base equipment;
- including every Thread color;
- maintaining a balanced set of alignments;
- using intentionally uneven or unconventional arrangements; and
- using future equipment-set combinations.

A Pattern does not change equipment pieces, silhouettes, or Identity colors. It changes build logic and supplies a decorative embroidery overlay.

## Example Patterns

These examples demonstrate the intended logic only. Their names, thresholds, values, and effects are placeholders for later balance work.

### Crimson Weave

If the player wears at least three Red equipment pieces:

- increased Power;
- increased skill damage.

### Flowing Weave

If the player wears at least two Blue equipment pieces:

- reduced grapple cooldown;
- increased movement speed.

### Scholar's Weave

If the player wears at least two Yellow equipment pieces:

- reduced cooldowns;
- improved resource efficiency.

### Trinity Weave

If the player wears at least one Red, one Blue, and one Yellow equipment piece:

- a small bonus to all statistics.

The important principle is that Patterns reward equipment combinations rather than individual pieces.

## Pattern Breadth and Rarity

The Pattern catalog should support the full range of intentional equipment arrangements rather than favoring only complete single-color sets. There may be a Pattern for a focused set, a hybrid, an all-color arrangement, a Neutral/Base build, or another meaningful combination.

Patterns may range from common to rare. Rarity can help distinguish straightforward, broadly useful Patterns from unusual or highly specialized ones, but rarity does not automatically mean greater numerical power. A rarer Pattern may instead require a more specific combination or enable a more distinctive style of play.

Final rarity tiers, acquisition methods, distribution, and availability are undecided. Patterns must not become progression gates.

## Gameplay Specialization

Equipping a Pattern should help the player shape a loadout into something special and distinct. Pattern effects may emphasize a particular rhythm, mechanic, tactical preference, or interaction among equipped pieces.

Patterns should:

- give purposeful identities to single-color, hybrid, balanced, Neutral/Base, and unconventional loadouts;
- reward deliberate equipment choices without prescribing one correct build;
- alter how a player approaches play rather than only increasing general power; and
- preserve execution, experimentation, and real-time equipment expression as central sources of mastery.

## Visual System

Patterns are visible on the player. Each Pattern contains an embroidered motif applied to designated cloth regions of the currently equipped armor.

Possible motifs include:

- crimson knotwork;
- blue flowing embroidery;
- golden geometric stitching; and
- trinity interwoven threadwork.

Patterns do not change armor shapes or Identity colors. Their visual contribution is limited to decorative embroidery that appears sewn directly into the player's clothing.

## Art Direction

Pattern artwork should read as physical embroidery rather than a magical effect. It should primarily appear on:

- cloak borders;
- hood trim;
- tunic hems;
- sleeve cuffs;
- sashes;
- scarves; and
- other restrained cloth accents.

Patterning should not cover the entire outfit. Embroidery should enhance the clothing while preserving the silhouette, Thread-color readability, and clarity of gameplay actions.

## Technical Direction

The character should eventually be composed from independent visual layers:

| Layer | Responsibility |
| --- | --- |
| Identity | Palette and color |
| Equipment | Sprite pieces and silhouette |
| Pattern | Embroidery overlay |

New equipment, Identities, and Patterns should combine without requiring unique artwork for each permutation. This separation is intended to keep content production scalable while increasing visual variety.

This is technical direction, not an approved implementation architecture. The rendering approach, authoring workflow, compatibility rules, and asset requirements require validation before production work begins.

## Design Goals

Patterns should:

- encourage interesting equipment combinations;
- create meaningful build diversity;
- support single-color, hybrid, balanced, Neutral/Base, and unconventional loadouts;
- help players create specialized and distinctive playstyles;
- provide long-term collectible progression;
- reinforce Threadbound's weaving theme;
- visually communicate the player's build; and
- expand customization without multiplying the art workload.

## Terminology

The word **Pattern** intentionally carries three connected meanings:

1. A gameplay accessory that modifies a build.
2. A visible embroidery pattern on the player's clothing.
3. The Weaver's chosen method of weaving the primordial Threads together.

This shared terminology is intentional and should remain consistent if the system moves forward.

## Open Design Questions

Before Patterns become an active system, the team must decide:

- whether Patterns belong in the demo or only in the long-term game;
- how conditional bonuses coexist with real-time equipment swapping;
- whether Pattern progression can remain expressive without becoming progression gating;
- which equipment slots contribute Thread alignments;
- whether Neutral/Base pieces contribute to any conditions;
- how Pattern rarity and acquisition should work;
- how players inspect active and inactive Pattern effects; and
- what visual-production method can support embroidery across all compatible equipment.

## Relationship to Equipment Philosophy

Patterns supersede the previous prohibition against hybrid bonuses. All bonuses based on equipment sets, hybrid combinations, Neutral/Base equipment, balanced arrangements, and other alignment combinations belong to the Pattern system.

Patterns complement rather than replace execution-based mastery. Equipment still determines the player's available tools, and player skill still determines how effectively those tools are used. A Pattern gives the chosen combination a distinct gameplay emphasis without making that combination mandatory for progression.
