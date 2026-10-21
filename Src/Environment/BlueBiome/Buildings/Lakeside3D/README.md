# Lakeside model and lighting test

The assembled map is now available in
`res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`.
Use F6 there for the painted terrain, water, building placement and smoothed
polygon collision. The original flat art-review room below remains available.

Open `res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_art_prep.tscn`
and run **F6** when ready. The existing lake greybox and main scene are unchanged.

The room has the covered boat slip, net workshop, fisher house and approved
central tower v3. It uses the current player and controller. Its flat test deck
and loft collision are temporary fixtures for checking art and entry; they do
not define the final level route. Water, air pockets, terrain and the final
building positions await the finished Krita map.

The review buttons offer daylight, dusk, all cutaways, entry cutaways, an
overview and a jump to each building. Entry cutaways automatically hide the
front wall and roof center when the player enters, restoring them on exit.
The fixed corner returns remain attached to the side walls and clear of the
interior. No existing player controls or equipment behavior were edited.

## Place into the authored room

1. Add one `lakeside_art_stage_2d.tscn` to the room.
2. Place the `covered_boat_slip_2d.tscn`, `net_workshop_2d.tscn`,
   `fishers_house_2d.tscn` and `central_tower_2d.tscn` prefabs as needed.
3. Each 2D origin is the model's **bottom center**, at **128 px per unit**.
   Move the anchors in the ordinary 2D editor. Translation, scale, rotation
   and visibility are forwarded to the 3D instance. The room owns collision.
4. Toggle **Preview Inside** on a house to inspect its cutaway. Adjust
   **Entry Rect** to the eventual accessible room shape. Entry is a sensor,
   not a solid wall; it filters the existing player's body/group.
5. Add `lakeside_lantern_2d.tscn` for a movable light. Its inspector exposes
   3D energy, radius, depth, shadow casting and matching actor-light energy.

The `*_3d.tscn` scenes are also available as ordinary Node3D prefabs. They have
no camera, light rig, water or generated 3D collision. Only the art stage's
two shared cameras render them into the existing 2D game.

`KritaReference` in the test room accepts an exported PNG at scale 1, with
Centered disabled, for matching pixel coordinates. The current lineup is a
review layout, not a traced or collision-authoritative copy of the unfinished
map. Interior floor tops are approximately 63 px above the workshop's anchor
and 81 px above the fisher house's anchor. Their test-room anchors compensate
for this so the player's feet meet the flat temporary deck.

## Materials and scale

| Model | Width × height × depth at game scale |
|---|---:|
| Covered boat slip | 1034 × 973 × 650 px |
| Net workshop | 1001 × 637 × 776 px |
| Fisher house | 745 × 835 × 764 px |
| Central tower v3 | 1200 × 4100 × 768 px |

Runtime resources are under `Assets/BlueBiome/Art/Lakeside3D/`. Geometry, UVs,
PBR values and source texture bytes come from the approved GLBs. The import
preparation only replaces duplicate embedded images with shared external
texture references and repacks the unchanged geometry buffers. See
`provenance.json` for source files and image SHA-256 values.

All four buildings now share the exact original Blender PNG maps at **4096 ×
4096** for color, normal and roughness. The old JPEG color and 2048 surface
files remain available but are no longer referenced by these building GLBs.
Imports use high-quality BPTC/BC7 compression where supported and mipmaps;
surface sampling uses anisotropic filtering. Geometry and UVs are unchanged.

The two building passes render at **125% of the viewport resolution**, with
4x MSAA and linear filtering when composited. Render Scale on LakesideArtStage
can be tuned between 0.5 and 2.0. Both passes retain the same camera registration
and shared lighting world; increasing this value costs GPU time and memory.

## Lighting baseline

`lakeside_lighting_3d.tscn` contains a shadow-casting sun, a restrained cool
fill and a scene-local WorldEnvironment with ambient light, filmic tonemapping,
contact shading and modest glow. **Soft daylight** and **Blue dusk** are
starting presets. The art stage's Lighting Preset property selects them;
the lighting scene's Sun Multiplier and Contact Shading properties allow tuning.

The buildings, lanterns and temporary deck share one World3D. Real 3D lights
therefore shade the model surfaces and can cast shadows between the models.
Foreground and background passes share that world. The 3D composite is
unshaded in the 2D pass to avoid applying a second ambient grade.

Each lantern pairs an actual shadowed OmniLight3D with the project's existing
WingLighting falloff texture on a PointLight2D. The latter includes lighting
layer 2, which the current live 3D player's composite receives. This keeps the
existing player presentation intact while allowing matching local warmth.

Painted 2D terrain can receive the 2D light component; receiving a physical 3D
shadow requires a matching 3D receiver. The temporary 3D deck provides a
receiver for this test. Final contact shadows, underwater lighting and any
GI bake should be tuned after the terrain and water boundaries are fixed.

References: [Godot 3D lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html),
[Godot viewports and shared worlds](https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html).

## Verification

`tools/environment/verify_lakeside_3d.gd` passes headlessly in Godot 4.7.2:
source-matched imported bounds, shared texture instances, shared World3D,
camera/2D registration at player and overview zooms, real-player floor contact,
entry/exit cutaways, fixed-roof clearance, and sun/lantern configuration.
Projection error is below 0.001 px. It also checks that the art contains no
3D collision or source preview cameras.

The CLI check uses dummy audio and workspace-only user data. No visible
editor, game window, mouse or keyboard control was used. A rendered Godot
lighting review remains for the user's playtest; these tests do not establish
the final lighting look. The existing equipment scripts still report their
separate shutdown resource diagnostics in the full-project CLI run.
