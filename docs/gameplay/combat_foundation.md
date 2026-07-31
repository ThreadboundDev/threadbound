# Combat Foundation

This document explains the first reusable combat framework for Threadbound.

The goal is to provide maintainable foundations for enemies, bosses, player damage, and hit feedback without rewriting the existing traversal controller.

## Core Concepts

Combat is built from small reusable pieces:

- `HealthComponent` stores health, damage, invulnerability, and death signals.
- `HurtboxComponent` receives hit data and forwards damage to health.
- `HitboxComponent` sends damage to hurtboxes while active.
- `DamageData` carries damage amount, knockback, hitstun, hit pause, move-owned
  screen shake, source, and hit position.
- `HitFlashComponent` gives immediate visual hit confirmation.
- `CombatFeedback` provides shared hit pause and camera shake helpers.

These components are meant to work for the player, normal enemies, bosses, hazards, and future weapons.

## Enemy Architecture

`EnemyBase` is a `CharacterBody2D` scene with:

- collision body
- authored or fallback visual
- health component
- hurtbox
- detection area
- attack range area
- melee hitbox
- hit flash component
- state machine

Enemy-specific scenes should inherit from `Src/Enemies/EnemyBase/enemy_base.tscn` and provide:

- a script extending `EnemyBase`
- an `EnemyStats` resource
- any unique visuals, animations, attacks, or state overrides

## Enemy States

The base state machine supports:

- `Idle`
- `Patrol`
- `Chase`
- `Attack`
- `Hurt`
- `Dead`

The state machine is intentionally simple. Each enemy can override methods on `EnemyBase`, replace state scripts, or add new states for special behavior.

## Stats

Enemy tuning lives in `EnemyStats` resources.

Current tunables include:

- max health
- move speed
- chase speed
- acceleration
- gravity
- attack damage
- attack timing
- hurt timing
- death cleanup delay
- knockback
- hit pause
- screen shake strength
- opt-in incoming knockback and hitstun multipliers
- opt-in hurt knockback damping, gravity, and visual recoil

Player combat tuning lives in `PlayerStats`.

Normal enemies opt into receiver-specific hurt response so the same player move
can read differently by target weight: Threadlings react lightly, Loomkins sit
in the middle, and Tensioners react heavily. Bosses and legacy enemies retain
their authored behavior unless they explicitly opt in. Opt-in normal enemies
use a short damage gate so distinct rapid combo strikes can both connect.

## Threadling Example

`Src/Enemies/Threadling/threadling.tscn` is the first example enemy.

It currently:

- patrols around its start position
- detects the player with an aggro area
- chases the player
- attacks when the player is in melee range
- takes damage through its hurtbox
- flashes on hit
- dies when health reaches zero

Enemy scenes may replace the fallback geometry with authored animation while
continuing to use `begin_attack`, hurt, and death behavior from this architecture.

## Player Combat Hooks

The player now has:

- `HealthComponent`
- `HurtboxComponent`
- `AttackHitbox`
- `HitFlashComponent`
- `PlayerStats`
- `Attack` input action

The movement controller now drives authored moving, stationary, backpedal, air,
grapple-strike, and neutral-smash attack timelines. Hitboxes follow the matching
animation strike windows and each move owns its damage and feedback profile.

## Combat Presentation Ownership

The accepted `DamageData` owns hitstun, hit pause, and move-specific camera
shake. Receivers may scale physical response for body weight, but should not
replace a move's presentation profile. Legacy hits without move-owned shake may
fall back to the receiver's existing feedback values. Ground impacts that must
read even on a miss—the neutral smash and Tensioner stomp—request one
activation-owned shake and explicitly suppress per-target shake fallback.

Normal enemies also attach a small world-space health bar above their visuals.
It appears after recent damage, follows the enemy, and hides again after a short
delay. Bosses keep their dedicated HUD and do not receive this bar.

## Next Steps

- Playtest attack commitment, cancel timing, and hit readability across mixed
  Threadling, Loomkin, and Tensioner encounters.
- Tune the ProtoWeaver and later bosses in their own dedicated boss pass.
- Extend the same move-owned feedback contract to future enemies and weapons.
- Continue tuning move-owned hit pause, knockback, and screen shake after
  playtesting.
- Extend the state machine for bosses when boss-specific behavior is ready.
