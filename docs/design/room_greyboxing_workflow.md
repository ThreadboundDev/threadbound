# Room Greyboxing Workflow

The Room Greybox editor dock exists to turn an idea into a playable room as quickly as possible.

## Palette

- Dark-grey terrain tiles: standard terrain and collision, painted on a 128 px grid through Godot's native TileMap palette.
- Dark-grey one-way tile: jump-through platform with a pale top edge, painted from the same palette.
- Dark-grey large block: freely resized solid rectangular geometry.
- Dark-grey one-way block: freely resized jump-through rectangular geometry.
- Blue water: playable prototype swim volume.
- Red hazard: damage and knockback volume; free placement by default so slopes, spikes, and irregular danger zones are not constrained to the grid.
- White water bulb: non-solid traversal volume. Attacks recoil the player,
  dashes continue through it, grapple pops it without propulsion, and ordinary
  contact gently ejects the player.

Select the intended room or geometry container, open **Room Greybox** in the bottom panel, and press **Terrain Tiles**. Choose the solid or one-way tile in Godot's TileMap palette, then paint and erase directly in the 2D viewport. Pressing the button again selects the room's existing `GreyboxTerrain` layer.

Use **Large Block** or **One-Way Block** for quickly placed rectangular geometry that is easier to resize than repaint. Water, hazards, and bumpers remain independent resizable pieces and do not snap to the terrain grid. Newly created elements are added beside the currently selected greybox element rather than inside it, preventing accidental chains of nested blocks.

Press F6 to run the current room.

The dock deliberately contains only pieces needed to build and test traversal.
Finished artwork, annotations, markers, slopes, and production-art generation
are handled outside this focused palette.

## Blue Macro Reference

Blue prototype rooms share the macro map at a 12× planning scale. Each room places its local origin over the relevant point in the same 18,432 × 12,288 map space. The reference is translucent in the editor and automatically hidden during play. Room boundaries are sized against the 1920 × 1080 gameplay viewport so normal rooms provide several screens of camera travel rather than merely surrounding one camera view.

Open `blue_biome_greybox_overview.tscn` to compare room footprints and preserve the macro composition. Do not use the overview as a runtime level. Open an individual scene under `BlueBiome/Prototypes/Rooms/` and press F6 to test that room alone.

Each shell starts with a temporary floor so it can run immediately. Paint the real silhouette into `Geometry/GreyboxTerrain`, then remove or resize the temporary floor when the room supports the player itself. Planned exits are markers only until the room-transition system is implemented.

The debug colors should remain conspicuous. This tool is evaluated by authoring speed and gameplay clarity, not presentation quality.

## Prototype Water

Current water is intentionally minimal. The player floats at the transformed top edge of the water volume with the torso and head exposed. Horizontal movement uses the Run animation, while an idle surface float uses Jump_Apex. Jump or Up rises and Down sinks. Pressing Jump while at the surface commits to a normal-strength launch long enough to clear the water volume. Opaque water renders above the player but below terrain, hiding submerged body pixels without covering platforms. It does not yet implement drowning, currents, waterlogged sinking, a regional unlock, or finished swimming animation.

### Finished Water Visual Workflow

The production target follows the demonstrated Maskborne workflow while
preserving the existing `GreyboxWater2D` physics contract:

1. Author water as a drag-resizable body aligned to the room's playable shape.
2. Reflect the continuously rendered background and eligible scene actors into
   the water rather than relying on a static painted reflection.
3. Apply a horizontal blur to calm and unify the reflected image.
4. Apply a top-to-bottom biome gradient independently of reflection capture.
5. Reduce reflected actors and background forms toward readable silhouettes,
   while retaining restrained dynamic light from character and scene lighting.
6. Break up both the outside edge and interior of reflected silhouettes with
   animated horizontal distortion and fragmented bands.

The reflection renderer is a presentation layer only. Water collision, player
surface height, concealment, swimming behavior, and eventual progression rules
remain separate systems. Source reference: [Creating Stylized 2D Water for
Games](https://www.youtube.com/shorts/4I3HkE7eA0A).

One-way tiles use a full one-way terrain polygon for landing and ledge probes plus a separate full grapple target. They pass upward from below and do not create solid vertical collision at internal tile seams. Double-tap Down briefly ignores terrain collision to fall through, then restores it automatically.

## Prototype Hazards

The **Hazard** button creates a reusable triangular spike strip. Hazards reuse the shared damage pipeline and expose size, spike width, damage, knockback, and retrigger delay. Their free placement is intentional: resize and rotate the same strip for floors, walls, or ceilings.

## Prototype Bumpers

The **Water Bulb** button creates a reusable non-solid traversal volume. Bulbs
are harmless solid surfaces: touching or landing on one never deals damage.
Each instance exposes its size, hits required to break, launch strength in
normal jump heights, and regeneration delay. The attack that removes the final
hit launches the player opposite the attack direction. Because ballistic height
depends on velocity squared, a value of `2.0` computes the speed required for a
two-jump apex rather than simply doubling jump velocity.

Use one-hit bumpers for fast traversal chains and multi-hit bumpers for route
timing, gates, or optional pockets that remain accessible until regeneration.
