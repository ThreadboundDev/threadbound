# Threadbound

![Threadbound Banner](docs/art/concept_art/banner.png)

Threadbound is a 2D action metroidvania built in Godot. It is about momentum, identity, and choice: the player moves through the world by chaining traversal, combat, equipment, and real-time adaptation into one continuous flow.

You are the Threadborne, a being born from the wound left when the primordial Threads were separated. The world of Eryndor is not asking you to become a class, follow a fixed build, or unlock a prescribed route. It is asking what kind of being you will become through action.

## Current Demo Direction

The active demo target is the **Chamber of the First Weave**.

The chamber is being built as a compact vertical slice of the full game:

- A playable title screen, pause menu, options menu, and in-game menu shell
- Flow-focused player movement with jumping, dashing, momentum, attacking, and grappling
- Audio routed through a centralized `AudioManager` with music, SFX, UI, and background audio categories
- Three wing objectives built around the core Threads:
  - **Power**: defeat the red wing enemies
  - **Balance**: prove control over momentum
  - **Essence**: reach and claim the thread through puzzle/traversal space
- Wing doors and a tri-thread boss door that respond to demo progress
- Save point foundation through the Blossom of Eryndor
- Early enemy, boss, pickup, and objective systems

The short-term goal is not a content-complete game. It is a clean, testable demo that communicates Threadbound's feel, tone, and design promise.

## Design Pillars

Threadbound is guided by a few hard rules:

- **Flow first**: movement, combat, and traversal should feel connected instead of separated into stops and menus.
- **Identity through action**: equipment, color, combat style, and world response should reflect what the player chooses and does.
- **Expression over optimization**: there should not be one correct build or one mandatory route.
- **Base-kit completion**: major progress should not be locked behind optional gear. Equipment should expand how the player plays, not whether they can continue.
- **Choice has consequence**: absorbing, sparing, claiming, or refusing power should shape mechanics, appearance, world state, and narrative tone.

## Current Runtime Entry Points

Important Godot scenes and systems:

- Main scene: `Src/UI/MainMenu/main_menu.tscn`
- Demo world: `Src/Environment/World/Chamber Of The First Weave.tscn`
- Player: `Src/Characters/Player/player.tscn`
- Player controller: `Src/Characters/Player/player.gd`
- Base gloves / grapple: `Src/Equipment/base_gloves.tscn`
- Equipment manager: `Src/Equipment/equip_manager.gd`
- Audio manager: `Src/Global/audio_manager.gd`
- Audio registry: `Src/Global/audio_registry.tres`
- Demo progress: `Src/Global/demo_progress.gd`
- Pause menu: `Src/UI/PauseMenu/pause_menu.tscn`
- Game menu shell: `Src/UI/GameMenu/game_menu.tscn`
- Save point menu: `Src/UI/SavePointMenu/save_point_menu.tscn`
- Door foundation: `Src/Environment/Doors/demo_door.tscn`
- Demo thread pickups: `Src/Pickups/DemoThreads/`

## Project Structure

```text
threadbound/
  addons/      Godot plugins
  Assets/      Runtime art, UI, animation, audio, tiles, and source exports
  docs/        Design, gameplay, narrative, art direction, and archive notes
  Src/         Godot scenes, scripts, resources, shaders, and gameplay systems
```

The current naming direction is documented in [Project Structure and Naming](docs/design/project_structure_and_naming.md).

## Documentation

The docs folder contains the living design source for Threadbound. Good starting points:

- [Docs Index](docs/README.md)
- [Narrative Canon](docs/narrative/CANON.md)
- [Core Mechanics](docs/gameplay/core_mechanics.md)
- [Combat Foundation](docs/gameplay/combat_foundation.md)
- [Equipment Slots](docs/gameplay/equipment_slots.md)
- [Progression and Choices](docs/design/progression_and_choices.md)
- [Gameplay Philosophy](docs/design/gameplay_philosophy.md)
- [Visual Readability Art Pass](docs/art/visual_readability_art_pass.md)
- [Asset Standards](docs/art/asset_standards.md)

## Narrative Guardrails

The current cosmology is stable. Before making lore, dialogue, quest, or worldbuilding changes, start with the canon docs.

Core guardrails:

- Eryndor is the living world-consciousness and primary narrator.
- Thought is the First Weaver.
- The Threads were originally unified within Eryndor and were never meant to be possessed.
- The Monarch, Hermit, and Sage were once the King, Monk, and Scholar.
- The Weaver is not the creator of the world and did not shatter the Loom.
- The Threadborne represents possibility, not destiny or prophecy.

## Development Notes

Threadbound is early and actively changing. The project currently prioritizes readable systems, editable Godot scenes, and small focused commits.

Before changing architecture, scene trees, equipment systems, combat systems, lore, or approved assets, explain the intended change and get approval. Focused bug fixes, documentation cleanup, comments, and small refactors are fine when they preserve the existing direction.

Useful habits:

- Keep runtime files Godot-friendly and descriptive.
- Prefer scene/resource-driven setup where designers need to tune by hand.
- Use the existing managers and registries instead of scattering one-off systems.
- Commit and push frequently while iterating.

## Tech

- Engine: Godot 4.7.1 Mono
- Primary language: GDScript
- Repository owner: ThreadboundDev

## License Notice

This project is currently **All Rights Reserved**. You may view the code and content, but you may not reuse, redistribute, or create derivative works without explicit permission.
