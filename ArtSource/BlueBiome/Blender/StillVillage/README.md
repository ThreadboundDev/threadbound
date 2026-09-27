# Still Village kit — first production pass

Open `Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_preview.tscn`
in Godot and press F6. It inherits the bulb choice room and adds an isolated art
pass. Player controls, room collision, launch responses, and bulb timing come
from the existing scene.

## Deliverables

- `StillVillage_Kit_v1.blend`: twelve editable asset collections, materials,
  modifiers, curves, and neutral orthographic studio. The assets are arranged
  in a source-file grid for inspection.
- `models/`: twelve individual GLB models, exported with their own origin.
- `still_village_kit_review.png`: contact sheet of the actual built assets.
- `room_start_preview.png`: actual Godot view at gameplay scale.
- `room_overview_preview.png`: whole-room overview from Godot.
- `kit_manifest.json`: texture sizes, pivots, and pixels per Blender unit.
- `model_verification.json`: verified mesh and triangle counts per GLB.

Runtime textures and bulb frames live in `Assets/BlueBiome/StillVillage`.
Reusable collision-free placeable scenes live in
`Src/Environment/BlueBiome/ArtPlaceables/StillVillage`.

## Twelve pieces

1. Short stone cap
2. Long stone cap
3. Timber deck
4. Curved brace
5. Support post
6. Bulb hanger with separate living attachment
7. Dry irrigation channel
8. Complete stopped waterwheel
9. Shore stone
10. Grass clump
11. Cherry foliage cluster
12. Still cloth awning

All twelve have 3D source geometry and GLB exports. The 2D room uses their
orthographic renders, including foliage and cloth, rather than instantiating a
live 3D viewport for every prop. Stone and deck origins mark the walkable top
left; post origins mark their upper center. Refer to manifest pivots when
placing raw textures; the reusable scenes apply those offsets automatically.
The nominal source density is 128 pixels per Blender unit.

## Two 2D parallax layers

- Far: sky, mountains, and the dry waterfall scar; camera factors (0.10, 0.04).
- Near: distant village and still lake; camera factors (0.26, 0.08).

The far plate covers the camera bounds without repetition. The near plate
repeats horizontally with mirrored edges; it never repeats vertically. A
presentation shader lowers near-layer contrast and fills the generated lake's
soft bottom alpha. Solid sky/lake fills prevent exposed edges. These fills do
not add another illustrated parallax layer. Neither water nor machinery is
animated in this still-state room.

Backgrounds were generated with the built-in image tool; complete prompts are
in `background_generation_prompts.md`. The kit geometry and sprite rendering
were authored deterministically in Blender.

## Bulb presentation

The approved Hanging Bell render is packaged as four SpriteFrames animations:
24-frame rush, 12-frame pop, 6-frame spent hold, and 30-frame refill. The room
uses the existing bulb broken/regenerated signals. Refill anticipates the
existing 2.5-second cooldown and returns to the rushing loop exactly when the
bulb becomes usable. The water center stays aligned with the original target.
Hanger supports and stems are decorative and do not introduce obstacles.

## Validation

- Godot import and script parsing completed.
- `tools/environment/verify_still_village.tscn`: PASS. Compares every inherited
  collider, one-way flag, bulb coordinate/size/timing; loads all 12 placeables;
  checks the two measured camera-follow rates and horizontal coverage at both
  room ends; verifies pop, refill, and regenerated visual states.
- All twelve GLBs contain mesh geometry.
- All twelve rendered pieces have nonempty alpha with padding on every side.
- Gameplay-scale and overview renders were visually reviewed; hanger/stem gaps,
  missing hanger supports, excessive background scale, and overly angular
  blossoms were corrected.

The headless run still emits the host certificate-store error and existing
player-resource shutdown warnings. The focused test reports PASS; this is not
a claim of a warning-free whole-project run.

## Rebuild

1. Run background Blender with `--factory-startup --threads 8 --python
   tools/art/build_still_village_kit.py`.
2. Run `tools/art/package_still_village.py` with Python + Pillow.
3. Import in Godot, run the focused test, then open the preview scene with F6.

The preview creates its art nodes at runtime. Use the twelve placeable scenes
for editor-authored production rooms. This is a first art pass: review surface
finish and decorative density at native gameplay scale before extending it
across the biome. The illustrated concept sheet is a direction reference, not
a pixel-identical promise for these first 3D models.
