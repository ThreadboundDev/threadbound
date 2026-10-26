# Lakeside entrance depth and house focus — approval proposal

**Approved by Chase on October 26, 2026:** “Approve the proposed scope.” This
authorizes the door transition, indoor focus, exit cue and tower foreground rim
described below. Implementation and visual acceptance are tracked separately.

Chase's October 26 playtest confirms house bouncing is fixed and villager
interactions work. The work/greet poses are acceptable for now. Remaining
feedback is recorded in `docs/verification/lakeside_playtest_2026_10_26.md`.

## Proposed behavior

1. **House entry at the actual door.** Keep the existing Interact action. Briefly
   lock ordinary movement, turn the live 3D character away from the camera, play
   a short walk into the door, open the door presentation, then reveal the
   cutaway. Keep the player's horizontal location at the door, rather than the
   current offset InsideSpawn destination. Exit reverses this at the same door.
   The gameplay world remains 2D; depth motion is a visual transition, with only
   a short vertical reconciliation if indoor/outdoor floors differ. Do not fake
   this by translating the physical player horizontally across the room.
2. **Indoor focus.** Smoothly frame the occupied house with a modest zoom and
   house-bound camera limits. Dim/desaturate scenery outside the occupied house
   so the room is the focus, keeping HUD/prompt readable. Start with a restrained
   dim treatment rather than blur. Restore outdoor framing smoothly on exit.
   Leave tower traversal camera behavior alone in this first pass.
3. **Readable exit.** Retain a quiet amber door outline/light patch inside the
   house, aligned to the exterior door and active exit range. Keep the prompt.
4. **Tower opening depth.** Separate the front stone lip/jambs into an always
   foreground art piece. Keep the open swim path and existing physics. The player
   passes behind the stone rim before the facade/cutaway reveals the interior.
   This needs a mesh/render-layer split, not a new underwater movement system.

These changes are needed because the current door interaction changes the
physical destination immediately, while the facade and camera provide no entry
motion or indoor emphasis. The tower's fixed basin currently draws behind the
player even at its front face.

## Implementation file list

Existing files that may change for this proposal:

- `Src/Characters/Player/player.gd`
- `Src/Characters/Player/player_live_3d_visual.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_2d.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_door.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_building_3d.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_art_stage_2d.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/fishers_house_2d.tscn`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/net_workshop_2d.tscn`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/central_tower_3d.tscn`
- `Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.gd`
- `tools/environment/verify_lakeside_house_entry.gd`

New files (and Godot import/UID sidecars where needed):

- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_focus.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_focus.gdshader`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_door_visual.gd`
- `Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_door_visual.gdshader`
- `Assets/BlueBiome/Art/Lakeside3D/Models/central_tower_v5.glb`
- `outputs/central-tower-model-v5/CentralTower_Editable.blend` and README/.gdignore
- `tools/art/split_tower_entry_foreground.py`
- `tools/environment/verify_lakeside_entry_focus.gd`
- `work/lakeside-entry-focus-2026-10-26/` source checks, GPU captures and reports

Documentation: this proposal, the linked playtest report, current
`docs/project_status_and_worklist.md`, and `docs/next_test_session.md`.

## Verification / limits

Exercise actual input enter/exit repeatedly, both house types and presentation
modes; preserve player stats, equipment and combat outside the transition. Test
hurt/death, repeated Interact, interrupted transitions, F2/debug teleport, camera
restore and resize. Capture intermediate entry frames and the tower approach
from below. Check that the exit cue and camera framing agree with the actual
door, and tower art adds no blocking collision.

Approval is required under AGENTS.md: "Before making any architectural changes"
and "Scene tree restructuring". This proposal is not yet approved. Bug fixes
for reflections, visual contact, idle bulb presentation and crack depth can
proceed separately; new house/camera/entrance architecture waits for approval.
