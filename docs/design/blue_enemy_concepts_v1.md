# Still Lake enemy concepts — approval pass 1

Status: A/Reedhook and the D2/Tide Duelist swordfish/samurai direction were approved for simple 3D models. First-pass editable Blender sources and rigged Godot exports are now available; see [model delivery notes](../art/blue_enemy_models_v1.md). The Swordfish Duelist's behavior, environmental interactions, elite variant, Bellstriker contrast enemy, and Stillwater Tortoise midpoint boss direction are now approved for prototyping; see [Blue Biome swordfish ecosystem and environmental combat](blue_swordfish_ecosystem_and_environmental_combat.md). B, C, and E remain proposals. Original D was not approved. Factions and lore have not been added. The current lake-heavy direction in the conversation takes precedence over the older overland route document.

The approved combat direction uses swordfish anatomy and the principles of battōjutsu and iaijutsu without making the creature a literal samurai. The earlier visual scope studies below remain useful model references, but the maintained behavior and encounter rules now live in the linked design record.

## Needlefin iteration 2

The user suggested combining a swordfish with a samurai and asked whether it might suit a boss. `ArtSource/BlueBiome/Concepts/Enemies/needlefin_samurai_v2.png` explores D1/Reed Ronin (common), D2/Tide Duelist (elite), and D3/Stillwater Ronin (miniboss). These are alternative scope studies, not three approved enemies. Shared features: a smooth katana-shaped bill, integrated helmet brow, indigo armor scales, and sleeve-like fins. Recommendation: use the middle silhouette with simplified fins as a distinctive regular/elite enemy; reserve elaborate dueling behavior and larger presentation for a possible miniboss. Its threat level should come from behavior and encounter design, not armor detail alone. No boss or lore commitment has been made. Generated with the built-in image tool; exact prompt saved alongside the board.

## Recommended presentation

Use simple live 3D characters with painted textures, restrained cel shading, and the same contour treatment as the player. Keep splashes, attack strokes, and magical effects in 2D. This matches the existing player and water bulbs while allowing smooth turns, swimming pitch, recoil, and attack animation without drawing separate sprite directions.

Material detail should come from the texture and large modeled shapes rather than dense geometry. Prototype budgets of roughly 2,000–8,000 triangles per creature are reasonable starting targets, not hard limits. Test the silhouette and animation at gameplay size before refining topology. Avoid the smooth plastic look of the earlier environment models: use broad painted value changes, selective roughness, worn edges, and very limited specular highlights.

Shared vocabulary: indigo cloth, blue-green bodies, aged ivory ceramic, weathered wood, and occasional frayed bindings. Keep bodies darker than the lake. Small coral markings can support attack tells, but movement and silhouette must communicate attacks without color alone. Friendly water bulbs retain their distinctive luminous globe and petal silhouette.

Names below are working labels. Their origin and allegiance remain undecided; they are not claims about the lake's established inhabitants.

## A — Reedhook: grounded skirmisher

Lean cloth-bodied dock prowler with a chipped narrow ceramic mask, reed shoulder strips, and a two-handed wooden boat-hook. About player height, with the long hook providing an immediately recognizable reach silhouette. A possible regional Frayed treatment, subject to narrative approval.

It approaches along a deck, visibly plants its rear foot and draws the hook back, then makes one forward rake with a short step. It pressures the player's horizontal spacing while leaving room to jump, dash through, or attack during recovery. No forced pull, disarm, invulnerability phase, or special counter required in the first version.

Minimum model: humanoid body, mask, coat skirt, hook. Minimum clips: idle, walk, anticipation/rake/recovery, recoil, collapse. Existing humanoid animation workflows make this a useful first ground prototype.

## B — Shard Crab: grounded heavy

Low, wide crab-like creature with a broken slate-glazed ceramic shell, four chunky walking legs, and two unequal claws. Roughly 1.3 player widths and half the player's standing height. Use big shell plates and a readable soft underside, not tiny shell detailing.

It raises the larger claw, leans toward the target, and makes a short ground slam. The body remains damageable throughout; the hard shell is a visual identity rather than an immunity puzzle. A slow lateral shuffle and longer recovery distinguish it from Reedhook. Start with contact damage only on the actual claw strike, not a permanently dangerous body.

Minimum model: shell, body, four legs, two claws. A short mechanical rig with clear pivots; no simulated cloth. Its low body gives the player a different jump/pogo target on decks and inside dry pockets.

## C — Reed Kite: aerial diver

An angular heron-like creature with an ivory pointed face and two indigo sailcloth wings supported by reed spars. Short frayed cord legs trail below it. The wide V outline must remain recognizable even with the wings folded.

It hovers above roof/deck routes, folds its wings in a visible windup, then dives along a committed diagonal and opens the wings to brake. It does not continuously steer into the player during the dive. Recovery stays close enough to attack, rather than retreating offscreen. Initially it remains above water and does not become an aquatic enemy when crossing the surface.

Minimum model: compact torso, head, two articulated wing assemblies, small tail. Animate broad rigid wing sections; no expensive cloth simulation is needed. Hover, fold, dive, brake, recoil, fall.

## D — Needlefin: aquatic charger

Compact koi-inspired dart fish with a pointed ivory snout, dark indigo body, pale back plates, two teal fins, and a forked tail. Around one player-body length. Its narrow arrow-like profile sharply contrasts with Silt Ray.

It cruises slowly, draws its body into an S and briefly flares its fins, then commits to a short straight charge. It brakes and turns before charging again. Aim locks during the tell; no homing charge or unavoidable body tracking. This tests underwater dodging and attacking while the player keeps swimming.

Movement is actively propelled through the magically still water, not evidence of a restored ambient current. Constrain the first prototype to its connected water volume; it must not swim through solid tiles, dry air pockets, or out into the sky. Keep collision handling and turn speed readable before adding more elaborate AI.

Minimum model: body, jaw/snout, two fins, three tail joints. Idle swim, coil/tell, dash, brake/turn, recoil. Recommended first aquatic model and enemy prototype.

## E — Silt Ray: aquatic spacing enemy

Broad, flattened kite-shaped ray with indigo/teal fins, a low broken ivory ridge, a small masked face, and one short tail. Roughly 1.5 player widths. A soft fan-shaped underside and slow fin movement distinguish it from the sharp Needlefin. Avoid a bell, flower, or glowing orb silhouette so it cannot be mistaken for a water bulb.

It glides at a medium distance, cups its fins visibly, then releases one slow, finite water-pressure projectile. The projectile dissipates against solid terrain and at the dry-pocket boundary. The ray remains vulnerable during the tell and recovery. No homing shots, persistent current field, whole-room pulse, or water-resistance debuff in the first version.

It creates a reason to move around an enemy rather than only swimming directly toward it. Pair one with Needlefin only after each is readable on its own; multiple overlapping projectiles should not be the initial test.

Minimum model: flat body, two fins with two joints each, short tail. Glide, cup/tell, release, relax, recoil. The projectile is a separate 2D effect.

## First playable selection after approval

Start with A and D: they answer the immediate questions of how ground combat and swimming combat feel against readable enemies. Then add B for a heavier close-range target, C for rooftop pressure, and E for underwater spacing. Do not implement all five behaviors before testing the first pair.

Approval can be by letter, independently for visual design and combat role. After approval, create simple models and short turn/attack previews before spending time on final textures. Keep original approved enemy work and current greybox room intact; use reusable enemy scenes for later placement.

## Image-generation status and prompt

The first built-in image generation attempt returned `usage_limit_reached`. A subsequent user-requested attempt succeeded: the five-panel approval board is saved at `ArtSource/BlueBiome/Concepts/Enemies/blue_enemy_lineup_v1.png`. The exact prompt is saved alongside it as `blue_enemy_lineup_v1_prompt.txt`. Built-in image generation was used; no fallback API was used. These remain concept proposals, not approved models or implemented enemies.
