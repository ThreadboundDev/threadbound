# Blue Chamber Exit / Rooftops — Codex Experimental Pass

This log covers only the removable experimental room at
`Src/Environment/BlueBiome/Prototypes/Experiments/blue_chamber_exit_rooftops_codex_pass.tscn`.
The original room remains the authority until this pass is approved.

## 2026-08-24 — Pass 01: Layer Foundation

- Duplicated the authored chamber-exit room into an isolated experiment.
- Kept the existing collision layout as the starting gameplay authority.
- Added a far-far vista concept: pale cliffs, dry waterfall face, and a small
  still-lake reveal reserved for the upper-right composition.
- Added a distant village concept with irregular warm-wood buildings, curved
  roofs, broad cherry-blossom masses, and lower contrast than gameplay forms.
- Added a near silhouette concept using dark slate roofs, trees, hanging cloth,
  reeds, and large central negative space for traversal readability.
- Added a transparent native vegetation strip for gameplay-adjacent dressing.
- Added `blue_native_wind.gdshader`: two-frequency base sway, planted roots,
  per-strip phase variation, and a narrow periodic gust envelope.
- Rejected an initial near-silhouette export because it baked its transparency
  checkerboard into RGB. Kept the composition through a controlled green-key
  source and deterministic chroma-key CanvasItem shader instead.
- Added a continuous blue-slate atmosphere fill after the first live render
  exposed background gaps.
- Disabled the overpowering near and foreground silhouette mockups after live
  inspection; they remain available for a later selective edge-framing pass.
- Corrected parallax repeat spacing to the source texture width and softened
  the village layer so gameplay geometry remains the strongest value group.
- Replaced the repeated painted vistas with single oversized layers after a
  second live review exposed visible tonal seams between generated edges.
- Audited the authored collision route at spawn, the central chamber, and the
  upper-right exit. The route geometry was intentionally preserved; this pass
  adds landmarking and motion without rewriting the authored jumps.
- Live Godot check: current-run game log contained no errors, the experimental
  room sustained roughly 145 FPS during inspection, and no core player values
  were changed by this art pass.
- No core player, combat, equipment, progression, or camera scripts changed.

## Revert Scope

Remove the experimental scene, this changelog, and
`Assets/BlueBiome/Prototype/CodexPass/`. No approved source asset is replaced.

## 2026-08-24 — Pass 02: Full-Room Paint-Over Workflow

- Replaced the camera-sized backdrop test with three room-scale panorama
  districts: chamber-side village, dense central rooftops, and the lake
  overlook. Together they cover the authored route from left to right.
- Added soft edge blending between panorama panels so generated edge values do
  not read as hard vertical seams.
- Added a transparent rooftop/stone paint-over sheet and aligned selected
  modules to the existing greybox platforms. The TileMap remains the collision
  authority; its experimental visual opacity is reduced to make that separation
  obvious while editing.
- Added four independently placed cherry-blossom elements plus the earlier
  grasses and reeds. Trees use a restrained native sway; grasses retain broader
  irregular sway and stronger occasional gusts.
- Added an experimental opaque water material informed by the linked Ghibli
  water devlog reference: vertical color depth, softly broken horizontal ripple
  bands, restrained reflections, surface glints, and gust-driven variation.
  No third-party code or assets were copied.
- Kept player movement, swim depth, collision shapes, platform positions,
  hazards, combat, equipment, progression, and the original room unchanged.
- Live checks covered spawn, central rooftops, lake overlook, and the main water
  volume. Greybox collision remained enabled, the current-run log was clean,
  and the scene ran at roughly 145 FPS during inspection.

## 2026-08-24 — Pass 03: Free-Place Building Library

- Added four complete collision-free building families: wide house, narrow
  tower, lakeside stilt house, and open pavilion.
- Preserved original dark-field renders beside flat-green keyed production
  copies. Godot removes the key through the existing chroma material; the
  uniform key also provides a simpler cleanup target in Krita than the earlier
  baked gradients.
- Anchored building scene origins to their roof line. Selecting a gameplay roof
  and adding a building now places the facade downward beneath that surface.
- Added freely positioned medium/long roof skins, stone ground, wind grass,
  wind-shaped cherry tree, and cherry shrub scenes. None contains collision.
- Extended the Room Greybox dock with building and free-place art rows. Art is
  created under `ArtPlaceables`, never snaps, and begins at the selected 2D
  object's global position.
- Added Strong/Faint collision-preview controls using editor undo. They change
  only the visible opacity of terrain and large blocks; collision stays active.
- Verified all ten placeable scenes load and contain zero collision nodes. A
  live building alignment check confirmed clean chroma removal and correct
  facade-under-roof anchoring.

## 2026-08-24 — Pass 04: Hybrid Ground, Platforms, and House Depth

- Added a decorative 128 px Blue ground atlas with four surface-cap and four
  stone-fill variants. Warm-neutral slate, green growth, and restrained pink
  blossom flecks keep the gameplay ground from becoming a repetitive blue wall.
- Added Room Greybox controls to create/select the collision-free ground-art
  layer or regenerate it from the current `GreyboxTerrain` silhouette. Surface
  and fill selection is automatic; the result remains directly editable.
- Added short and long modular wood platforms with thin one-way landing
  collision and separate grapple target areas. These are explicit gameplay
  placeables rather than collision baked into an entire house illustration.
- Added collision-free railings, posts, braces, hanging cloth, rope-bridge art,
  and a high-Z foreground house frame for assembling layered interiors around
  the player.
- Added free-place left- and right-rising greybox slopes with full grapple
  coverage. No player movement values or slope-specific motion rules changed.
- Preserved the generated village platform kit in both its original dark-field
  source and production chroma-key copy for later Krita cleanup.

## 2026-08-25 — Pass 05: Scene Tree Cleanup and Combat HUD

- Reduced `Geometry` to terrain and the temporary starter floor, then moved all
  water volumes and hazards into their existing dedicated root containers.
- Replaced automatic Area2D names with location-based labels such as
  `WestUpperWater`, `LakeOverlookWater`, and `ChamberExitHazard`.
- Renamed `CodexVisualLayers` to `EnvironmentArt` and grouped its contents by
  rendering purpose: far background, background, gameplay surfaces, buildings,
  vegetation, and foreground.
- Renamed the panorama panels `ChamberSideVillage`, `CentralRooftops`, and
  `LakeOverlook` to match the Blue macro-map language used during greyboxing.
- Added the production `CombatHUD` under a layer-80 `HUD` CanvasLayer so health,
  action points, momentum, and the existing combat displays are visible while
  testing this room.
- Preserved gameplay transforms, collision settings, player behavior, and art
  layering during the reorganization.

## 2026-08-25 — Pass 06: Seamless Building Cutaway Prototype

- Added a reusable building cutaway controller that detects the player inside
  an authored zone, fades the exterior shell, reveals the interior, and adds a
  localized warm-light layer without modifying player or camera behavior.
- Added a separated lakeside-house interior with a broad lower gameplay strip,
  loft, ladder, storage, textile details, and warm practical lighting.
- Kept a dedicated foreground architectural frame above the player so entering
  reads as occupying the building rather than walking in front of another flat
  background image.
- Replaced the experimental stilt-house sprite with the reusable cutaway scene
  at the same transform. Existing world collision remains authoritative.
- Added a north-star comparison document capturing presentation lessons from
  Castlevania: Belmont's Curse while preserving Threadbound's distinct focus on
  momentum, grapple, pogo, AP routing, water traversal, and player expression.

## 2026-08-25 — Pass 07: Threadglass Hazard Kit

- Added a five-piece regional Threadglass hazard sheet with floor, wall,
  hanging, waterline, and bright-crowned pogo silhouettes.
- Preserved the original dark-field concept sheet beside the production sheet
  for later paint cleanup or variant extraction. Because repeated extraction
  returned a baked neutral checker field rather than genuine alpha, the Godot
  scenes use a dedicated bright-neutral key shader while preserving saturated
  cyan blades and coral warning edges.
- Built five free-place hazard scenes on top of the existing greybox hazard
  implementation. Damage, retrigger timing, knockback, and pogo reception are
  shared with the established system rather than duplicated.
- Added per-variant knockback direction and collision dimensions appropriate to
  floor, wall, hanging, waterline, and vertical pogo placements.
- Added a `debug_draw_enabled` presentation switch to greybox hazards so final
  regional art can hide the red prototype rectangle without disabling physics.
- Extended the Room Greybox panel with direct buttons for all five Threadglass
  variants.

## 2026-08-26 — Pass 08: Authoring Library Cleanup

- Sorted reusable art scenes into explicit Buildings, Ground, Platforms,
  Surfaces, and Vegetation folders while keeping gameplay buildings, hazards,
  clean room shells, experiments, and references separate.
- Updated every Room Greybox placement path to the categorized scene library.
- Added Blue Biome README files and a compact asset index describing where each
  kind of room-building resource lives and whether it owns collision.
- Removed the painted pool portion from the waterline Threadglass crop. The
  hazard now supplies only reeds/glass and collision, allowing live animated
  water to remain the single water presentation layer.
- Extended hazard verification with a guard that prevents the waterline crop
  from extending back into the illustrated static water.

## 2026-08-26 — Pass 09: Tall Layered Background

- Restored the intended two-stage background: a bright distant mountain/lake
  vista underneath the transparent lakeside-village silhouette.
- Added a square, vertically extended vista with real sky above and descending
  mountain depth below, avoiding vertical image repetition during camera travel.
- Configured the transparent village to repeat horizontally only. Buildings do
  not tile vertically, while the far vista remains a single non-repeating plate.
- Retained the dense three-panel village panorama in the scene as a disabled
  alternate layer so it can be compared or reused without replacing assets.

## 2026-08-26 — Pass 10: Far-Background Isolation

- Removed all previously placed roofs, collision skins, houses, vegetation,
  and foreground dressing from the experimental room while preserving their
  reusable source scenes and assets.
- Hid the HUD by default while keeping it at the room root and ready for later
  gameplay testing.
- Isolated the active art pass to a light sky fill, vertically complete
  mountain/lake vista, and a separate alpha-backed cloud bank.
- Added slow independent horizontal cloud movement and shallow parallax. The
  distant vista and clouds repeat horizontally only and never vertically.
- Hid the village and alternate panorama group for the next layer pass. The
  village's real art pixels are now full opacity; only its negative space uses
  transparency.
- Recorded open-air value, alpha, filtering, and layering rules in the Blue
  Biome direction document.

## 2026-08-26 — Pass 11: Landmark-Aligned Vista and Cloud Kit

- Removed all repetition from the landmark-bearing mountain/lake vista to
  eliminate hard seams and duplicate lakes.
- Scaled the single vista to cover the full room and aligned its painted lake
  with the authored `Lake Glimpse` marker at the upper-right of the greybox.
- Preserved the designer-authored far-background and cloud scroll offsets.
- Replaced the single moving cloud sheet with five reusable atlas-backed cloud
  scenes. Six independently transformed instances now occupy two shallow
  parallax depths, including coverage two grid cells above the former row.
- Added per-cloud drift speed and horizontal wrapping so clouds can be freely
  placed, scaled, mirrored, and slightly rotated throughout the Blue region.

## 2026-08-26 — Pass 12: Krita Cloud Atlas Integration

- Updated every cloud variant to the designer-recut `6800×1750` Krita atlas,
  respecting its six-column, three-row transparent cell layout.
- Expanded the reusable library to eight variants spanning broad banks, wisps,
  towers, clusters, streaks, puffs, and small distant forms.
- Populated the chamber sky with independently scaled, mirrored, rotated, and
  phase-offset instances across high and middle parallax depths.
- Added restrained continuous drift, slow vertical float, horizontal wrapping,
  and a low-amplitude UV billow shader. Cloud color remains authored texture
  color; the material applies no blanket blue tint.

## 2026-08-26 — Pass 13: Room-Bound Cloud Recomposition

- Rebuilt both active cloud bands from scratch around the designer-authored
  `7467×4220` cloud coverage guide centered at `(546.5, -419)`.
- Replaced the former ten placements with twelve far and twelve middle-depth
  placements distributed across the complete playable room envelope.
- Varied silhouettes, scale, mirroring, rotation, drift, and motion phase while
  reserving clearer negative space around the upper-right lake glimpse.
- Tightened the atmosphere polygon to the coverage guide. Preserved the
  landmark-aligned far vista because sprite scale changes draw size but not the
  source texture's memory footprint.
- All cloud instances continue sharing one imported atlas texture rather than
  loading duplicate source images.

## 2026-08-26 — Pass 14: Exact Cloud Cell Correction

- Corrected all eight cloud atlas regions from an incorrect equal division of
  the full PNG canvas to the designer-authored contiguous `1024×512` cells.
- The cloud grid now uses exact `1024`-pixel horizontal and `512`-pixel vertical
  offsets; unused canvas space is excluded from every placed cloud.
- Extended the automated cloud verifier to assert every exact source rectangle
  and cell alignment so canvas dimensions cannot be mistaken for cell size
  again.

## 2026-08-26 — Pass 15: Standalone High-Resolution Grass Family

- Began replacing vegetation atlases with individual transparent assets built
  at high resolution for free placement and safe per-instance scaling.
- Added short, medium wind-grass, and tall fountain-grass silhouettes with
  natural green dominance, cool Blue Biome shadows, and warm daylight accents.
- Added bottom-anchored reusable placeable scenes with deliberately different
  idle sway, gust strength, speed, and phase settings.
- Preserved the former vegetation sheets as legacy references; no existing
  room placements were replaced during this asset-library pass.

## 2026-08-26 — Pass 16: Standalone Flower Family

- Added three individual high-resolution transparent flower assets: a low pink
  blossom bed, a medium airy wildflower, and a tall bell-flower accent.
- Kept foliage naturally green and used controlled cherry pink, coral, cream,
  and cool shadow values to support rather than overwhelm the Blue palette.
- Added independently placeable, bottom-anchored scenes with progressively
  stronger wind response for low, medium, and tall silhouettes.
- Expanded vegetation verification to cover all standalone grass and flower
  scenes, their source resolution, materials, and ground registration.

## 2026-08-26 — Pass 17: Layered Reflective Water Prototype

- Added a reusable reflective water presentation layer that automatically
  follows the dimensions of its parent `GreyboxWater2D` volume.
- Implemented continuous screen-space scene reflection, horizontal-only blur,
  a Blue Biome vertical gradient, silhouette reduction, retained light values,
  interior breakup, edge distortion, and animated surface glints.
- Replaced the two manually sized painted rectangles in the experimental room
  and gave all three authored water volumes the same reusable visual treatment.
- Kept water collision, surface height, player concealment, jumping, and swim
  behavior under the existing greybox water implementation.
- Added focused verification for water sizing, shader features, and all three
  room integrations.

## 2026-08-26 — Pass 18: Standalone High-Resolution Tree Family

- Added three individual transparent tree assets: a young cherry tree, a broad
  mature cherry landmark, and a shoreline willow.
- Added bottom-anchored free-placeable scenes with defaults sized for gameplay
  composition while retaining substantial source resolution for variation.
- Introduced a tree-specific wind shader that locks the root and lower trunk,
  minimizes motion through the crown center, and concentrates subtle sway and
  occasional gust movement toward the outer foliage.
- Expanded vegetation verification to include all three tree scenes alongside
  the grass and flower families.

## 2026-08-26 — Pass 19: Individual Cloud Texture Migration

- Replaced every remaining cloud atlas region with a direct reference to one
  of the designer-exported individual cloud PNGs.
- Selected eight complete silhouettes from the eighteen exports and excluded
  empty cells and visibly clipped edge fragments.
- Preserved all existing named cloud scenes, room placements, parallax depths,
  drift settings, phase variation, scaling, mirroring, and billow materials.
- Reworked cloud verification to forbid `AtlasTexture`, assert the individual
  `1133×583` source dimensions, and validate every intended texture mapping.

## 2026-08-26 — Pass 20: Room-Bound Far Vista Height

- Limited the far-vista sprite to a centered `1254×674` display region while
  preserving its established seven-times horizontal scale and lake alignment.
- Reduced the displayed height from `8778` to `4718` world pixels, covering the
  `4220`-pixel Area2D guide with approximately `249` pixels of vertical padding
  on each side.
- Preserved the original square source texture and image proportions; no
  vertical squashing or landmark relocation was introduced.

## 2026-08-26 — Pass 21: Deterministic 1024×512 Cloud Split

- Replaced Krita's incorrect equal-canvas split with deterministic crops at the
  authored `1024×512` guide intervals: six columns by three rows from `(0, 0)`.
- Saved all eighteen transparent cells under `Art/Clouds/Individual1024` and
  classified them by actual alpha bounds.
- Mapped the eight reusable cloud scenes only to complete, padded cells; cells
  with artwork touching a crop edge and empty cells remain unused.
- Extended verification to assert exact texture size and reject any selected
  cloud whose nontransparent pixels touch a source-image boundary.

## 2026-08-26 — Pass 22: Hand-Composed Cloud Organization

- Preserved the designer's sixteen saved cloud positions while organizing them
  into clearly named `FarClouds` and `MidClouds` parallax groups.
- Renamed every instance by depth, room location, and silhouette instead of
  retaining generic numeric placement names.
- Added distinct billow amount, billow speed, vertical float, drift, phase,
  scale, mirroring, and minor rotation profiles across the composition.
- Expanded verification to assert both organized depth groups, all sixteen
  placements, descriptive naming, and unique motion phases.
