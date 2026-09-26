# Development checkpoints

Use `threadbound/<type>-<description>` branches and `<type>: <description>` commits. Commit a coherent change after its relevant checks pass, before starting the next feature. Push at the end of a work session. Do not mix unrelated unfinished features into a single commit.

Blender sources, GLB exports, FBX animation inputs and ZIP source archives use Git LFS. Install Git LFS before cloning or pulling the project; run `git lfs pull` if an asset contains a pointer instead of binary data. Existing history has not been rewritten or migrated.

Keep deliberate named art revisions and approved source files. Automatic Blender backups (`.blend1`, etc.), Godot caches, build outputs, logs and `tmp/` stay local. Never ignore unfinished source work just to make the status clean.

Before publishing:

1. Review `git status --short` and the staged diff.
2. Stage explicit feature paths, including assets and their Godot import settings.
3. Run relevant Godot checks and `git diff --cached --check`.
4. Commit with a descriptive type and message, then push the branch.
5. Open a PR describing behavior, validation and remaining playtest needs. Merge only after review.

## September 26 checkpoint

The accumulated blue-biome work is preserved on `threadbound/chore-blue-development-checkpoint` in topic commits. Some runtime changes share `player.gd`; these stay together rather than creating artificial partial versions of that file. Treat the complete branch as the runnable checkpoint; the individual commits group review topics rather than promising independent feature releases.

The checkpoint retains earlier intentional art studies, animation sources and test scenes. Their presence does not mean they are all active in the game. The lake greybox and current player/enemy scene references determine the active assets. Future archive cleanup should follow a reference audit rather than deleting historical sources during a Git checkpoint.
