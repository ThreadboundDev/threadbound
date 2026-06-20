# Threadbound Visual Readability Art Pass

## Core Philosophy

Threadbound uses graphic silhouettes with clean illustrated rendering.

Readability is the highest priority. If rendering detail conflicts with gameplay readability, choose readability.

Threadbound should feel elegant, ancient, woven, and above all readable.

## Readability Rules

- Silhouette is always more important than texture.
- Every asset should be immediately readable from gameplay distance before internal details are visible.
- Use minimal visual noise and sharper silhouettes.
- Large forms should remain visible even when zoomed out.
- Shading and texture detail should support broad form, material, and age. They should not define the object.

## Rendering Rules

- Rendering should feel hand-drawn and shape-based.
- Rendering should never destroy readability.
- Avoid excessive texture noise, photorealistic stone surfaces, and busy surface detail.
- Use broad value shapes, controlled highlights, subtle color variation, and restrained wear/aging.

## Platform Rules

- Gameplay platforms are gameplay shapes first, not realistic stone blocks.
- The top edge is the most important area.
- Prioritize clean collision readability, strong silhouette, and clear platform boundaries.
- Players read edges. Players do not read repeated texture patterns.
- Platform centers should remain calm and minimally detailed.
- Use shadow gradients, dark fades, and simplified surfaces instead of noisy center detail.

## Chamber Lighting Direction

The Chamber of the First Weave should read as an underground space with a clear hierarchy between playable elements and decorative depth layers.

- Primary light enters from the top-center world opening.
- Gameplay platforms, the player, enemies, and interactables remain the highest-contrast elements.
- Far-background architecture should be lighter, lower contrast, and less saturated than gameplay tiles.
- Midground architecture may retain more form and texture, but it should not compete with traversal silhouettes.
- Decorative foreground silhouettes should frame the view without obscuring or mimicking platforms.
- Character readability takes priority over atmospheric darkness.

Future lighting and shader work should focus on:

- screen-space cave atmosphere and edge falloff
- stronger foreground/background separation
- subtle thread-themed glow and motion accents
- restrained local player light that supports readability
- material presets for far, mid, gameplay, and foreground layers

## Architectural Language

Do not create generic fantasy ruins.

Threadbound architecture should feel like a civilization built around weaving reality: a weaving machine mistaken for a cathedral.

Borrow from:

- Looms
- Spindles
- Tension structures
- Rings
- Weaving frames
- Thread channels
- Sacred machinery

Examples:

- Loom-rings instead of stained-glass windows
- Spindle towers instead of castle towers
- Thread channels running through stone
- Massive tension structures supporting ruins
- Floating architecture suspended by woven forces

## Color Rules

- Use restrained color.
- Most architecture should remain bronze, stone, ivory, weathered gold, and dark slate.
- Thread energy provides color accents.
- Red, blue, and yellow should feel precious.
- Color should guide attention.
- Never flood the screen with saturation.

## Density Rules

- The world should feel ancient and layered.
- Use arches, ruins, floating structures, pillars, and thread formations to create depth.
- Avoid clutter.
- Every asset should have room to breathe.
- Players should see large shapes first.
- Details should emerge naturally after the big read.

## Initial Asset Audit

### Highest Priority: Chamber Gameplay Tiles

Files:

- `Assets/chamber_of_first_weave/Tiles/cotfw_chamber_tileset_atlas_128_current.png`
- `Assets/chamber_of_first_weave/Tiles/cotfw_chamber_tileset_atlas_256_current.png`
- `Assets/chamber_of_first_weave/Tiles/platform_left.png`
- `Assets/chamber_of_first_weave/Tiles/platform_center.png`
- `Assets/chamber_of_first_weave/Tiles/platform_right.png`

Current issue:

The architectural borders read well, but stone and moss centers are too noisy. The center fill texture competes with the platform boundary. Grass edges also have too much micro-chatter for gameplay scale.

Pass direction:

- Preserve strong bronze frame language.
- Simplify stone centers into broad value masses.
- Darken/de-emphasize center fill detail.
- Keep top edge clearer and more continuous.
- Reduce tiny moss/grass spikes unless they reinforce the outer silhouette.

### High Priority: Threadling Enemy

Files:

- `Assets/The Frayed/threadlin_idleright.png`
- `Assets/The Frayed/threadling_attackright.png`
- `Src/Enemies/Threadling/threadling.tscn`

Current issue:

The creature concept has a clear wrapped-head/glowing-eye silhouette, but it is still stored as a large sheet and includes many repeated frames. The smoky tail and wispy edges may disappear or fuzz out at gameplay scale.

Pass direction:

- Extract clean single-frame idle and attack assets for the current scene.
- Strengthen the wrapped head and glowing eye silhouette.
- Simplify the smoky tail into one larger readable trailing mass.
- Keep attack beam shape clean and high-readability.

### High Priority: Player Keyframes

Files:

- `Assets/Threadborne/Player_Normalized_V1/*.png`
- `Assets/Threadborne/Run/*.png`
- `Assets/Threadborne/Equipment/Weavers_Shuttle_Club.png`
- `Assets/Threadborne/Equipment/Weavers_Shuttle_Club_Smear.png`

Current issue:

The normalized jump/grapple frames are more consistent than the originals, but internal clothing folds and leg/boot rendering details are close to overpowering the gameplay silhouette. The weapon is readable but should stay small and simple.

Pass direction:

- Preserve pose and proportions.
- Strengthen outer silhouette and head/body separation.
- Reduce internal clothing texture contrast.
- Keep face/head and boots readable at gameplay scale.
- Keep weapon/smear chunky and readable rather than ornate.

### Medium Priority: HUD Assets

Files:

- `Assets/UI/Momentum+Action Points.png`
- `Assets/UI/health_bar_game_asset.png`
- `Src/UI/combat_hud.tscn`

Current issue:

The action point UI strongly fits the elegant/woven/ancient direction, but the fine thread lattice may shimmer or become visual noise at HUD scale. The health bar concept is too ornate and high-detail for a basic gameplay bar.

Pass direction:

- Preserve ring/loom language.
- Thicken important ring silhouettes.
- Reduce fine lattice density.
- Use thread colors only for active state accents.
- Create a simpler health bar with stronger silhouette and less ornamental surface detail.

### Medium Priority: Background Architecture

Files:

- `Assets/chamber_of_first_weave/cotfw_chamber_mid_architecture_atlas_v2_clean.png`
- `Assets/chamber_of_first_weave/cotfw_chamber_far_architecture_atlas_v2_alpha.png`
- `Assets/chamber_of_first_weave/cotfw_chamber_foreground_silhouettes_atlas_v2_alpha.png`
- `Assets/chamber_of_first_weave/cotfw_loom_shrine_clean.png`

Current issue:

The architecture mostly fits the Threadbound identity, especially rings and arches, but some assets rely on tiny hanging threads, chips, and edge noise. Background pieces need lower contrast and clearer large shapes.

Pass direction:

- Preserve loom-ring, spindle, arch, and sacred-machine language.
- Reduce hairline thread clutter.
- Group value shapes more strongly.
- Keep backgrounds lower contrast than gameplay tiles and enemies.
- Make shrine/ring forms read first, detail second.

## Recommended Replacement Order

1. Chamber gameplay tiles and platform tiles
2. Threadling extracted single-frame idle/attack assets
3. Player keyframes and weapon/smear polish
4. HUD simplification
5. Background architecture simplification

All replacements should be created as versioned assets first. Do not overwrite original assets until a version is approved in-game.
