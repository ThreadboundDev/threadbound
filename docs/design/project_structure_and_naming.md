# Project Structure and Naming

This document defines the cleanup direction for Threadbound files and folders. It is meant to keep the project readable for collaborators without forcing risky path renames during unrelated gameplay work.

## Project Roots

- `addons/` stores Godot editor and runtime plugins.
- `ArtSource/` stores editable art, reference images, and intermediate authoring inputs. Use `.gdignore` for source-only subtrees.
- `Assets/` stores game-ready art, UI images, animation exports, audio, and importable visual assets.
- `Builds/` is ignored and stores regenerable local exports when needed.
- `Src/` stores Godot scenes, scripts, resources, UI, characters, environment, equipment, and managers.
- `docs/` stores design, gameplay, narrative, art direction, and archived historical notes.
- `Media/` stores development captures and social-media production files that are not loaded by the game.
- `tools/` stores verification scenes, cleanup scripts, and local development utilities.

Keep runtime assets out of `ArtSource/` and temporary build output out of the repository.

## New Files

Use Godot-friendly naming for new runtime files:

- Files and folders: `snake_case`
- GDScript classes: `PascalCase`
- Scene node names: `PascalCase`
- Signals, variables, functions, and input actions: `snake_case`

Examples:

- `base_gloves.gd`
- `base_grapple_state.gd`
- `radial_menu.tscn`
- `threadborne_player.tscn`
- `class_name BaseGloves`

## Runtime Paths

Avoid spaces, punctuation-heavy names, and temporary suffixes in paths that Godot loads directly.

Preferred:

- `Assets/threadborne/equipment/base_grapple_rope.png`
- `Src/equipment/base_gloves.gd`

Avoid:

- `Base Grapple Rope.png`
- `Base_Grapple_Rope&Needle.png`
- `radial_menu.tscn11067775801.tmp`
- `SomeSprite.png~`

Existing paths do not need to be renamed immediately. Rename old paths only in focused cleanup commits where Godot import files, scene references, and scripts can be checked together.

## Art Assets

For exported runtime art, prefer stable descriptive filenames in `snake_case`.

For source art files, keep useful working files under `ArtSource/`, but do not commit editor backups or autosaves. The `.gitignore` excludes common temporary files such as `*~`, `*.tmp`, and Godot temporary scene saves.

## Documentation

Use lowercase `snake_case` for new docs:

- `base_kit_polish_plan.md`
- `combat_direction.md`
- `project_structure_and_naming.md`

When a document becomes obsolete but still has reference value, move it to:

`docs/archive/YYYY-MM-DD_short_reason/`

Each archive folder should include a short `README.md` explaining why the material was archived.

## Branches and Pull Requests

Use the repository `threadbound/<type>-<description>` convention:

- `threadbound/docs-project-structure`
- `threadbound/fix-grapple-collision`
- `threadbound/asset-player-animation-cleanup`
- `threadbound/feature-equipment-ui`

Keep pull requests focused around one kind of change so review stays approachable.
