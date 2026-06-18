# Combat Foundation

This document explains the first reusable combat framework for Threadbound.

The goal is to provide maintainable foundations for enemies, bosses, player damage, and hit feedback without rewriting the existing traversal controller.

## Core Concepts

Combat is built from small reusable pieces:

- `HealthComponent` stores health, damage, invulnerability, and death signals.
- `HurtboxComponent` receives hit data and forwards damage to health.
- `HitboxComponent` sends damage to hurtboxes while active.
- `DamageData` carries damage amount, knockback, hitstun, hit pause, source, and hit position.
- `HitFlashComponent` gives immediate visual hit confirmation.
- `CombatFeedback` provides shared hit pause and camera shake helpers.

These components are meant to work for the player, normal enemies, bosses, hazards, and future weapons.

## Enemy Architecture

`EnemyBase` is a `CharacterBody2D` scene with:

- collision body
- visual placeholder
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

Player combat tuning lives in `PlayerStats`.

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

The visuals are placeholder geometry. Future animation work can hook into `begin_attack`, hurt, and death behavior without replacing the architecture.

## Player Combat Hooks

The player now has:

- `HealthComponent`
- `HurtboxComponent`
- `AttackHitbox`
- `HitFlashComponent`
- `PlayerStats`
- `Attack` input action

The existing movement controller remains intact. The current attack is a simple timed melee hitbox used to prove the combat loop before final animations are added.

## Next Steps

- Add proper player attack, hurt, and death animations.
- Add enemy animation hooks for patrol, chase, attack, hurt, and death.
- Place Threadling instances into a test room.
- Add debug health displays if needed.
- Tune hit pause, knockback, and screen shake after testing in-game.
- Extend the state machine for bosses when boss-specific behavior is ready.
