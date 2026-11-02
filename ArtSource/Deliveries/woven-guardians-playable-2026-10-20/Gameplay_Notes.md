# Woven guardians — playable delivery, October 20

Chase approved the Eave Runner and Loom Heron for production and placement.
Both use the existing EnemyBase state machine, HealthComponent, HurtboxComponent,
HitboxComponent, enemy scaling, health bars, hit feedback and save reset system.
Their attack scripts are confined to the new enemies. One small EnemyBase bug
fix prevents an old death timer from hiding an enemy that was just revived by
a save reset. No player, equipment or progression code changed. Reedhook remains
the existing prototype.

## Test in the map

Run `res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn`
with F6. The bottom **Eave Runner** and **Loom Heron** buttons teleport the player
to each encounter. F2 restores all five authored enemies. The other three enemies,
villagers, workstations, HUD, water, buildings and map geometry are retained.

Eave Runner starts on the tower platform at y=-595.2, near the right wall.
Loom Heron patrols above the right side of the boat slip. The teleport positions
were verified against the real player's capsule and actual building floors.

The art has genuine 3D skinned meshes rendered into transparent 768-square
SubViewports with 4x MSAA and mipmapped anisotropic materials. Physics stays 2D.
Enemy art is 96 game pixels per authored metre. The existing 3D building stage
and its ten placements remain intact. Offscreen enemy renders are suspended.

## Eave Runner

`Src/Enemies/EaveRunner/eave_runner.tscn` is the reusable gameplay prefab.
It uses the previously delivered 60-bone, 66,052-triangle model and twelve clips.
The short cloth tails remain bone animated.

The runner seeks nearby full-height walls on safe floor, checks three separate
contacts, braces, then climbs approximately 150 pixels. A low corner cannot act
as a perch. Its blue ring builds during a 0.6-second wall windup; aim locks for
the last 0.15 seconds. It pushes off, slashes during the authored blade sweep,
and lands into a 0.7-second recovery. The jump is ballistic and collision driven.
After landing it can seek the other wall for another leap.

If a wall is unavailable it uses a 0.55-second throwing windup and releases a
single pin 0.133 seconds into the release clip. Pins travel straight at 560px/s,
last at most two seconds, and stop at terrain. Continuous collision sampling
prevents tunnelling. They use the travelling pin as the damage source so the
existing shield block checks the correct incoming side after the thrower moves.
Owned pins are removed on reset/removal, and expire if their owner dies.

Initial tuning: 90 HP, 20 slash damage, 12 pin damage. No idle contact damage.
Hurt interrupts the windup, slash and pending pin release. These are first-playtest
values, not final difficulty balance.

## Loom Heron

`Src/Enemies/LoomHeron/loom_heron.tscn` is the reusable gameplay prefab.
Editable packed source is
`ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v1.blend`.
Runtime GLB and thirteen texture maps are under
`Assets/BlueBiome/Enemies/LoomHeron/`.

The model has 24,488 triangles, 13,176 vertices, eight material surfaces and
seventeen deform bones. Wings have actual wooden spars, framed indigo cloth
panels, pale sewn repairs, cord lashings and tassels. The body is woven; its
ceramic pointed face and paired-loop binding mark tie it to the approved guardian
direction. Detail maps are shared with the village/Eave Runner materials.

Clips: idle, flight, perch, dive_windup, dive, brake, hurt and death. The perch
clip is available for dressing/art review; this first playable instance hovers
and patrols rather than navigating onto perches.

The heron seeks a point above and beside the player, visibly folds its sails
for 0.7 seconds, then commits to one diagonal line. Aim stops following the
player 0.18 seconds before launch. A dive lasts at most 0.55 seconds/385 pixels,
stops on solid terrain or at the dry-air boundary, and brakes into a harmless,
vulnerable 0.95-second recovery close to the floor. It then repositions.

Initial tuning: 65 HP, 18 dive damage, 700px/s dive speed. No idle contact damage.
The central body is the collision/hurtbox; the full visual wing span is not an
invisible wall or damage area. Hurt and death stop the attack normally.

Both have a 950px home leash for target acquisition. Navigation is local and
collision driven, suitable for these authored encounters; it does not find
paths across an arbitrary maze or another floor. The exact maker of the woven
beings is left unspecified, consistent with the approved faction direction.

## Verification

- Saved Blender source: 106 checks of skin weights, all eight clips, deform
  bounds, finite geometry, loop joins, packed images and actual skeletal motion.
- Isolated gameplay: 80 checks; real-wall vs corner contacts, full wall sequence,
  one hit per attack, harmless windup/recovery, pin release/interruption, thin-wall
  projectile blocking, target occlusion, projectile cleanup, locked dive aim,
  terrain-blocked dive, hurt, death and save reset, including an immediate revive
  while the previous death animation's cleanup timer is still pending.
- Authored map with real player: 19 headless checks; both encounters, actual
  hurtbox damage, another wall leap after landing, existing shield block,
  health/UI, unchanged village placements and complete F2 replacement.
- Existing Reedhook regression checks also pass after the death/reset timer fix.
- Actual Forward+ renderer on RX6800XT: 97 checks and 80 captured frames, showing
  both live encounters in the real map. Captures preceded the later wall-seeking
  range improvement; subsequent headless checks verify repeated wall use.

Commands are in the three verifier scripts under `tools/enemies/` and
`tools/art/verify_loom_heron_source.py`. Godot console runs use the scratch APPDATA
folder under `work/lakeside-godot/appdata`, preserving the user's saves/settings.
Existing shutdown texture/resource cleanup diagnostics remain in the rendered
map's log; the gameplay and source checks have no failures or script errors.

No more graphical test windows were launched after Chase requested no further
window switching. Final verification and packaging used background tools.
