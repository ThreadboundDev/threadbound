# Asset Standards

This document defines working standards for placeholder and production art. The goal is to keep Threadbound visually consistent while the project still uses a mix of sprite exports, AI-assisted concepts, and experimental rigging tests.

## File Naming

Use lowercase `snake_case` for new runtime art files and folders.

Preferred examples:

- `threadborne_idle_right.png`
- `base_grapple_needle.png`
- `mossy_tileset.png`
- `equip_icon_monarch_gloves.png`

Source art files such as `.kra` may keep descriptive working names while they are still exploratory, but exported runtime art should use stable names.

## Player Sprite Standards

Until rigged animation is ready, the active player uses sprite-based animation.

For new Threadborne sprite exports:

- Use a consistent canvas size within each animation set.
- Keep the character centered around a consistent foot position.
- Keep the same visual scale between idle, run, jump, wall cling, and grapple frames.
- Preserve transparent padding instead of cropping each frame tightly.
- Avoid changing camera distance or perspective between frames.

Current inconsistency to clean up over time:

- Idle sheet: `3072x3072`
- Run frames: `1095x1095`
- Jump/grapple frames: mixed rectangular canvases
- Rig base pieces: mostly `1023x1537`

## Rigging-Friendly Art

Experimental rigging is archived for now. Future rig-ready art should be planned around clean layer separation rather than cutting up a flattened image.

Recommended layer groups:

- Head
- Torso
- Upper arms
- Forearms
- Hands
- Belt / waist
- Upper legs
- Shins
- Feet
- Scarf / cloth accents

To avoid boxy joint artifacts:

- Paint overlap past the joint area.
- Round limb ends where rotation will expose edges.
- Keep elbows, knees, wrists, and ankles separated enough for deformation.
- Add hidden under-painting behind rotating parts.
- Use consistent pivots for mirrored left/right limbs.

## Threadborne Palette

Use `docs/art/concept_art/threadborne_master_palette_final.png` as the current palette reference.

Current base swatches:

- Head / hands: `#e7af8d`
- Chest / pants: `#2d2123`
- Belt / bracers / boots: `#5b2c21`
- Global outline: `#000000`

Supporting shades from the palette may be used for highlights and shadows, but new placeholder art should avoid drifting into unrelated skin, cloth, or leather colors.

## UI Icon Standards

Equipment icons should eventually share:

- Matching canvas size
- Matching camera distance
- Matching background treatment
- Matching outline thickness
- Clear silhouette at small sizes

Current equipment icon exports are mostly `1920x1080`, which is oversized for runtime UI. Keep source-resolution files if useful, but future runtime exports should be sized intentionally for UI use.

## Validation Checklist

Before adding or replacing runtime art, check:

- Does the filename use `snake_case`?
- Does the image match the expected canvas size for its set?
- Does the character/object keep the same scale as neighboring assets?
- Does the transparent bounding box drift between animation frames?
- Does the palette match the master reference?
- Does the asset need a source file archived beside it?
- Is the import path referenced by scenes or scripts?

## Automation Ideas

Useful future tooling:

- Generate an asset inventory with image dimensions.
- Report transparent bounding boxes for player animation frames.
- Create contact sheets for visual review.
- Compare sampled colors against the master palette.
- Flag runtime assets with spaces, uppercase names, or punctuation-heavy paths.
