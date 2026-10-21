# \# Threadbound Development Rules



### \## Approval Requirements



Before making any architectural changes:



\* Explain the proposed change.

\* Explain why the change is needed.

\* List all files that will be modified.

\* Wait for approval before editing.

## 

### \### Allowed Without Approval



\* Bug fixes

\* Documentation

\* Comments

\* Small refactors



### \### Not Allowed Without Approval



\* Scene tree restructuring

\* Combat system changes

\* Equipment system changes

\* Lore changes

\* Asset replacements



\---



## \# Git Workflow Rules



### \## Branch Naming



Use the repository branch prefix:



threadbound/



Branch format:



threadbound/<type>-<description>



Allowed types:



\* feature

\* fix

\* asset

\* art

\* vfx

\* level

\* refactor

\* docs

\* chore

\* test



Examples:



\* threadbound/feature-radial-equipment-swap

\* threadbound/fix-grapple-collision

\* threadbound/asset-player-air-attack-cleanup

\* threadbound/vfx-enemy-death-unravel



Do not use:



\* codex/

\* temp/

\* misc/

\* update/



\---

## 

## \## Commit Messages



Format:



<type>: <description>



Examples:



\* feature: add radial equipment swap

\* fix: correct grapple collision

\* asset: clean player attack frames

\* vfx: add enemy death unravel effect



Keep commit messages concise and descriptive.



\---



### \## Pull Requests



Title format:



\[Type] Description



Examples:



\* \[Feature] Radial equipment swap

\* \[Fix] Grapple collision edge case

\* \[Asset] Player air attack cleanup



Pull requests should include:



1\. What changed

2\. Why it changed

3\. How it was tested



\---



### \## Threadbound Project Philosophy



Preserve existing project direction unless explicitly instructed otherwise.



Do not:



\* Introduce new gameplay systems without approval

\* Rewrite established lore

\* Replace approved art direction

\* Add progression gating

\* Introduce classes or permanent builds

\* Remove player expression systems



Follow existing design documents and established project conventions whenever possible.

## Required Git checkpoints — Chase's standing instruction, October 21, 2026

Chase explicitly requires regular commits and Git reminders so work does not
accumulate across chats again. Apply this to every repository development task.
Routine task-scoped commits and pushes are authorized; protected implementation
changes still follow the approval requirements above.

- At task start, inspect `git status --short --branch` and recent history. State
  the task and its intended commit checkpoint. Use
  `docs/project_status_and_worklist.md` as the single current priority list.
- Reuse the current correctly named branch when the work belongs to its scope.
  Create `threadbound/<type>-<description>` for a separate task when appropriate;
  start from the current accepted work, never an older branch by assumption.
- Keep one implementation task active. Before changing topics, starting another
  feature/art pass, or ending a work session, explicitly call out **Git checkpoint
  due** if changes remain. Save editor/Blender/Krita files before staging.
- Commit each coherent fix, test update, accepted art delivery, or documented
  decision after relevant verification. During longer work, review status about
  every 30-45 minutes and checkpoint a useful unit when ready. Do not create empty
  commits or split a dependent change into broken pieces just to meet a timer.
- Stage explicit paths, review the staged diff, run `git diff --cached --check`,
  and use LFS for applicable assets. Never discard/stash someone else's edits,
  ignore unfinished source, or weaken tests merely to produce a clean status.
- If interrupted work must be saved, make a clearly described WIP checkpoint
  with known failures and the next step recorded. WIP is not accepted/release
  work. Preserve unrelated edits and explain anything left uncommitted.
- Push after each completed task and at session end. Verify the remote branch
  matches local HEAD. If a push fails, retain the local commit and report the
  exact blocker; do not claim the work is backed up remotely.
- When Chase works manually in Godot or an art tool, remind him to save and
  checkpoint before switching tasks. Handle routine Git operations when tools
  are available. If Chase wants to run Git himself, provide exact commands and
  verify the result before continuing into another implementation task.
- End repository work with a short Git status: branch, latest commit, pushed or
  local-only, and remaining changes. Mark work-list items complete only with the
  commit and required validation/acceptance recorded.
- Pure discussion with no repository change needs no commit. Record consequential
  project decisions in the relevant document and commit that documentation.

Do not merge, rewrite history, or publish a build merely to satisfy a Git
checkpoint. Follow review and release approval requirements separately.



