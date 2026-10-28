# CC0 library and focused asset search plan

October 28, 2026. Current policy: Chase wants **CC0 assets only** for this new
download library. Do not retain packs requiring credit, prohibiting commercial
use, or carrying a custom license. This is a policy for the newly collected
library, not an instruction to delete existing installed game assets.

Later October 28, Chase explicitly requested assessment of a new Fab Standard
[armored golem candidate](armored_golem_review_2026_10_28.md). That review is
separate from this CC0 collection; a specific retention/use exception remains
undecided. Do not treat the review as a general licensing-policy change.

## Current library

Ten original ZIPs remain in `C:\Users\chase\Documents\Threadbound Asset Library\archives`:
1,819,468,033 bytes (1.69 GiB), containing 4,593 file entries including alternate
formats. [Current disposition manifest](library_disposition_2026_10_28.json).
The [original audit](free_asset_inventory_2026_10_28.md) and its catalogs are
historical records of all 13 downloads, including the three removed packs.

| Pack ID | Retained pack | Best source role |
| --- | --- | --- |
| P02 | NOX Essentials | Water/cave ambience, footsteps, selected effort sounds |
| P03 | Fantasy Props MegaKit | Workshop furniture, ropes, storage, lights |
| P06 | KayKit Fantasy Weapons Bits | Sword/shield silhouette comparisons; other weapon stock |
| P07 | KayKit Resource Bits | Folded textiles, wood, stone and workshop supplies |
| P08 | Kenney Retro Fantasy Kit | Lightweight building/layout stock; material adaptation needed |
| P09 | Medieval Village MegaKit | Modular architecture, windows, rooflines and supports |
| P10 | Modular Character Outfits – Fantasy | Peasant/ranger clothing for future NPC trials |
| P11 | Universal Animation Library 2 | Carry/work/idles, climb and visual combat source |
| P12 | Universal Animation Library | Talk/interact/sit, locomotion and reaction source |
| P13 | Universal Base Characters | Reusable humanoid body/head/hair foundation |

Removed by Chase's instruction: **P01 Bestiary**, licensed QAL; **P04 Fantasy RPG
Music Pack** and **P05 Fantasy RPG Music Vol. 2**, licensed under AlkaKrab's
custom agreement. Removed ZIPs total 1,588,404,389 bytes (1.48 GiB). No attribution-
required or noncommercial-only pack was identified in this batch; these three
were removed because their terms were not CC0. Their extracted preview/PDF
evidence was removed from the local library too. Historical textual license
findings and hashes remain in Git so the disposition is explainable.

Retention is based on the **CC0 notices inside these exact ZIPs**, saved with
their hashes. NOX's [creator listing](https://nox-sound-design.itch.io/essentials-series-sfx-nox-sound)
also confirms CC0. The retained Quaternius downloads include CC0 notices, and
the [UAL1 pack page](https://quaternius.com/packs/universalanimationlibrary.html)
still states CC0, whereas the [central license page](https://quaternius.com/license.html)
now states QAL. That discrepancy remains recorded; do not infer that future
Quaternius downloads are CC0 from the creator's name. Check each actual release
and preserve its terms. Any future pack supplied under QAL fails this policy.

## Recommendation on 2D and 3D — pending Chase's decision

Continue evaluating **hybrid 2.5D**. A complete 3D conversion is not required to
benefit from free 3D assets. Source format and final presentation are separate
choices: a model can become a live actor, a rendered animation sheet, or a fixed
building/prop stamp. Models give reusable proportions, rigs, consistent camera
views and editable lighting even when the delivered art is 2D.

The current work-list default already combines a live 3D player, 3D enemies and
tower with painted houses, villagers and bulbs. Keep that accepted/pending
comparison history intact. Chase likes the low-poly look but has not approved
a full conversion. No new art direction, replacements or engine changes are
authorized by this recommendation.

Favor live models where turning, deformation, reusable motions and depth improve
the result. Favor 2D for layered scenery and compositions that read better as
graphic shapes. Try rendering source models into 2D when the model is useful
but its live shading conflicts with the room. A consistent palette, contour,
shadow grouping, character scale and gameplay readability should connect the
results; low polygon count alone will not make mixed packs coherent.

After stabilization, a useful separately scoped comparison is **one workshop
vignette**: an existing character-sized worker, a talk/work action and a few
textile/wood props, shown at the same gameplay camera as live 3D and rendered
2D. Judge foot contact, hand/tool contact, side-view silhouette, material match,
motion and actual frame cost. This is a proposal, not a new implementation task
or acceptance test already performed. Reuse the existing comparison controls
where practical, after listing files and obtaining required replacement approval.

## What we need to search for

First use what is present: the library already covers generic swords/shields,
architecture, crates/barrels/furniture, human bodies/clothes, basic talking and
locomotion, footsteps and water ambience. More broad fantasy packs are unlikely
to resolve the most specific gaps.

| Need in Threadbound | Copyable searches | Useful download criteria | Priority |
| --- | --- | --- | --- |
| Give settlements a woven identity | `CC0 low poly loom spindle shuttle yarn skein`; `CC0 fishing net rope knot woven basket 3D` | Complete visible objects, simple UVs/materials, readable at gameplay size; distinguish a yarn shuttle from a loom assembly | High |
| Make thread and cloth audible | `CC0 rope tension creak`; `CC0 cloth tear fabric stretch`; `CC0 spool rattle`; `CC0 underwater bubbles swimming strokes` | Clean isolated recordings, several variations, no baked music or heavy reverberation; water ambience already covered | High |
| Find music after removing the custom-license packs | `CC0 dark fantasy ambient instrumental loop`; `CC0 melancholic chamber music game loop` | Actual CC0 license file, clean loop points, restrained instrumentation, no required attribution; listen before collecting a large batch | High |
| Support believable village work | `CC0 humanoid weaving sewing animation`; `CC0 fishing net repair animation`; `CC0 carpenter planing animation` | Actual included motion, editable skeleton, tool/contact information, in-place version; generic work motions already available | Medium |
| Strengthen fabric and ribbon identity | `CC0 stylized woven fabric seamless`; `CC0 stitched trim texture`; `CC0 rigged cloth strip ribbon 3D` | Low visual noise, editable color, appropriate density; simple baked deformation preferred for an initial trial | Medium |
| Fill specific motion gaps after reviewing existing work | `CC0 ledge grab climb animation`; `CC0 rope pull reel animation`; `CC0 swimming dive stop animation` | Check against later authored air/water work and retained UAL clips; avoid duplicate walk/run sets | Medium |
| Source approved creature anatomy when needed | `CC0 rigged stylized fish animation`; `CC0 low poly bird rig fly land` | Actual mesh/rig/clip contents, side-view readability and fit to an approved enemy concept | Later |

These are search phrases, not verified offers or claims that each specialized
asset exists for free. This pass downloaded nothing new and auditioned no audio.
Do not force a gameplay feature or new species into the world because a pack
contains it. The removed Bestiary no longer supplies creature donor candidates.

## Collection rule for the next batch

Before downloading, write one sentence: **“This fills ___ in this room/action.”**
Check our current catalog first. Save only an asset that supplies that missing
piece or offers a concrete quality improvement worth comparing. Record creator,
page URL, explicit CC0 notice, formats, dependencies, and intended use together.
“Free,” “royalty-free,” and “no credit needed” alone do not establish CC0.
Skip unclear/custom/attribution-required/noncommercial terms under Chase's policy.

Keep source packs outside Godot. An approved trial should import only selected
models/motions and dependencies. P13's three missing normal-map references remain
documented in the original audit for a later working-copy fix; keeping that pack
does not mean it has passed an engine import or animation-retargeting test.

Checkpoint: `docs: apply CC0-only asset policy and focus reuse searches`.
T20 remains the active implementation priority. This decision concerns collection
and recommendations; all protected production changes require their own scope.
