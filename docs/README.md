# Threadbound Docs

This folder contains design, gameplay, narrative, art direction, and archived development notes.

## Start Here

- [October 21 development checkpoint](checkpoint_2026_10_21.md) - consolidated recap, active vs unfinished assets, fresh check failures and the recovery Git branch
- [Project status and work list](project_status_and_worklist.md) - prioritized Away and At-computer queues, acceptance steps and wider verification checklist (reviewed October 5, 2026)
- [Next hands-on test session](next_test_session.md) - the short ordered checklist to use when Chase is ready to play; update after feedback or relevant runtime changes
- [October 10 focused verification](verification/focused_checks_2026_10_10.md) - fish, bulbs, walls and room-authoring results, tested source state and remaining coverage
- `docs/narrative/CANON.md` - current narrative canon and guardrails
- [Enemy factions and world context](design/enemy_factions_and_world_context.md) - enemy belonging rule, proposed Hermit faction connections and NPC talking points
- [Woven Blue guardians](art/woven_blue_guardians_v1.md) - rigged Eave Runner art, twelve clips, Godot review and two proposed flying enemies
- `docs/gameplay/core_mechanics.md` - traversal and real-time weaving philosophy
- `docs/gameplay/combat_foundation.md` - reusable combat components and enemy framework
- `docs/gameplay/equipment_slots.md` - equipment slot design
- `docs/narrative/story/endings.md` - ending structure and secret-route development reference
- `docs/design/project_structure_and_naming.md` - project naming and folder conventions
- `docs/design/color_system.md` - color identity, acquisition, and gameplay framing
- `docs/design/progression_and_choices.md` - absorb/spare progression framing
- `docs/design/pattern_system.md` - exploratory long-term Pattern accessory, embroidery, and build-combination design
- `docs/art/environment_art_style.md` - environment visual direction
- `docs/art/asset_standards.md` - runtime art naming, palette, sprite, and rigging standards

## Folders

- `archive/` - dated historical material that is no longer canon or no longer active
- `art/` - art direction and concept art
- `design/` - broad design principles and systems direction
- `gameplay/` - mechanics, combat, equipment, bosses, and endings
- `narrative/` - canon, cosmology, story, character, and voice documents
- `upload_versions/` - generated category bundles for uploading to chat tools with attachment limits

## Upload Versions

Use `docs/upload_versions/README.md` to choose a compact set of category master documents. These files reproduce the maintained source docs without summarizing them and can be refreshed with `tools/build_upload_docs.ps1`.

## Archive Habit

When a document becomes obsolete but still has historical value, move it into a dated folder under `docs/archive/`.

Use a short README in each archive folder to explain why the material was archived.
