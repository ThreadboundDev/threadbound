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
| Ground combo 1/2 | 0.90 effective | 320 px |
| Up combo 1/2 | 1.10 | 384 px |
| Air double attack | 1.20 | 416 px |

Up attacks retain a 16 px runtime transparent gutter around their scaled source
cells. The air double attack uses a 416 px runtime cell, leaving a 16 px gutter
around its 384 px rendered source. All runtime visual scale multipliers remain `1.0`,
which gives future wrist-mounted grapple art a stable coordinate system.

The `ground_combo_01` authoring sheet now uses 896 px padded cells so repaired
weapon and smear pixels cannot cross an atlas boundary. Its normalizer scale is
`0.6428571`, which renders the original 640 px content at the same effective
`0.90` scale and preserves its existing screen size.

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

The upward combo clips repeat their vertical swing rather than transitioning
into the horizontal part of the source sheets:

- Up combo 1 plays source frames 8–12 twice at 12.5 fps. Its active windows
  are frames 1–4 and 6–9 in the ten-frame curated clip.
- Up combo 2 plays source frames 8–13 twice at 14.4 fps. Its active windows
  are frames 1–5 and 7–11 in the twelve-frame curated clip.

Both clips keep approximately their previous duration, show two distinct upward
swings, and retain two matching strike windows. Key readable poses tilt the mask
18 degrees toward the overhead weapon. The generated upward-head study is stored
at `docs/art/concept_art/Upward Attack Head Reference.png`; final sheet changes
remain deterministic so pose placement does not drift between frames.

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

### Stationary ground attacks

All four ground combo clips have one-to-one stationary variants:

- `Ground_Attack_Combo_1_Stationary` (14 frames)
- `Ground_Attack_Combo_2_Stationary` (19 frames)
- `Ground_Up_Combo_1_Stationary` (10 frames)
- `Ground_Up_Combo_2_Stationary` (12 frames)

Each stationary frame retains the corresponding moving frame's upper body,
weapon, and slash effect. Only the running lower body is replaced with a braced,
planted stance. The player uses the moving variant only when horizontal input
and real horizontal velocity are both present. Releasing input or pushing into
a wall selects the stationary variant. Switching in either direction preserves
the exact frame index and intra-frame progress; combat timing, strike windows,
combo state, and attack duration continue to use the original logical clip.

The stationary compositor deliberately keeps a narrow overlap around the belt:
the planted lower-body mask begins 12 source pixels above the detected belt,
while removal of the moving lower body begins 18 source pixels below it. This
shared 30-pixel source band prevents transparent or antialiased seams from
separating the torso from the hips after runtime downscaling.

The stationary animations are registered from the four normalized stationary
sheets when the player initializes. Their atlas regions, frame durations,
playback speeds, and loop settings are copied one-to-one from the moving clips.

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

The padding allows corrective translation without cropping an extended hand,
weapon pose, foot, or billowing cloth.

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

The upward-head pose study used the built-in ImageGen edit workflow. Prompt
direction: change only the stitched mask/head so it looks 20–25 degrees upward
toward the raised weapon; preserve the exact body, hands, bronze weapon, slash
VFX, proportions, placement, scale, and lighting; add no scarf or other cloth;
render on flat green for local alpha removal. The study establishes the intended
read, while the live sheets use a repeatable 18-degree local head treatment.

The stationary lower-body studies also used the built-in ImageGen edit workflow.
Prompt direction: preserve the approved player identity and attack-ready
silhouette; use an athletic, grounded stance with both feet planted; retain only
subtle cloth and weight motion; add no foot travel; render on flat green for
local alpha removal. The normalizer composites only the lower-body study beneath
the exact source upper body.

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
cells are reduced to 320 px by the final runtime-raster pass. Pass
`-UpwardHeadChromaSource <path>` only when replacing the transparent upward-head
pose study.

Pass both `-StationaryForwardChromaSource <path>` and
`-StationaryUpChromaSource <path>` to rebuild the four stationary authoring
sheets from new flat-green lower-body studies. Omitting them keeps the checked-in
stationary authoring sheets and only regenerates normalized runtime rasters.

Run the focused scene-level verification after importing:

```powershell
godot --headless --path . res://tools/player_animation/verify_player_animation.tscn
```

It checks the seven motion clips, all moving and stationary ground combos, and
the air double attack: frame counts, frame textures, atlas cell sizes, playback
speeds, loop modes, and the player's uniform runtime scale. It also verifies
that stationary/moving selection uses both input and real velocity and preserves
the frame plus intra-frame progress through each switch.

## Deliberate limits

- No legacy art was deleted.
- No scene tree was restructured.
- Grapple physics, range, collision, and hit behavior were not changed by this
  adjacent art pass.
- A true per-frame V3 weapon silhouette replacement would be a separate authored
  animation pass. V2 establishes the palette, master model, and stable scale that
  pass should follow.
