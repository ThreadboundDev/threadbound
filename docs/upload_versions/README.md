# Threadbound Upload Versions

These generated master documents reduce the maintained documentation set to five uploadable files while preserving the full text of every active source document.

1. `01_art_master.md` - art direction, environment style, asset standards, and readability pass
2. `02_design_master.md` - design philosophy, identity, color, enemies, levels, progression, and project conventions
3. `03_gameplay_master.md` - mechanics, combat, equipment, and bosses
4. `04_narrative_characters_master.md` - narrative canon plus all character references
5. `05_narrative_world_and_story_master.md` - narrative canon, cosmology, voice, plot, symbolism, cinematic, and endings

`CANON.md` intentionally appears in both narrative bundles so either upload has the project guardrails. Archived notes and image assets are intentionally excluded.

Do not edit generated master documents directly. Update the maintained source file and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\tools\\build_upload_docs.ps1
```