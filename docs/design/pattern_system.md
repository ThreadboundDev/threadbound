# Pattern System Design (Accessory Slot)

## Status

Patterns are a long-term design proposal and a potential core pillar of Threadbound alongside Equipment and Identity.

This document preserves the concept for future evaluation. Patterns are not currently confirmed for the demo, and the examples below do not establish final balance.

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
- combining Red and Blue items;
- maintaining a balanced set of alignments; and
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
- how players inspect active and inactive Pattern effects; and
- what visual-production method can support embroidery across all compatible equipment.

## Existing Philosophy Conflict

The current equipment design states that there are no hybrid bonuses and that power comes from execution rather than equipment combinations. Patterns intentionally introduce combination-based bonuses, including hybrid bonuses.

This conflict is unresolved. This proposal does not supersede the current equipment rules in `docs/gameplay/equipment_slots.md`. Adopting Patterns will require a deliberate revision of the equipment philosophy and an evaluation of how the system affects player expression, mid-action swapping, balance, and progression.
