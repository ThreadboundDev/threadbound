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
- blurry painterly fantasy
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

"Graphic illustration 2.5D Threadbound environment matching Threadborne silhouette and contour readability. Shape-first rendering, clean black outline hierarchy, controlled shading, readable gameplay forms, cave plus architecture integration, atmospheric but restrained lighting, no photorealism, no painterly brushwork, no matte-painting softness."

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
