# Downloaded asset library — October 28, 2026

**Historical initial audit.** Chase subsequently requested CC0-only retention.
P01, P04 and P05 were removed; ten packs with included CC0 notices remain.
Use the [current library policy and search plan](cc0_library_and_search_plan.md)
and [disposition manifest](library_disposition_2026_10_28.json) for current holdings.
Counts, paths and music/Bestiary suggestions below describe the original batch;
those removed packs are no longer available for reuse. Their original extracted
evidence was deleted locally; textual findings remain as historical records.

## Result and location

13 newly downloaded ZIPs, **3,407,872,422 bytes (3.17 GiB)** compressed;
4,760 archive files, 3.65 GiB uncompressed. All archives passed full ZIP CRC
reads. The catalog inspects 531 glTF/GLB files; alternate formats and root-motion
copies are not additional models or additional unique actions.

Local library: `C:\Users\chase\Documents\Threadbound Asset Library`.
Original ZIPs live in `archives/`; `catalog/` contains the audit, preview images,
license documents and extracted PDF text. ZIPs stay intact for provenance and
selective extraction. The 13 originals were removed from Downloads only after
destination SHA-256 verification. Older downloads, loose FBXs, artwork,
installers and unrelated documents were left in place.

Only documentation, catalog metadata and the inspection script enter Git.
The external library is a **local copy, not backed up by the Git push**.
No assets have been installed or replaced in the game. Gameplay, equipment,
scene structure and lore are unchanged. T20 stabilization remains the current
implementation priority; this audit prepares later asset decisions.

Machine-readable records beside this report:

- [Archive hashes, sizes and counts](download_manifest_2026_10_28.json).
- [Every archive member](download_files_2026_10_28.csv): filter by pack ID,
  filename or extension; source paths are exact ZIP member names.
- [Model geometry, skeletons, dependencies and clip names](download_models_2026_10_28.json).
- [Included license/readme text and PDF extraction](download_evidence_2026_10_28.json).
- [Animation shortlist and complete clip list](download_animation_clips_2026_10_28.md).

## Pack inventory and proposed use

Priority means suitability for a later isolated trial, not permission to replace art.
Sizes below describe the original ZIPs. CC0 labels report included notices;
the Quaternius discrepancy is addressed separately below.

| ID | Download / size | Actual downloaded contents | Fit / recommendation | Included license |
| --- | --- | --- | --- | --- |
| P01 | Bestiary – Dungeon Monsters Kit Standard / 45.1 MiB | **Imp and Puglin only**, FBX + GLB, 55-joint rigs; 15,232 / 7,528 mesh triangles; three base-color maps per creature plus normal/ORM/emission | Conditional enemy donors. All 55 joint names occur in the UAL rigs, but proportions/rest poses and animation transfer remain untested. Neither GLB contains animation clips. Large troll/other advertised creatures are absent. | QAL v1.0, dated August 28, 2026 |
| P02 | Essentials Series NOX SOUND / 988.4 MiB | **1,644 WAVs**: footsteps, nature/water ambience, voices, vehicles, electromagnetic recordings and sample sounds; original PDF docs | **High**: wood/rock/water footsteps, lake/stream/cave/rain loops; secondary creature-effort source. Modern vehicle/device sounds are lower priority. | CC0 in included README PDF and creator page |
| P03 | Fantasy Props MegaKit Standard / 143.3 MiB | **94 models**, glTF + BIN, FBX and OBJ; furniture, books, rope, containers, tools, lights and weapons | **High**: village interiors, workshop/storage dressing, rope and hanging cloth. Use a small consistent subset after material matching. | CC0 notice |
| P04 | Fantasy RPG Music Pack / 715.3 MiB | **28 named audio pieces** in WAV + MP3: 10 Ambient, 5 Dark Ambient, 5 Light Ambience, 5 Action, 3 Fx | Audition ambient/dark ambient for exploration and tower, light ambience for settlement. Filename-based candidates only; no final music choice. | AlkaKrab custom Music License Agreement |
| P05 | Fantasy RPG Music Vol. 2 / 754.5 MiB | **29 pieces** in WAV + MP3 + OGG: 10 Ambient, 5 Light Ambient, 5 Night Ambient, 5 Action and Complete/Death/Strange/Victory | Audition settlement/night and encounter transitions. Many files explicitly name loops; confirm actual loop seams. | Same AlkaKrab agreement |
| P06 | KayKit Fantasy Weapons Bits 1.0 FREE / 3.2 MiB | **31 model variants** in glTF + BIN, FBX (generic and Unity), OBJ; shared texture atlas | **High**: clear sword/shield silhouettes and excellent weapon comparison set. See weapon mapping below. Static meshes, not a weapon animation library. | CC0 |
| P07 | KayKit Resource Bits 1.0 FREE / 8.1 MiB | **76 models**; textiles, timber, stone, ore/bars, scrap, pallets and fuel containers | **High for textiles and timber**, medium overall. Folded cloth bundles are especially relevant to woven settlements. Fuel cans/barrels need an intentional setting fit. | CC0 |
| P08 | Kenney Retro Fantasy Kit 2.0 / 1.9 MiB | **105 model files per 3D format** (GLB, FBX, OBJ); small pixel textures, docks, pulley, stairs, walls, roofs, trees | Medium: very light kit for layout/blockout or background structures. Retro pixel surfaces visibly differ from Threadbound's graphic materials. Do not mix untouched pixel masonry into approved foreground art. | CC0 |
| P09 | Medieval Village MegaKit Standard / 153.5 MiB | **176 models**, glTF + BIN, FBX, OBJ; modular floors/walls/roofs, doors, balconies, stairs, windows and props | **High as construction stock**: rooflines, beams, railings, windows and rear architecture. Requires side-view composition, contour/value treatment and separate authored collision. Not a replacement instruction for current houses/tower. | CC0 notice |
| P10 | Modular Character Outfits – Fantasy Standard / 280.7 MiB | **Four complete outfits**: male/female Peasant and Ranger; 20 modular parts, glTF/FBX, textures; 65-joint rigs | **High** NPC clothing stock; Ranger silhouette can inform a future approved humanoid donor. Full outfits ~12.9k–27k triangles excluding head/hair. Readme says use only base-character head to avoid body clipping. | CC0 notice |
| P11 | Universal Animation Library 2 Standard / 17.9 MiB | **43 animation entries**, including T-pose; in-place and `_RM` GLBs/FBXs, 65-joint mannequin, separate female mannequin and one BLEND | **High**: lantern/rail idles, carry, plant/harvest/water, chop, chest opening, climb, sword/shield reactions. Female mannequin has no embedded clips. | CC0 notice |
| P12 | Universal Animation Library Standard / 15.2 MiB | **43 animation entries**, including T-pose; in-place and `_RM` GLBs/FBXs, setup images | **High**: talk, kneel/fix, sit, interact, pickup, locomotion/swim, death/hit, jab/cross. Pistol/driving content is lower priority. | CC0 notice |
| P13 | Universal Base Characters Standard / 123.0 MiB | **Two base bodies** (male/female), hair/beard/brows in origin-zero and head-rigged variants; 18 glTF exports total, FBXs, textures; bodies ~14.3k/15.1k triangles | **High** reusable NPC foundations alongside P10–P12. Available bodies are named `Superhero_*_FullBody`; not a large ready-made villager roster. | CC0 notice |

Geometry counts sum triangle primitives in each file, not runtime instance
budgets. They do not measure material draw calls, overdraw, texture memory or
frame time. Character assemblies add head/hair costs. Previews shipped in the
ZIPs often show paid/full-edition contents beyond this inventory.

## Weapons: what is here and how it could fit

P06 provides `sword_A`–`sword_E`, `shield_A`–`shield_C`, `staff_A`, `staff_B`,
`wand_A`, `spear_A`, `halberd`, `bow_A` / `bow_B` (each with/without string),
two arrows, two daggers, three axes, three hammers and four fistweapon variants.
This is five sword shapes and three shields, not just one placeholder per class.
The supplied contents image visibly includes a wooden practice sword, plain
metal blades and more elaborate alternatives. Letter names do not encode an
approved upgrade order.

| Existing design role | Candidate stock | Adaptation / outstanding question |
| --- | --- | --- |
| Neutral sword and shield | P06 swords and shields; P03 `Sword_Bronze`, `Shield_Wooden` | Compare grip, length, blade reach and shield coverage against the current character at gameplay scale. Choose a matching silhouette pair before replacement approval. |
| Red / Monarch greatsword | P06 broad/long sword candidates | Preview and scale against existing greatsword design; a larger mesh alone does not establish suitable two-handed poses or approved damage/reach. |
| Blue / Hermit ribbon staff | P06 `staff_A`, `staff_B`, `spear_A` or `halberd` as handle/head donors | A staff is a useful base, but these have no authored ribbon or ribbon motion. Preserve the ribbon-staff identity in an approved adaptation. |
| Yellow / Sage talismans | P03 scroll/book meshes as possible decorative stock | P06 wand/bows are not talismans. Current equipment document specifies talismans; changing the Yellow weapon into a wand/bow would be a separate design decision. |
| Other ranged or polearm ideas | P06 bow/arrow/wand/spear options | Good retained stock; neither a new player weapon class nor a ranged combat change is approved here. |

Chase raised discoverable alternatives and wooden/base/elaborate weapon tiers.
Record this as an **open proposal**: first consider cosmetic finds or expressive
sidegrades. A statistical upgrade ladder needs separate approval and must be
reconciled with [equipment expression and no progression gating](../gameplay/equipment_slots.md).
Keep gameplay color coding separate from the donor's blue crystals/paint.

## Reuse strategy for NPCs and enemies

The highest-value common foundation is **P13 bodies + P10 clothing + P11/P12
motion**, with targeted adaptation. UAL1 and UAL2 expose the same ordered
65 joint names in their inspected skins. This is useful evidence for a shared
pipeline, not a runtime compatibility pass. Existing villagers use a different
MakeHuman-derived rig; current player Mixamo motion also needs bone mapping,
rest-pose and root handling before transfer. Do not throw away the existing
62-action player library or the later authored air/water attack work.

Start a later approved trial with `Idle_Talking_Loop` and `Fixing_Kneeling` on a
single non-runtime NPC copy. Then test `Walk_Carry_Loop` / `TreeChopping_Loop`;
their hands must actually meet the carried object or workstation. Farming
motions could be adapted to labor where appropriate, but do not assume the
Standard packs include fishing, net weaving or boat planing: those named clips
are absent. Existing two work/greet poses are already accepted as sufficient.

For woven creatures, treat P01 mesh/skin weights as reusable construction.
Its 55-joint names are a subset of UAL's 65, but finger counts, bind transforms
and exaggerated limbs still need checking. Neither model supplies locomotion
or attacks in the GLB. No troll is present in the free download. A later
approved creature trial should obscure species cues with rope-bundle anatomy,
stitched/covered face, seams, cloth wraps and deliberately changed silhouette.
Keep hands/feet and attack tells readable; a fabric normal map alone will leave
a recognizable goblin-shaped creature. No new creature identity or lore is
accepted by this report.

Use in-place motion first for actors moved by the existing controller. `_RM`
contains root motion and is a comparison/source variant, not another set of
actions to import alongside the first. Check foot sliding, ground contact,
hand grip, looping, facing, movement ownership and contact timing. Combat clips
are visual source candidates; do not drive hitboxes or attack timing from them
without the required scoped combat approval.

## Environment and sound shortlist

P03 first picks: `Rope_1`–`Rope_3`, `Bucket_Wooden_1`, `Crate_Wooden`, `Barrel`,
`Workbench`, `Workbench_Drawers`, `Peg_Rack`, `Stool`, `Lantern_Wall`, banners,
book groups and shelves. P07 first picks: `Textiles_A/B/C`, textile stacks,
`Wood_Log_Stack`, planks and stone chunks. These add evidence of work and storage
without requiring new gameplay. Rope/cloth is a stronger thematic bridge than
generic ornate fantasy weapons everywhere.

P09 first picks: wood floors/overhangs, balcony railings, separate doors and
frames, windows/shutters, support beams and roof modules. Review source previews
as examples of assembly, not proof that all illustrated buildings/scenery are
in the free ZIP. Standard does not include the paid preconfigured Godot projects.
Most packs here are models with supporting texture maps, not standalone village
terrain/texture libraries. No dedicated woven shader or broad seamless fabric
material library was found in these archives.

Art treatment should follow [the environment guide](../art/environment_art_style.md)
and [asset standards](../art/asset_standards.md): silhouette and contour first,
restrained detail, controlled shadow groups, regional palette, side-view
readability and separation between traversable surfaces and decoration.
Simplify Quaternius's more textured fantasy surfaces; Kenney's tiny pixel
textures need a deliberate material choice. A few matched families will look
more coherent than using every pack in the same room.

P02 filename shortlist: `Footsteps_Wood`, `Footsteps_Rock`, `Footsteps_Water`,
and `Nature_Essentials_NOX_SOUND` cave/drip, stream/river, calm waterfall, wind,
rain and forest files. Preserve clean WAV masters externally; later export only
selected/edited runtime sounds. Audition water layers for masking enemy tells,
check mono/stereo placement, avoid clipping and randomize short repeated steps.
Voice efforts may be useful but require listening for tone and unwanted speech.

Actual WAV files counted by folder: 479 core footsteps, 233 Iceland-pack files,
18 Nature, 14 São Miguel, 161 Vehicle, 72 Electromagnetic, 657 Voices and
10 sample files. The creator page's subcategory counts differ for some groups;
**1,644 is the actual archive total**. No claim that every recording is unique.

P04/P05 are **57 named pieces across two packs**, with duplicate delivery formats,
not 143 different songs. P04 includes three Fx; P05 includes four event pieces.
Begin listening with P04 `Ambient 1`, `Dark Ambient 1`, `Light Ambience 1`,
and P05 `Ambient 1`, `Night Ambient 2 (Loop)`, `Action 1 (Loop)`.
These are audition starting points chosen from labels, **not heard/approved
matches**. Evaluate melancholy/mystery, instrumental palette, energy, duration,
repeat fatigue, loop joins and combat readability before selecting tracks.

## License findings and provenance

The exact bundled notices are retained in the external `catalog/evidence/Pxx/`
folders and text is indexed in the evidence JSON. Original ZIP SHA-256 hashes
tie those notices to this particular download. Findings are dated October 28.

- **P01: QAL v1.0, not CC0.** Commercial project use and modification are
  permitted; attribution is not required. Standalone asset redistribution,
  including modified asset packs, is restricted. Keep the raw library private;
  distribute approved derivatives as part of the game, subject to the terms.
  [Current official QAL](https://quaternius.com/license.html).
- **P03/P09/P10/P11/P12/P13: included CC0 notices**, while the current central
  Quaternius license is QAL. The [UAL1 page](https://quaternius.com/packs/universalanimationlibrary.html)
  and [UAL2 page](https://quaternius.com/packs/universalanimationlibrary2.html)
  still explicitly show CC0. Preserve both facts rather than relabel these
  archives as unconditionally QAL or treating all new downloads as indisputably
  CC0. Both sets of terms allow the intended game use without required credit;
  confirm the conflict with the creator before relying on raw redistribution.
- **P06/P07: bundled CC0.** No mandatory attribution. Retain Kay Lousberg's
  notice and source links from each ZIP for provenance.
- **P08: bundled CC0**, also shown on the
  [official Kenney page](https://kenney.nl/assets/retro-fantasy-kit).
- **P02: CC0**, explicitly in the bundled README PDF and
  [NOX creator listing](https://nox-sound-design.itch.io/essentials-series-sfx-nox-sound).
- **P04/P05: royalty-free custom license, not CC0.** Commercial games and
  videos are permitted and credit is optional. The included PDF restricts raw
  redistribution/sublicensing and standalone music uploads; open-source games
  require direct permission. Timing/volume/EQ/transition edits are allowed;
  remixing or sampling requires written permission. Retain the PDFs. Creator
  listings matching the exact ZIP names:
  [Music Pack](https://alkakrab.itch.io/fantasy-rpg-soundtrack-music),
  [Vol. 2](https://alkakrab.itch.io/free-25-fantasy-rpg-game-tracks-no-copyright-vol-2).

Voluntary creator credits are still useful for a later shipped asset ledger.
Avoid publishing the external library itself. No purchase, contact with creators
or new downloads was performed during this audit.

## What to search for next

| Priority | Search target | Why it fills a real gap | What to check before downloading |
| --- | --- | --- | --- |
| 1 | Loom, shuttle, spindle, yarn skein, woven baskets, hanging nets, rope knots and sailcloth props | More Threadbound-specific than another generic medieval megapack; existing bundles help but do not supply a working weaving station library | Clear silhouette, separate moving pieces, simple materials, license file |
| 1 | Cloth tension, rope creak, thread snap, fabric tear, spool rattle, wood strain, submerged bubbles and swim strokes | Distinctive sound palette; NOX is strong on ambience/steps but not a complete thread-combat sound set | Several clean variations, no baked music, short tails, CC0 or clear game-use rights |
| 2 | Net mending, sewing, weaving, fishing, tool handoffs and boat repair humanoid motion | Actual labor clips missing from the two downloaded Standard libraries | Actual free clip list; rig names/rest pose; prop contact; in-place option; avoid packs advertising only paid clips |
| 2 | Grapple hold/reel/release, controlled landings, dry ledge grab, swim rise/dive/stop | Broadens motion where the existing inventory identifies gaps; verify against later authored player work before collecting duplicates | Clean source motion and editable rig, no forced forward motion; avoid another generic walk/run-only set |
| 2 | Ribbon/cloth-strip meshes and small-joint baked cloth rigs; graphic seamless fabric/stitched trim materials | Staff ribbons and woven identity need more than metallic blue crystals or generic skin textures | Non-photoreal detail at game scale, editable UVs, loop behavior, no mandatory runtime simulation |
| 3 | Fish/bird/turtle source anatomy and locomotion matching approved concepts | More relevant than collecting additional unrelated fantasy species | Usable rigs/weights and actual clips, species-neutral adaptation potential, license evidence |

Prefer small missing pieces over more bulk packs. Keep original download page
URL, creator, license, archive hash and intended role together for future batches.
Do not buy full editions until a specific missing mesh/clip is confirmed useful.

## Suggested next decision and validation boundary

After current stabilization, propose one isolated reuse trial: one clothed NPC
with one work/talk clip, or a sword/shield silhouette comparison on a duplicate
character. List exact files and adaptation before protected asset replacement.
For any selected import, copy only its model, required BIN/textures, license and
provenance; check all external glTF dependencies and keep duplicate engine
exports out. Validate scale, pivots, materials, bones and motion in an isolated
project before approval to install. Record gameplay-scale screenshots and motion
review; only then assess frame cost and gameplay regression for the affected area.

**Pre-import issue found in P13:** `Superhero_Female_FullBody.gltf` references
missing `T_Eye_Normal_png.png`. `Superhero_Male_FullBody.gltf` references missing
`T_Hair_1_Normal_png.png` and `T_Eye_Normal_png.png`. The archive contains similarly
named `T_Eye_Normal.png` and `T_Hair_1_Normal.png`; compare those maps and relink
them on an extracted working copy before a trial. Original archives remain intact.
All other inspected external glTF dependencies resolve to archive members.
These three missing references are recorded in each affected model's
`missing_dependencies` field. Successful ZIP reads do not guarantee a clean import.

This audit verified ZIP integrity, file counts, hashes, glTF JSON structures,
triangle counts, skin joint names, clip names, included documentation and selected
supplied preview images. Dependency inspection found the three P13 references
above. It did **not** run a Godot import, retarget animations,
test FBX/BLEND files, audition audio, accept visuals or change runtime content.
The reusable scanner is `tools/assets/inventory_downloads.py`; it reads archives
without executing their contents and extracts only preview/document evidence.

Checkpoint: `docs: inventory downloaded asset library and reuse candidates`.
The work-list entry records this audit as complete; proposed imports remain open.
