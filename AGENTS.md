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



