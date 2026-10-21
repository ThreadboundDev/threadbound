# Matching bridges and balconies from existing stamps

Prepared October 21, 2026 at baseline `f94f9b17`. Chase requested the bridges
and balconies used as Krita stamps because the current small bridge does not
match. Source/reference preparation is complete; installing replacements or
restructuring the room awaits approval under `AGENTS.md`.

## Evidence and recommendation

The current consolidated Slate Library supplies A04 Engawa Landing, B04 Simple
Plank Crossing, J03 Japanese Veranda, J04 Matched Broken Bridge and T01 Rock
Timber Landing. Its source README identifies this as the active kit, superseding
the historical stamp folders. Source copies and the original visual catalog
are saved under `ArtSource/BlueBiome/Placeables/WalkwayStamps/` with hashes and
provenance. No generation, image edits or game replacements were performed.

The active Krita playtest uses nine `Geometry/BridgeLandings/Deck01..Deck09`
sprites, all selecting `Assets/BlueBiome/Art/LakesideMap/walking_deck.png`.
That image comes from D01 Deck Edge in the construction kit. Instances have
different horizontal and vertical scales, so the same timber details change
proportion between spans. The older `platform_rope_bridge.tscn` is a separate
atlas/chroma-key placeable and is not the nine-sprite map setup.

**Recommend 2D first.** The saved stamps already supply the desired silhouettes,
weathered timber, rails and supports for the painted village. Reusable 2D
objects give a direct style comparison at normal player scale. Reserve a 3D
rebuild for a later explicit decision if the in-game comparison shows a need
for shared building lighting/depth; it is a separate art scope.

## Proposed integration

- Make reusable simple crossing, railed veranda, balcony/engawa and broken-pair
  art prefabs. Keep the rock-attached landing as a saved reference for now.
- Use the original stamp pixels. Preserve the scale of end posts, rails and
  braces; fit different lengths with fixed ends and repeated middle sections.
  Author source regions/anchors using Godot texture regions and scene data,
  without generating replacement images or stretching an entire stamp unevenly.
- Align each art object's walk-plane anchor to its existing one-way landing.
  Audit the current nine sprite/collision pairs first, because several were
  manually repositioned. Match current collision spans and route positions;
  do not silently move gameplay geometry to fit an image.
- Replace the repeated deck-edge visuals with the appropriate intact crossing
  or veranda presentation. Use a balcony where it is visibly attached to a
  building/rock. Expose the art type/length for later editor adjustment.
- Preserve current one-way collision polygons, margins, span widths, gaps and
  collision layers. The initial prefabs own artwork and a walk-plane anchor;
  the existing room continues to own physics. Do not add a second collider.
- Keep the broken-pair prefab available for later placement. Do not create a
  new broken route, invisible bridge or new gap during this visual correction.
- Place rails behind the player and keep visible feet aligned with the deck.
  Compare the result beside the current 3D houses and painted terrain in both
  daylight and dusk before accepting the visual match.
- Keep the old deck image and older rope-bridge source intact for historical
  references. This request does not replace other rooms' approved art.

## File scope for approval

Paths are relative to the repository root. New PNG `.import` sidecars and script
UID files are explicitly included. Runtime files are limited to this source kit
and the Krita playtest; no player, combat, equipment or house-door code changes.

1. `.gitattributes` (LFS for the new runtime source copies)
2. `Assets/BlueBiome/Art/WalkwayStamps/A04_Japanese_Engawa_Landing.png` (new)
3. `Assets/BlueBiome/Art/WalkwayStamps/A04_Japanese_Engawa_Landing.png.import` (new)
4. `Assets/BlueBiome/Art/WalkwayStamps/B04_Simple_Plank_Crossing.png` (new)
5. `Assets/BlueBiome/Art/WalkwayStamps/B04_Simple_Plank_Crossing.png.import` (new)
6. `Assets/BlueBiome/Art/WalkwayStamps/J03_Japanese_Veranda.png` (new)
7. `Assets/BlueBiome/Art/WalkwayStamps/J03_Japanese_Veranda.png.import` (new)
8. `Assets/BlueBiome/Art/WalkwayStamps/J04_Matched_Broken_Bridge.png` (new)
9. `Assets/BlueBiome/Art/WalkwayStamps/J04_Matched_Broken_Bridge.png.import` (new)
10. `Assets/BlueBiome/Art/WalkwayStamps/provenance.json` (new)
11. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/walkway_stamp_2d.gd` (new)
12. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/walkway_stamp_2d.gd.uid` (new)
13. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/plank_crossing_2d.tscn` (new)
14. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/railed_veranda_2d.tscn` (new)
15. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/engawa_balcony_2d.tscn` (new)
16. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/broken_timber_bridge_2d.tscn` (new)
17. `Src/Environment/BlueBiome/ArtPlaceables/Platforms/README.md` (new)
18. `Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
19. `tools/environment/verify_lakeside_walkways.gd` (new)
20. `tools/environment/verify_lakeside_walkways.gd.uid` (new)
21. `docs/design/lakeside_walkway_stamp_proposal.md` (approval/delivery record)
22. `docs/project_status_and_worklist.md`
23. `docs/next_test_session.md`

If the asset audit shows that a different architecture or additional runtime
files are necessary, revise the proposal before expanding the implementation.

## Verification and commit checkpoints

Source preparation: compare all six copied PNGs byte for byte with the active
library; record dimensions, alpha ranges and checksums; commit/push the source
pack and proposal without replacing any live assets. This is the current step.

After approval: verify each prefab's anchor/span and repeated sections, ensure
current collision vertices/margins/layers and authored gaps are unchanged, and
exercise real player landing/walking at representative narrow/wide spans.
Rerun relevant map/house/encounter checks if integration touches their route.
Headless checks cannot accept the image seams, proportions, layering or lighting;
Chase's visible review does that.

Implementation commit subject: `art: integrate matching village walkway stamps`.
Push and confirm remote HEAD before starting another art direction. T01/T02
house review remains pending; this scoped request does not reopen general art
production or approve a 3D rebuild.
