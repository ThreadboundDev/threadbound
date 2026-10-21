# Development checkpoints

Use `threadbound/<type>-<description>` branches and `<type>: <description>` commits. Commit a coherent change after its relevant checks pass, before starting the next feature. Push at the end of a work session. Do not mix unrelated unfinished features into a single commit.

## Required rhythm from October 21, 2026

Chase's standing instruction is to make Git checkpoints explicit. The assistant
handles routine task-scoped commits/pushes and reminds Chase to save manual
editor/art work before switching tasks. This is also recorded in `../AGENTS.md`.

1. **Start:** inspect status/history; choose one item from the
   [current work list](project_status_and_worklist.md); name its intended commit.
2. **Work:** finish the smallest coherent result and run its relevant checks.
   Review status about every 30-45 minutes during longer tasks; the timer is a
   reminder, not a requirement for artificial or empty commits.
3. **Checkpoint:** save files, stage explicit paths, inspect the staged diff,
   run `git diff --cached --check`, commit, and push. Include the work-list result
   and next hands-on retest in the same task commit when practical.
4. **Verify:** confirm remote HEAD equals local HEAD, record the commit/result,
   and report any remaining changes. Then choose the next task.

Call out **Git checkpoint due** before a topic change or session end when files
remain uncommitted. If Chase wants to do Git himself, provide exact commands
and verify completion. If interrupted work is not ready, preserve a clearly
described WIP checkpoint with its failures and next step; do not call it accepted.
If a push is blocked, state that the commit exists only locally and why.

The current stabilization branch is
`threadbound/chore-october-development-checkpoint`, starting from `16b3bd3c`.
Keep related stabilization and planning commits here until this branch is
reviewed. After integration, use focused task branches from the accepted base.
Do not return to `water-cleanup` or `Main` without checking their history.
Opening a PR and merging are separate from saving work; never merge or publish
a build automatically to complete a checkpoint.

Blender sources, GLB exports, FBX animation inputs, ZIP source archives and scoped delivery/reference images use Git LFS according to `.gitattributes`. Install Git LFS before cloning or pulling the project; run `git lfs pull` if an asset contains a pointer instead of binary data. Existing history has not been rewritten or migrated.

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
