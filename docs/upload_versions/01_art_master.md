# Threadbound Art Master

> Generated from the maintained source documents by `tools/build_upload_docs.ps1`. Edit the source documents, then regenerate this file.

## Included Sources

- `docs/art/asset_standards.md`
- `docs/art/environment_art_style.md`
- `docs/art/visual_readability_art_pass.md`

---

# Source: docs/art/asset_standards.md

# Threadbound Art Bible (Production Version)

## Vision Statement

Threadbound is a 2.5D metroidvania inspired by Hollow Knight, Crowsworn, gothic fantasy architecture, and illuminated manuscript ornamentation.

The visual identity of the game is built around:

* strong silhouettes
* clean black outlines
* graphic rendering
* gameplay readability
* ornate but controlled detail

The world should feel ancient, woven, and mysterious while remaining instantly readable during gameplay.

---

# Core Art Philosophy

## Readability First

Gameplay readability takes priority over realism, rendering complexity, or visual spectacle.

Every asset must remain readable at gameplay distance.

If visual detail reduces readability:

remove detail.

---

## Silhouette Before Detail

Assets should read in this order:

1. Silhouette
2. Major Shapes
3. Secondary Forms
4. Surface Detail

The silhouette should communicate the object before any internal detail is visible.

---

## Graphic Illustration and Shape-Based Rendering

Threadbound uses a graphic illustration style.

Threadbound uses clean, graphic shapes first, with controlled shading and lighting accents where they support form, material, mood, and readability.

Avoid:

* visible brush strokes
* smeared textures
* soft painting
* concept art rendering
* atmospheric paint effects
* realistic surface rendering

Prefer:

* clean linework
* hard-edged forms
* controlled shadow shapes
* restrained lighting accents
* flat color masses
* strong silhouette definition

---

# Linework Standards

## Outlines Are Structural

Outlines are a core part of the art style.

They are not optional decoration.

Outlines define:

* readability
* separation
* depth
* gameplay clarity

---

## Outline Hierarchy

### Foreground

Strongest outlines.

Used for:

* player
* enemies
* interactables
* gameplay platforms

---

### Midground

Moderate outlines.

Used for:

* major architecture
* traversal structures
* environmental landmarks

---

### Background

Lightest outlines.

Backgrounds should remain graphic and readable without competing with gameplay.

Backgrounds must retain crisp shape separation and edge clarity.

---

# Rendering Standards

## Shape-Based Rendering

Forms should be described through:

* shape design
* value grouping
* shadow masses

Not through excessive texture.

---

## Value Grouping

Use:

* clear light areas
* clear shadow areas
* limited value transitions

Avoid noisy rendering.

Large value shapes should dominate.

---

## Texture Philosophy

Texture should be implied rather than painted.

Good examples:

* stone cracks
* carved ornamentation
* architectural seams
* woven thread motifs

Bad examples:

* noise overlays
* heavy brush textures
* grunge layers
* photorealistic materials

---

# Architecture Style

## Architectural Identity

Threadbound architecture combines:

* gothic ruins
* cathedral forms
* woven motifs
* circular loom-inspired geometry
* vertical compositions

Architecture should feel:

* ancient
* sacred
* constructed around weaving symbolism

---

## Common Architectural Elements

Use frequently:

* arches
* spires
* circular frames
* hanging ornaments
* suspended chains
* thread motifs
* woven lattice structures

---

## Ornamentation Rule

Decoration should feel built into the structure.

Never pasted onto the surface.

Details should appear structural.

---

# Environment Art

## Visual Hierarchy

Environment art exists to support gameplay.

Priority:

1. Gameplay elements
2. Traversal readability
3. Environmental storytelling
4. Decorative detail

---

## Platform Design

Platforms must clearly communicate:

"This is a surface the player can stand on."

Top surfaces should be:

* readable
* high contrast
* visually stable

Undersides may contain:

* roots
* threads
* hanging ornamentation
* ruins

but must never obscure gameplay.

---

# Color Direction

## Palette Philosophy

Threadbound uses restrained color palettes.

The world is primarily built from:

* stone greys
* weathered golds
* muted greens
* neutral earth tones

Accent colors are used intentionally.

---

## Thread Colors

Thread influence should remain visually important.

Red:

* power
* force
* dominance

Blue:

* balance
* flow
* calm

Yellow:

* essence
* knowledge
* perception

Thread colors should act as focal points rather than flood entire scenes.

---

# Character Design Standards

## Readability Over Complexity

Characters should be the most readable assets in the game.

Requirements:

* clear silhouette
* recognizable shape language
* strong outline treatment
* readable pose language

A player should immediately understand:

* direction
* threat level
* current action

---

## Animation Philosophy

Animation should prioritize:

* readability
* responsiveness
* strong key poses

Avoid excessive in-between detail.

Strong poses are more important than smooth rendering.

---

# Enemy Design Philosophy

Enemies should follow Hollow Knight principles:

* simple primary shape
* recognizable silhouette
* clear attack language
* readable movement

Complexity should come from behavior rather than visual noise.

---

# VFX Standards

## Hollow Knight Philosophy

The VFX sells the attack.

The weapon supports the attack.

Not the other way around.

---

## VFX Characteristics

Preferred:

* clean graphic shapes
* sharp arcs
* strong motion language
* white dominant effects
* black contour accents
* thread-inspired breakup

Avoid:

* smoke clouds
* particle spam
* soft, texture-led magic effects
* blurry glows

---

# Asset Generation Guidelines

## Preferred Keywords

Use:

* graphic fantasy illustration
* clean black outlines
* strong silhouette
* hard-edged rendering
* gameplay asset
* hand-drawn 2D game art
* gothic fantasy architecture
* Hollow Knight readability
* Crowsworn-inspired detail
* transparent background

---

## Forbidden Keywords

Do not use:

* brush-led rendering
* texture-led rendering
* concept art
* digital painting
* oil painting
* brush strokes
* realistic rendering
* atmospheric painting
* cinematic illustration
* photorealistic
* soft shading

---

# The Final Test

Every asset should pass a simple question:

"Could a player instantly understand this while moving at full speed?"

If the answer is no:

simplify it.

---

> Threadbound is not painted.
>
> It is illustrated.
>
> Readability creates beauty.
>
> Clarity creates immersion.
>
> The silhouette comes first.

---

# Source: docs/art/environment_art_style.md

# Threadbound Environment Art Style Guide
_Global Environment Rules + Generation Specification_

## Purpose
This document serves as the universal environment art bible for Threadbound.

It defines:
- Global environment rules
- Style authority
- Technical standards
- Generation workflow
- Layer philosophy
- Prompt consistency

Region-specific identity should be stored in separate supplement files.

---

# 1. Core Environment Identity

Threadbound environments follow a:

**Graphic Illustration 2.5D** style.

Not:
- photoreal
- matte painting
- blurry, brush-led fantasy rendering
- texture-heavy realism

Instead:

- readability first
- silhouette driven
- graphic shape language
- controlled shading and lighting support
- gameplay clarity
- stylized rendering
- atmosphere serving movement

---

# 2. Style Authority Hierarchy

## Primary Style Authority
**Threadborne Character**

The environment should match Threadborne.

Environment must inherit:

- contour treatment
- silhouette readability
- stylized rendering
- graphic rendering balance
- value grouping
- edge clarity

**Character leads environment.**

The world adapts to Threadborne.

---

## Secondary Authority
**Approved Environment References**

These define:

- material language
- stone style
- architecture integration
- cave treatment

but do NOT override character readability.

---

# 3. Graphic vs Rendering Support

## Gameplay Geometry
**Graphic first, minimal rendering support**

Applies to:

- walls
- floors
- platforms
- collision geometry
- arches
- architectural structures
- gameplay overlays

Characteristics:

- strongest contour
- highest readability
- clean silhouette
- restrained texture
- hard-edged shadow shapes

---

## Midground
**Graphic forms with moderate shading support**

Applies to:

- decor
- ruins
- stalactites
- mid-depth forms
- silhouette layers

---

## Deep Background
**Simplified graphic forms with atmospheric lighting support**

Applies to:

- atmosphere
- cave depth
- distant structures
- ambient forms

Background should support mood while remaining cohesive, never becoming a soft matte painting.

---

# 4. Contour Rules

Gameplay geometry should include:

- visible contour treatment
- readable dark edge separation
- clear silhouettes
- intentional shape boundaries

Avoid:

- fuzzy edges
- soft matte painting
- overblending
- excessive realism
- noisy texture fields

Outlines should be:

- stylized
- restrained

Not comic-book thick.

---

# 5. Rendering Philosophy

Threadbound uses:

**Shape First Rendering**

Priority:

1. Silhouette
2. Value grouping
3. Contour
4. Surface texture

Texture should never overpower readability.

---

# 6. Cave + Architecture Philosophy

Threadbound regions often merge:

- nature
- ruins
- woven construction
- ancient systems

Architecture should feel:

- integrated
- reclaimed
- weathered
- embedded

Avoid:

- pristine fantasy cities
- perfect masonry
- overt temple spectacle

---

# 7. Technical Standards

## Viewport
**1920×1080**

Gameplay camera reference.

## Standard Grid
**128×128**

Used for:
- metrics
- layout
- gameplay planning
- collision logic

## Large Room / Region Canvas
Current standard:

**6144×3456**

## Player Scale Reference
Current reference:

**168 px**

Subject to gameplay iteration.

---

# 8. Layer Stack

## Layer 1 – Far Background
- atmosphere
- cave scale
- slow parallax
- simplified graphic forms
- controlled atmospheric lighting

## Layer 2 – Mid Background
- decor
- ruins
- silhouettes
- moderate parallax

## Layer 3 – Gameplay Layer
Most important layer.

Contains:
- terrain
- walls
- platforms
- collision forms

Characteristics:
- strongest contour
- highest readability
- closest match to Threadborne

## Layer 4 – Foreground / FX
Contains:
- framing
- occlusion
- veins
- shaders
- atmosphere
- reactive effects

Should never obscure gameplay unfairly.

---

# 9. Environment Workflow

Recommended:

1. Gameplay layout
2. Room sketch
3. Layer planning
4. Background generation
5. Gameplay geometry generation
6. Decor generation
7. FX and shader pass

AI supports:
- atmosphere
- materials
- consistency

Human controls:
- gameplay
- flow
- composition
- navigation

---

# 10. Prompt Formula

"Graphic illustration 2.5D Threadbound environment matching Threadborne silhouette and contour readability. Shape-first rendering, clean black outline hierarchy, controlled shading, readable gameplay forms, cave plus architecture integration, atmospheric but restrained lighting, no photorealism, no brush-led rendering, no matte-painting softness."

Then append:
- region identity
- layer
- mood
- technical size
- gameplay purpose

---

# 11. Region Supplements

Major areas should receive their own supplement files.

Examples:
- chamber_first_weave_environment.md
- monarch_region_environment.md
- hermit_region_environment.md
- sage_region_environment.md
- weaver_city_environment.md
- reclaimer_environment.md

These define:
- local palette
- local mood
- architecture
- gameplay notes
- local exceptions

---

# Source: docs/art/visual_readability_art_pass.md

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
