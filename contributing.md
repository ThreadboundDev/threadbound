# Contributing to Threadbound

Thanks for taking interest in Threadbound.

This project is early, personal, and still finding its final shape. Clarity matters more than volume: every change should make the project easier to understand, easier to playtest, or easier to build on.

## Development Priorities

Current priorities:

- Polish base movement.
- Polish the base grapple.
- Stabilize the base equipment kit.
- Keep animation and equipment behavior readable.
- Keep documentation aligned with current canon and implementation.

Later priorities:

- Expanded equipment variants.
- Combat and weapons.
- Enemy implementation.
- Boss encounters.
- Larger world and progression systems.

## Project Structure

```text
docs/   Design, gameplay, narrative, art direction, and archives
Assets/ Game art, animation exports, UI art, and source art files
Src/    Godot scenes, scripts, shaders, and gameplay systems
addons/ Godot plugins
```

## Documentation Guidelines

- Use current canon from `docs/narrative/CANON.md`.
- Archive obsolete drafts instead of deleting them when they may be useful history.
- Prefer dated archive folders, such as `docs/archive/2026-06-06_lore_cleanup/`.
- Keep docs clear and direct.
- Avoid introducing new cosmological forces, creator figures, or retcons without explicit approval.

## Code Guidelines

- Keep changes focused.
- Follow existing Godot and GDScript patterns in the project.
- Avoid large scene tree restructures without approval.
- Preserve base-kit gameplay while polishing feel.
- Do not treat obsolete archetype scripts as active runtime code.

## Change Approval

Before making architectural changes, explain:

- What will change.
- Why it is needed.
- Which files will be modified.

Wait for approval before changing:

- Scene tree structure
- Combat systems
- Equipment systems
- Lore canon
- Asset replacements

Documentation cleanup, comments, and small bug fixes are fine when they stay within the current direction.
