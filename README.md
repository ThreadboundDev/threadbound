# Threadbound

![Threadbound Banner](docs/art/concept_art/banner.png)

Threadbound is a painterly 2D action metroidvania built in Godot.

The game is about movement, identity, and choice: the player weaves traversal, equipment, and eventually combat together in real time while deciding what kind of being the Threadborne becomes.

## License Notice

This project is currently All Rights Reserved. You may view the code and content, but you may not reuse, redistribute, or create derivative works without explicit permission.

## Current Focus

- Base player movement feel
- Base grapple polish
- Base equipment kit
- Animation and equipment sync
- Documentation and project organization

Combat, enemies, and expanded gear sets are planned, but the current priority is making the base kit clean, responsive, and durable.

## Core Pillars

- Flow-state traversal
- Real-time equipment weaving
- Choice as identity
- No hard progression gates from optional gear
- A world that reacts to what the player becomes

## Narrative Canon

The current cosmology is stable. Before making lore, dialogue, quest, or worldbuilding decisions, start here:

- [Narrative Canon](docs/narrative/CANON.md)
- [Cosmology & Origins](docs/narrative/cosmology/cosmology_and_origins_revised.md)
- [Cosmology Timeline](docs/narrative/story/threadbound_cosmology_timeline.md)
- [Five Answers to Freedom](docs/narrative/story/five_answers_to_freedom.md)
- [Narrative Voice & Lore Delivery](docs/narrative/narrative_voice_and_lore_delivery.md)

Key guardrails:

- Eryndor is the living world-consciousness and primary narrator.
- Thought is the First Weaver.
- The Threads were originally unified within Eryndor and were never meant to be possessed.
- The Monarch, Hermit, and Sage were once the King, Monk, and Scholar.
- The Weaver is not the creator of the world and did not shatter the Loom.
- The Threadborne represents possibility, not destiny or prophecy.

## Project Structure

```text
threadbound/
  addons/      Godot plugins
  Assets/      Game art, UI art, tiles, animation sources
  docs/        Design, gameplay, narrative, art, and archive material
  Src/         Godot scenes, scripts, shaders, and gameplay systems
```

Important runtime files:

- `project.godot`
- `Src/Environment/World/World.tscn`
- `Src/Characters/Player/player.tscn`
- `Src/Characters/Player/player.gd`
- `Src/Equipment/BaseGloves.gd`
- `Src/Equipment/base_gloves.tscn`
- `Src/Equipment/equip_manager.gd`
- `Src/UI/RadialMenu.tscn`
- `Src/UI/radial_menu.gd`

## Tech

- Engine: Godot 4
- Language: GDScript
- Repository owner: ThreadboundDev

## Contribution Notes

Threadbound is early and actively changing. Before changing architecture, scene trees, equipment systems, combat systems, lore, or assets, explain the intended change and get approval.

Small documentation cleanup, comments, and focused bug fixes are welcome when they preserve the existing direction.
