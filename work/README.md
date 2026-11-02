# Verification fixtures and authoring evidence

Named work packages retain inputs, manifests, scripts, review images and reports
used by existing tools and project documentation. They are not all disposable
temporary folders. The painted-comparison scene currently reads
`painted-2d-comparison-2026-10-22/source_manifest.json` at runtime.

Current character packages:

- `pale-doll-clothing-prep-2026-11-02`: separate clothing generation references.
- `pale-doll-base-v3`, `pale-doll-study-2026-11-01`: original study/review evidence.

`third-person-study-2026-10-28/project` is the tracked source of an independent
prototype, with its own `project.godot`. Its installed playable copy lives under
`Threadbound - Potential Use/Prototypes/Third Person Study`, outside the actual game.

Ignored isolated import projects, sandboxes, nested Godot caches and temporary
extractions have been moved to deletion staging. Their tracked manifests and
source inputs remain. A tool may recreate a scratch folder when rerun; keep only
useful evidence afterward, rather than accumulating whole import projects.
