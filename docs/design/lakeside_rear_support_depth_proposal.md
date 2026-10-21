# Restore the separate Krita wood support layer

October 21, 2026; inspected baseline `7531cbdf`, proposal saved as `bec89e67`.
**Chase approved this scope; implementation is complete, visible review pending.**
Chase reports that background beams/pillars read as gameplay until the player
passes through them. He clarified that Cave Walls and Under Cave Mouth may
remain together; wood must be separate, or become separate Godot objects.

## Confirmed cause

The saved source KRA contains `STAMP REAR SUPPORTS` (`layer20`) separately below
`Cave Walls` and `Under Cave Mouth` (`layer18`/`layer19`). Its SHA-256 still
matches the imported manifest:
`41ee10a00fb3339bf4fb21f40a904b2607e11ef70e2ba487944f41a5c1dd9f44`.
The archived XML also matches the current source exactly.

`work/krita-map-import/extract_map.py` flattened all three into `rear_cave`.
The Godot scene draws that combined group at z=-6, so the supports cannot
receive a separate depth treatment. Their collision exclusion was preserved:
`prepare_rock_mask.py` deliberately excludes `layer20`. This is a visual import
problem, not a request to make those beams solid.

## Approved result

- Keep Cave Walls and Under Cave Mouth combined in `rear_cave`, at z=-6.
- Extract only the original wood support layer into `rear_supports`, at z=-7.
  Keep exact 1:1 pixel positions and alpha. Both remain behind the player.
- Give only the wood a shared, tunable canvas shader/material: lower saturation
  and local contrast with a restrained cool atmospheric tint. Keep it opaque
  and retain sharp source contours. Initial values are a review starting point;
  accept the result beside the playable rocks and timber walkways in daylight
  and dusk.
- Use a separate art group rather than manually reconstructing each beam as an
  independent object. This restores the authored layer and supports one place
  to adjust its appearance. Individual editable beams can be a later request.
- Preserve all cave rock placement, playable timber platforms, physics, house
  doors, water, enemies and current room edits. No parallax is needed for this
  correction; structural connections should stay aligned.

## Exact implementation file scope

Paths below are relative to the repository root. This file list was saved
before runtime changes and approved by Chase before implementation.

1. `work/krita-map-import/extract_map.py`: retain the wood as a separate export;
   add a scoped update mode so unrelated map/source exports are preserved.
2. `work/krita-map-import/assemble_scene.py`: support the extra art group and an
   artwork-only mode. **Do not regenerate the main playable room**, which would
   overwrite subsequent house/layout/walkway work.
3. `Assets/BlueBiome/Art/LakesideMap/map_manifest.json`: source-layer mapping and
   independent support chunks; retain the other groups/coordinates.
4. `Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_krita_artwork.tscn`:
   independent wood group, source sprites and shared filter material.
5. `Src/Environment/BlueBiome/ArtPlaceables/Background/rear_support_depth.gdshader`
   and its `.gdshader.uid` (new).
6. `Src/Environment/BlueBiome/ArtPlaceables/Background/rear_support_depth.tres`
   (new; tunable shared ShaderMaterial).
7. `tools/environment/verify_lakeside_krita.gd`: check layer separation, correct
   material ownership and ordering while retaining existing map assertions.
8. This proposal, `docs/project_status_and_worklist.md` and
   `docs/next_test_session.md`: approval, delivery evidence and short visual test.

Texture scope is the following 15 tile coordinates. For **each row**, the exact
new filename is `Assets/BlueBiome/Art/LakesideMap/rear_supports_<tile>.png` and
its `.png.import`; the existing combined filename
`Assets/BlueBiome/Art/LakesideMap/rear_cave_<tile>.png` may be re-exported without
wood, along with its existing `.png.import` if needed. Preserve source UIDs on
existing files. Rock chunks with no remaining rock pixels leave the live
manifest; no unrelated source art is deleted. Other rear/terrain chunks stay
unchanged.

| Tile |
|---|
| 05_00 |
| 06_00 |
| 06_01 |
| 00_02 |
| 01_02 |
| 05_02 |
| 06_02 |
| 00_03 |
| 00_04 |
| 05_04 |
| 06_04 |
| 03_05 |
| 04_05 |
| 05_05 |
| 06_05 |

Existing `.gitattributes` already covers these runtime PNGs with LFS. No new
asset generation, KRA modification, collision rebuild or playable room scene
rewrite is included. Temporary import caches/logs/previews belong under ignored
`tmp/rear_supports/`, not new tracked delivery files.

## Verification and Git checkpoint

Recompose the separated unfiltered layers and compare with the previous source
projection, including overlap/alpha at rock edges. Verify the source SHA and
unchanged chunk hashes outside this scope. Check Godot chunk coordinates,
filter ownership, draw order, and that rock/walkway collision data and the main
room scene are unchanged. Rerun map, walkway and house-entry fixtures; inspect
success markers and errors, not exit code alone. Retain historical tracked
reports; save current logs separately.

Chase's visible review accepts the strength of the depth filter and whether
beams clearly read as background before the player reaches them. Automated
checks cannot decide that. Existing house and walkway acceptance remains open.

Commit/push the approved coherent correction as
`fix: separate background timber from lakeside rock art`; confirm remote HEAD
before starting another task. This document is the reviewable scope required
by `AGENTS.md` before scene restructuring and asset replacement.

## Delivery and results — October 21, 2026

The original `STAMP REAR SUPPORTS` pixels now draw in their own `rear_supports`
group at z=-7. Cave Walls plus Under Cave Mouth remain combined in `rear_cave`
at z=-6. There are **15 wood chunks and 32 rock chunks** (56 painted chunks
total, including the unchanged terrain). Exactly 15 existing PNGs were updated
to remove the wood; their import settings and UIDs are unchanged. The other
existing textures and import files are byte-identical to the baseline.

Only the wood sprites inherit `rear_support_depth.tres`. Initial shader values:
saturation **0.45**, contrast **0.65**, haze amount **0.28**, cool haze color
**(0.10, 0.19, 0.26)**. Texture alpha and sharp outlines are retained. Tune the
shared material on `Geometry/TerrainArtwork/rear_supports` under **Material >
Shader Parameters**. The rock art and playable wooden platforms use their
existing materials.

For future scoped re-extraction, from the repository root use the project's
Python runtime with:

```text
work/krita-map-import/extract_map.py --rear-supports-only
work/krita-map-import/assemble_scene.py --artwork-only
```

The extractor verifies the source SHA before a scoped update and validates
recomposition before replacing files. The assembler requires an explicit mode
and rejects missing/misspelled modes. `--rebuild-legacy-room` is retained only
as an explicit legacy operation: it overwrites subsequent authored room work
and needs separate scope/review. It was **not run** for this correction.

Validation on Godot 4.7.2 Mono, with isolated saves/logs under ignored
`tmp/rear_supports/`:

- Recombined unfiltered wood/rock matches the original source within **one
  8-bit channel value**, with zero pixels exceeding the two-value tolerance.
  Both full extraction and scoped extraction now retain the separate layer.
- Scoped extraction and artwork-only assembly were repeated: all outputs were
  byte-for-byte identical. Missing/misspelled assembly flags fail without
  modifying the room. The retained source KRA was not modified.
- SHA-256 audit: main playable room, rock collision scene, collision mask,
  unrelated textures and all existing import sidecars are unchanged. The nine
  fitted walkway instances and house-entry work remain intact.
- Map fixture passed: 56 correctly positioned chunks; material ownership/draw
  order; **9,871** rock physics samples with **zero mismatches**; original house
  floors, water and dry-pocket behavior still pass.
- **405 house-entry** and **606 walkway** checks passed, including real player
  landings/walking on all nine spans. Logs contain the explicit success markers
  and no parse/script errors. Historical tracked reports were preserved.
- The connected editor's shader compiler validated the canvas shader: **valid,
  four uniforms, no errors or warnings**, without changing editor state.

Headless runs still emit the previously recorded equipment/audio shutdown
resource diagnostics; their investigation remains T04. The shader parse check
does not establish rendered appearance. **Chase's daylight/dusk visual review
is pending**, especially whether the supports read as background before contact.
Use the short T14 retest in `docs/next_test_session.md`. Commit subject:
`fix: separate background timber from lakeside rock art`; exact hash in Git log.
