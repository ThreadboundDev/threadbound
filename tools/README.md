# Development tools and verification

Subfolders group tools by the system they inspect or author: player animation,
environment, combat, grapple, enemies, audio, art, UI, save, and the separate 3D study.
These are development utilities, not the game's runtime code.

`maintenance/` provides a read-only local file inventory and an explicit-plan
file mover with a durable journal. It never permanently deletes files or
overwrites an existing destination. An organization move journal is retained
locally under `docs/organization/local/2026-11-02/`.

Use the installed Godot version. Keep temporary outputs in ignored `tmp/`;
retain meaningful reports in `docs/verification/` or the relevant `work/` package.
Use `docs/project_status_and_worklist.md` for current priorities and applicable checks.
