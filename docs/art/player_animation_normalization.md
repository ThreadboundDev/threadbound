# Player animation normalization V2

## Goal

Use the approved idle model as the source of truth for Threadborne's proportions
and palette, remove animation-dependent node scaling, consolidate the live player
art into one predictable folder, and establish the bronze long-handled Weaver's
Shuttle as the model for new weapon art.

The original assets remain in place as source material. The playable player scene
now references `Assets/Threadborne/Player/Normalized_V2`.

## Canonical presentation

- Proportion and character palette reference:
  `docs/art/concept_art/Idle right first.png`
- Weapon reference:
  `docs/art/concept_art/Weapon Model Bronze Long Handle.png`
- Runtime raster scale: 50% of the normalized authoring output
- Runtime `AnimatedSprite2D` scale: uniform `Vector2(0.70, 0.70)`
- Intended standing presentation: approximately 175 screen pixels tall

The idle sheet remains the calibration baseline. Run poses are naturally more
crouched, so they were not enlarged merely to force every silhouette to the same
bounding-box height.

## Scale normalization

The old scene compensated for differently authored attack sheets by changing the
entire player sprite's scale at runtime. V2 bakes those adjustments into the
transparent sheet cells:

| Animation family | Baked scale | Cell |
| --- | ---: | ---: |
| Ground forward | 0.75 | 512 px |
| Neutral special | 0.675 | 512 px |
| Ground combo opener | 0.90 | 320 px |
| Ground combo finisher | 0.6428571, rendered at 1.40 | 320 px |
| Stationary double hit | 0.90, rendered at 1.40 | 320 px |
| Backpedal combo variants | 1.15, rendered at 1.25 | 320 px |
| Air double attack | 1.20 | 416 px |

The air double attack uses a 416 px runtime cell, leaving a 16 px gutter around
its 384 px rendered source. The moving finisher, stationary double hit, and
backpedal variants use the runtime presentation multipliers listed above; other
animation families retain a `1.0` visual multiplier.

The `ground_combo_01` sheet is restored to the established 320 px runtime atlas.
Its content is baked at `0.6428571`, then displayed at a `1.40` visual
multiplier during the moving finisher. This produces the approved larger
screen-space character without changing Godot's atlas cell format.

### Runtime memory budget

The normalizer performs palette, registration, and opacity work at the larger
authoring resolution, then reduces every body-animation raster to 50% for
runtime. The uniform player sprite scale doubles from `0.35` to `0.70`, so the
screen-space character size and animation offsets remain unchanged.

This reduces texture area by 75%. Before this correction the V2 player folder
expanded to approximately 800 MiB of raw RGBA pixels before engine and graphics
copies. The optimized runtime rasters decode to approximately 200 MiB.

## Motion tuning

The basic ground attack previously played all 48 frames in a mixed
run-and-attack sheet at 90.566 fps. V2 plays the three planted strike poses in
source frames 31–33 at 6 fps: a readable 0.5-second overhead cut without the
repeated sprinting foot cycle.

### Forward pseudo three-hit chain

The forward chain uses the authored sheets in reverse numerical order:

- `ground_combo_02.png` is the logical `Ground_Attack_Combo_1` opener. It has
  14 curated frames and one damaging strike on runtime frames 3-5.
- `ground_combo_01.png` is the logical `Ground_Attack_Combo_2` finisher. It has
  19 curated frames and damaging strikes on runtime frames 2-4 and 9-11.

Pressing attack again during the opener or within the 0.45-second reset window
plays the two-hit finisher, creating a three-hit sequence. Waiting beyond that
window restarts at the one-hit opener. The forward finisher caps and resets the
chain instead of wrapping immediately back to the opener.

### Video-derived ground attack variants

The supplied stationary recording provides one standalone authored attack:

- `Ground_Attack_Combo_2_Stationary` uses the first double-sweep take and keeps
  source frames 0, 2, 4, 6, 8, 10, 11, 13, 15, 16, 18, 19, 21, 22, 24, 25, 27,
  28, and 29 as a 19-frame double hit. The discarded single-sweep take remains
  only as authoring reference and has no runtime sheet or animation.

The supplied backpedal recording also has two cuts:

- `Ground_Attack_Combo_1_Backpedal` compresses the complete source motion
  through frame 40 into a quick 14-frame opener so it still returns to its
  recovery pose before a chained attack begins.
- `Ground_Attack_Combo_2_Backpedal` carries the full two-sweep motion through
  source frame 40 as a 19-frame finisher.

All three active variant sheets are green-keyed while preserving the
recordings' shared 640 px camera origin and ground line, then reduced to 320 px
runtime cells. The stationary animation uses a `0.90` content scale, leaving at
least 16 transparent pixels around every occupied frame so slash effects cannot
clip at cell boundaries. It uses one consistent runtime scale across all 19
frames; pose foreshortening is kept in the artwork instead of compensating with
per-frame scale changes that make the upward sweep visibly grow.
Backpedal clips retain their `1.15` source scale because their recorded framing
already provides safe gutters. Preserving the fixed source canvas prevents a
low slash trail from being mistaken for a foot anchor and shifting the body
between frames. Broad white slash effects are protected during the selective
bronze weapon recolor so the VFX does not inherit the weapon palette.

The logical moving and backpedal opener/finisher chains remain at 14 and 19
frames. A stationary input bypasses the opener, plays the approved double-hit
animation as one complete move, and resets instead of chaining into a repeat.
When a swing begins, the player locks its visual mode for the full duration:

- no usable horizontal motion selects stationary;
- input and motion opposite the attack facing select backpedal;
- forward input and motion select the original moving animation.

Locking the selection at swing start prevents input release, acceleration, or a
collision from changing atlases mid-animation and causing a visible jitter.
Every variant keeps the logical clip's frame count, playback speed, and duration,
while its strike windows follow the visible slash poses in that specific take.

The old upward ground attack remains as unreferenced legacy source art, but it is
no longer present in the active player `SpriteFrames`. Upward ground input now
uses the frontal combo and its hit sector is widened from 90 to 130 degrees,
reaching slightly above the mask without covering directly overhead. Targets
farther above the player require an air attack.

### Ground finisher edge repair

Source files `frame_06.png`, `frame_07.png`, `frame_14.png`, `frame_15.png`, and
`frame_16.png` in `grounded_double_attack_01` were expanded from 640 px to
896 px canvases. The original 640 px content remains centered, while recovered
weapon tips and swing-smear pixels occupy the added padding. The assembled
`grounded_double_attack_01_sheet.png` uses the same 896 px cell layout, so none
of the recovered pixels can bleed into an adjacent frame.

### Atlas, opacity, and registration corrections

The first normalization pass incorrectly calculated baked scale from the
destination cell size. Values above `1.0` therefore drew outside their atlas
region and overwrote adjacent frames. V3 calculates baked scale from the
authored source cell instead. Every source frame is isolated before scaling,
and enlarged attacks retain transparent gutters.

Character pixels in the combo and air sheets are alpha-hardened after weapon
recoloring. Interior character/weapon pixels are opaque while antialiased edges
and pale slash VFX retain their original translucency.

Secondary-motion sheets now use padded 320 px runtime cells:

- Jump ascent, apex, descent, and wall cling register all frames to the first
  frame's head anchor.
- Landing and both grapple tosses register to the first frame's foot/ground
  anchor.
- Both moving ground-combo sheets receive a final median-baseline registration
  pass so the video-derived foot line does not bob between frames.
- The runtime wall-cling sheet receives a final contact registration pass after
  downscaling. Its occupied wall and ground edges are locked to frame zero so
  rounding cannot introduce a one-pixel fidget.
- Ledge hang uses a transparent 2x2 sheet; the connected opaque-black source
  background is removed without keying dark pixels enclosed by the character.
- The diagonal grapple toss clears only tiny detached components in the known
  lower-right atlas gutter, eliminating the one-frame screen-corner speck while
  preserving the authored body and cloth motion.
- The active grapple root and needle serialize hidden. During launch, the line
  renders only from the hand to the needle's travelled position; the full
  slack-rope simulation chain does not appear until attachment.

Runtime presentation applies two small movement-only corrections without
changing collision: landing uses a `0.88` visual multiplier with a 5 px downward
offset, while wall cling shifts the sprite 22 px away from the collision wall.
Wall cling and ledge hang keep their wall-side hand and foot rows fixed while
bowing the torso away from the collision edge. The cling contact VFX remains at
the collision surface, but is smaller and more transparent so it cannot cover
the pose. Pulling onto a ledge follows a 0.2-second eased quadratic arc and
progresses through hang, planted wall-brace, and landing poses instead of
teleporting or sliding one rigid frame to the platform top.

The padding allows corrective translation without cropping an extended hand,
weapon pose, foot, or billowing cloth.

## Editor-visible animation ownership

All playable clips are serialized directly into the `Player Animation`
node's `SpriteFrames` resource. Stationary and backpedal attacks, ledge hang,
wall cling, and the save-point sit sequence can therefore be previewed and
edited in the Godot inspector without running the game. `player.gd` selects
among those authored clips but no longer creates animation frames in `_ready()`.

The ledge-hang sheet is a separately authored four-frame contact pose. Its upper
hand, overall bounds, and foot line are registered within two pixels across the
loop. The gripping arm reaches the x=198-204 contact band in each 320 px cell,
letting the hand meet thin floating-platform edges while the arched torso remains
clear of thick wall foliage. The restored waist sash is preserved directly in
the artwork. The normalizer removes any connected dark background but does not
apply the wall-cling procedural warp to this sheet.

### Secondary motion and grapple tosses

The former single-frame jump and wall-cling poses now have restrained four-frame
cycles. The body silhouette stays stable while the tunic hem, waist cloth,
sleeves, and trouser folds shift enough to keep airborne and wall states from
looking frozen.

| Animation | Frames | Playback | Behavior |
| --- | ---: | ---: | --- |
| Jump ascent | 4 | 8 fps | Loops while rising |
| Jump apex | 4 | 8 fps | Loops within 140 px/s of the vertical apex |
| Jump descent | 4 | 8 fps | Loops while falling |
| Jump land | 4 | 12 fps | One-shot, held for 0.28 seconds when landing at rest |
| Wall cling | 4 | 6 fps | Slow loop with stronger tunic/waist-cloth billow |
| Grapple horizontal | 6 | 18 fps | 0.33-second one-shot throw |
| Grapple diagonal | 6 | 18 fps | 0.33-second one-shot throw |

The grapple throws progress from a braced ready pose through acceleration,
release, follow-through, and recovery. The sheets intentionally contain no
rope, hook, needle, or effects; those remain driven by the existing grapple
scene so the body animation can be shared across grapple types.

`player.gd` now selects the existing `Jump_Apex` clip around the top of the arc
and briefly selects `Jump_Land` after a stationary landing. This only changes
animation selection; jump force, gravity, horizontal control, and collision
behavior are unchanged.

## Color and weapon decisions

The combo and air attack sheets' embedded silver/lavender blades were selectively
remapped to the character's bronze/brown family. White/gray slash effects and the
character colors are preserved. Existing rendered attack frames retain their baked weapon
silhouette for animation continuity; newly authored frames should use the longer
V3 handle and bronze construction.

The supplied weapon concept was used as an image-generation edit reference to
preserve its silhouette while harmonizing it with the idle model's bronze and
leather palette. It was generated against a flat green key, then converted
locally to clean alpha. The in-game copy is rotated and scaled into the old
sheathed weapon's footprint so existing pose tracks remain valid.

Image edit prompt summary: preserve the exact long-handled shuttle silhouette,
angle, proportions, bronze head, leather grip, and line work; make only subtle
palette/finish corrections from the idle reference; use a flat chroma background
for lossless local removal.

The seven secondary-motion sheets were generated with the built-in ImageGen
workflow against flat green and converted to clean alpha locally. Prompt
direction for jump and wall cycles: preserve the approved player identity,
proportions, pose, costume, camera, and lighting; make the body nearly still;
animate only subtle tunic, waist-cloth, sleeve, and trouser-fold billow; use a clean
2x2 grid with no weapons, rope, effects, text, or shadows. Prompt direction for
grapple throws: preserve that same model and planted footing; create six readable
poses in a 3x2 grid moving from ready through a quick horizontal or diagonal
throw and recovery; do not draw the grapple device, rope, hook, projectile,
effects, text, or shadows.

The five edge repairs used per-frame ImageGen outpainting. Prompt direction:
preserve every visible in-frame detail and recover only the clipped bronze
shuttle tip and/or broad translucent swing arc outside the old boundary; add
generous padding; avoid thin spikes or extra effects; render on flat green for
local alpha removal. Generated pixels are used only in the padded edge region.

## Regeneration

From the project root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\player_animation\normalize_player_animation.ps1
```

Pass `-WeaponChromaSource <path>` only when replacing the transparent weapon
reference from a new flat-green source. Pass
`-MotionChromaSourceDirectory <directory>` to rebuild the seven motion-cycle
sheets from matching `ascent.chroma.png`, `apex.chroma.png`,
`descent.chroma.png`, `land.chroma.png`, `wall_cling.chroma.png`,
`grapple_horizontal.chroma.png`, and `grapple_diagonal.chroma.png` files. Godot
`.import` companions are generated by opening/importing the project after the
script completes.

Use `-RegisterExistingMotion` once when migrating an older 512 px generated
motion sheet to the padded, anchor-registered layout. The full 640 px registered
cells are reduced to 320 px by the final runtime-raster pass.

Pass `-StationaryAttackVideo <path>` and `-BackpedalAttackVideo <path>` to
re-extract the four checked-in video attack authoring sheets. The frame maps are
defined in the script. Pass `-FfmpegPath <path>` if FFmpeg is not on `PATH` or in
one of the known install locations. Omitting the video arguments keeps the
checked-in authoring sheets and regenerates only the normalized runtime rasters.

Run the focused scene-level verification after importing:

```powershell
godot --headless --path . res://tools/player_animation/verify_player_animation.tscn
```

It checks the motion clips, editor-authored sit and ledge clips, moving,
stationary, and backpedal ground combos, and the air double attack: frame
counts, frame textures, atlas cell sizes, playback speeds, loop modes, and the
player's animation-specific visual scale. It also verifies ledge alpha,
wall-cling contact registration, grounded attack baselines, diagonal grapple
gutter cleanup, landing and wall visual tuning, the phased ledge climb,
stationary atlas gutters and frame-scale correction, standalone stationary
reset behavior, ground variant locking, upward input routing, the 130-degree
frontal arc, and absence of the retired upward clips.

## Deliberate limits

- No authoring source art was deleted; only the rejected stationary runtime
  derivative was removed.
- No scene tree was restructured.
- Retired upward attack sheets remain available as source art but are not loaded
  by the active player scene.
- Grapple physics, range, collision, and hit behavior were not changed by this
  adjacent art pass.
- A true per-frame V3 weapon silhouette replacement would be a separate authored
  animation pass. V2 establishes the palette, master model, and stable scale that
  pass should follow.
