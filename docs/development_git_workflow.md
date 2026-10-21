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

## Work and playtest handoff

Use [Project status and work list](project_status_and_worklist.md) for the prioritized **Away** queue (conversation, design decisions, source review, automated verification, authorized fixes/proposals) and **At-computer** queue (feel, visual, route and release acceptance). Chase being away from the computer does not block independent work whose dependencies are ready.

When Chase asks what to test, read [Next hands-on test session](next_test_session.md), check its target revision against current changes, and provide the short ordered checklist directly in chat with scene, actions and expected result. Add exact retests for recent fixes first. After feedback, record keep/change/untested, prioritize up to three issues and refresh the next-session sheet. Keep automated results distinct from hands-on acceptance; follow existing approval rules for architectural and other protected changes.

## September 26 checkpoint

The accumulated blue-biome work is preserved on `threadbound/chore-blue-development-checkpoint` in topic commits. Some runtime changes share `player.gd`; these stay together rather than creating artificial partial versions of that file. Treat the complete branch as the runnable checkpoint; the individual commits group review topics rather than promising independent feature releases.

The checkpoint retains earlier intentional art studies, animation sources and test scenes. Their presence does not mean they are all active in the game. The lake greybox and current player/enemy scene references determine the active assets. Future archive cleanup should follow a reference audit rather than deleting historical sources during a Git checkpoint.
