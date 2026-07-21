# Threadbound Gameplay Master

> Generated from the maintained source documents by `tools/build_upload_docs.ps1`. Edit the source documents, then regenerate this file.

## Included Sources

- `docs/gameplay/core_mechanics.md`
- `docs/gameplay/combat_foundation.md`
- `docs/gameplay/combat_system.md`
- `docs/gameplay/equipment_slots.md`
- `docs/gameplay/boss_mechanics.md`

---

# Source: docs/gameplay/core_mechanics.md

\# Core Mechanics – Threadbound



Threadbound’s gameplay is built on \*\*flow-state traversal\*\* and \*\*real-time ability weaving\*\* in a clean graphic 2.5D world.



The player is never meant to stop, pause, or “solve” movement like a puzzle.



Instead, gameplay is about \*\*continuous motion, adaptation, and expression\*\*.



\---



\## 🧵 Core Gameplay Loop (Thread Weaving)



Threadbound is built around \*\*real-time ability weaving\*\*:



1\. Move through the world using base traversal  

2\. Encounter an obstacle, enemy, or traversal challenge  

3\. Briefly \*\*slow time\*\*  

4\. Swap equipment using a \*\*radial menu centered on the player\*\*  

5\. Resume movement instantly and continue the chain  



This creates a continuous loop of:



> \*\*Move → Adapt → Execute → Flow\*\*



There are \*\*no hard pauses\*\*, no menu breaks, and no separation between traversal and combat.



\---



\## 🎮 Universal Player Actions (Base Kit)



These abilities are always available and ensure the game is fully completable without upgrades.



\### Movement

\- \*\*Jump\*\*  

\- \*\*Air Control\*\*  

\- \*\*Ground Movement (Run / Acceleration-based)\*\*  



\### Traversal

\- \*\*Basic Grapple\*\*

&#x20; - Free-form raycast (no fixed anchor points)

&#x20; - Short range, slower than upgraded variants

&#x20; - Used for positioning and early traversal



\- \*\*Pogo Strike\*\*

&#x20; - Downward attack bounce (Hollow Knight-style)

&#x20; - Works on enemies, hazards, and surfaces

&#x20; - Functions as both combat and traversal tool



\### Combat

\- \*\*Light Attack\*\*

\- \*\*Heavy Attack\*\*

\- \*\*Air Attacks\*\*

\- \*\*Basic Combo Chain\*\*



\---



\## 🔁 Traversal Philosophy (Flow-State Movement)



Traversal is designed around \*\*momentum and chaining\*\*, not isolated actions.



Players are encouraged to:



\- Chain movement abilities together

\- Maintain forward motion at all times

\- Transition seamlessly between traversal and combat

\- Use environment + abilities together fluidly



\---



\### Key Principles



\#### 1. Momentum Matters

\- Speed builds through chaining actions (jump → grapple → attack → land → continue)

\- Movement should feel \*\*carried forward\*\*, not reset



\#### 2. No Hard Stops

\- No stamina bars

\- No forced pauses

\- No “wait and go” mechanics



\#### 3. Combat = Movement

\- Attacks influence positioning

\- Movement abilities can be used offensively

\- Combat flows naturally out of traversal



\---



\## 🧰 Equipment as Expression (Not Progression)



Threadbound does \*\*not\*\* gate progress behind abilities.



Instead, equipment:



\- Enhances speed

\- Expands movement options

\- Enables new combat expression

\- Reveals secrets and alternate routes



\---



\### Core Rule



> \*\*Any player can complete the game using only the base kit.\*\*



Equipment exists to transform:

\- \*\*How\*\* you move  

\- \*\*How fast\*\* you move  

\- \*\*How creatively\*\* you solve encounters  



—not \*\*whether\*\* you can progress.



\---



\## 🎮 Real-Time Equipment System (Radial Weaving)



At any moment, the player can:



\- Hold input → \*\*slow time briefly\*\*

\- Open a \*\*radial menu around the player\*\*

\- Swap:

&#x20; - Gloves (grapple)

&#x20; - Boots (movement)

&#x20; - Head/Chest (utility)

&#x20; - Weapon



Releasing the input resumes gameplay instantly.



\---



\### Design Impact



This system allows:



\- Mid-air adaptation  

\- Combat combo extension  

\- Traversal correction on the fly  

\- High-skill expression through rapid decision making  



\---



\## 🔗 Ability Chaining



The core of Threadbound’s feel comes from chaining actions:



Example flow:

\- Jump → Grapple → Swing → Release → Air attack → Pogo → Dash → Continue



With equipment:

\- Jump → Swap boots mid-air → Pole vault → Swap gloves → Grapple → Slam



\---



\### Goal



> The player should feel like they are \*\*weaving movement\*\*, not executing inputs.



\---



\## 🌍 World Interaction Philosophy



The world is designed to \*\*respond to the player’s identity\*\*, not block them.



\### Environment Behavior



\- Platforms may appear or disappear based on player state  

\- Surfaces may react differently depending on equipped tools  

\- Visual cues reflect interaction possibilities  



\---



\### No Gating Rule



\- Critical paths are always traversable with base abilities  

\- Equipment creates:

&#x20; - Shortcuts  

&#x20; - safer routes  

&#x20; - expressive alternatives  



\---



\## 🧵 Player Identity Through Mechanics



Mechanics reinforce identity:



\- Movement style reflects equipped gear  

\- Combat style reflects chosen tools  

\- Visuals reflect absorbed or spared power  



The player is not assigned a class.



> \*\*The player becomes their build through action.\*\*



\---



\## 🎯 Endgame Expectation



By late game, players will:



\- Chain multiple abilities in a single sequence  

\- Swap equipment mid-combat and mid-traversal  

\- Maintain near-constant motion  

\- Express a unique personal playstyle  



\---



\## 🧠 Summary



Threadbound is not about unlocking power.



It is about:



\- Learning flow  

\- Adapting in real time  

\- Expressing mastery through movement  



\---



> You are not navigating the world.  

> You are weaving through it.

---

# Source: docs/gameplay/combat_foundation.md

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

---

# Source: docs/gameplay/combat_system.md

# Combat System – Threadbound

Threadbound combat is designed to feel like **fluid, momentum-driven action** — fast, expressive, and inseparable from movement.

There is no separation between traversal and combat.

You are always:
- moving  
- adapting  
- weaving  

Combat is not about choosing the right build beforehand.

> It is about **responding in real time**.

---

## 🧵 Core Philosophy

- Combat is an extension of traversal, not a separate mode  
- Flow is constant — no slow, methodical pacing  
- The player is never locked into a single playstyle  
- **Equipment defines expression, not identity locks**  
- Mastery comes from **how you weave tools together**, not what you equip  

---

## 🔁 Core Combat Loop

At any moment, the player can:

1. Engage with basic attacks or movement  
2. Encounter resistance (enemy pattern, positioning, pressure)  
3. Briefly **slow time**  
4. Swap weapon or equipment via radial menu  
5. Continue the sequence seamlessly  

This creates a loop of:

> **Engage → Adapt → Chain → Flow**

There is no downtime between decisions and execution.

---

## ⚔️ Universal Combat Actions

These are always available regardless of equipment.

### Basic Attack
- Fast, chainable strikes  
- Forms the backbone of all combat  

### Heavy Attack
- Slower, higher impact  
- Carries momentum and can transition into movement  

### Pogo Strike
- Downward attack that bounces off enemies or surfaces  
- Functions as both combat and traversal  

### Thread Interaction (Grapple)
- Can cancel into or out of attacks  
- Used for repositioning, combo extension, or engagement  

### Dodge / Thread Dash
- Short, responsive repositioning tool  
- Keeps combat fluid — no traditional roll or stamina system  

---

## 🎮 Real-Time Equipment Weaving (Combat Core)

Combat is built around **mid-action equipment swapping**.

At any moment:
- Slow time briefly  
- Open radial menu  
- Swap weapon or ability  
- Resume instantly  

---

### Example Combat Flow

- Engage with Greatsword (Red) heavy strike  
- Launch enemy upward  
- Swap mid-air to Ribbon Staff (Blue)  
- Continue juggle with extended reach  
- Swap to Talismans (Yellow)  
- Finish with ranged burst  

---

### Design Goal

> Combat should feel like **weaving attacks together**, not executing fixed combos.

---

## ⚔️ Weapon Styles

Each Thread Master provides a distinct weapon style.

These are not locked roles — they are tools the player can swap between freely.

---

### 🟥 Red – Greatsword (Power)

- Slow, heavy, momentum-driven  
- Wide arcs and high impact  
- Launches enemies and controls space  

**Feel:** Weighty, forceful, deliberate  

---

### 🟦 Blue – Ribbon Staff (Balance)

- Medium speed, extended reach  
- Flowing, continuous strikes  
- Excellent for spacing and aerial control  

**Feel:** Graceful, controlled, fluid  

---

### 🟨 Yellow – Talismans (Essence)

- Fast, ranged, precise  
- Projectile-based attacks and setups  
- Enables safe pressure and positioning  

**Feel:** Calculated, methodical, reactive  

---

### Universal Rules

- All weapons function in air and on ground  
- All weapons can chain into each other via swapping  
- No weapon is ever invalid — only situationally stronger  

---

## 🧰 Equipment Integration (No Hybrids)

Combat is shaped by **individual equipment effects**, not color combinations.

There are **no hybrid bonuses**.

Instead, power comes from:
- how you swap  
- when you swap  
- how you chain abilities  

---

### Gloves (Grapple – Combat Interaction)

Each color modifies grapple behavior:

- Red → aggressive pull / slam potential  
- Blue → swing / reposition flow  
- Yellow → displacement / reposition / setup  

---

### Boots (Movement – Combat Extension)

Affect aerial combat and repositioning:

- Red → aggressive downward pressure  
- Blue → vertical control / vaulting  
- Yellow → repositioning / spacing tools  

---

### Head / Chest (Utility)

- Adds situational combat effects  
- Supports control, setup, or survivability  
- Does not replace core combat loop  

---

## 🔗 Ability Chaining in Combat

Combat is built around chaining:

- Attacks → Movement → Equipment → Attacks  

Example:
- Attack → Grapple → Air combo → Swap → Continue → Dash → Finish  

---

### Key Principle

> There is no “end” to a combo — only how long the player can maintain flow.

---

## 🧠 Skill Expression

Player skill is defined by:

- Timing swaps under pressure  
- Maintaining momentum  
- Adapting to enemy behavior in real time  
- Choosing the right tool in the moment  

---

## 👁️ Boss Combat Philosophy

Bosses are designed to test:

- Adaptability  
- Flow-state mastery  
- Real-time decision making  

---

### Boss Expectations

Players are encouraged to:
- swap equipment mid-fight  
- adapt to phase changes dynamically  
- maintain pressure while repositioning  

---

### Advanced Encounters

Late-game bosses (Weaver, Follower) assume:

- full system understanding  
- rapid swapping  
- mastery of multiple weapon styles  

These encounters push the player to:
> **use everything they’ve learned — seamlessly**

---

## 🎨 Audio & Visual Feedback

- Hits produce clean graphic thread bursts  
- Impact intensity reflects weapon weight  
- Enemy damage shows thread fraying  
- Player visuals reflect current identity  

---

## 🧠 Summary

Threadbound combat is not about memorizing combos.

It is about:

- adapting in real time  
- chaining movement and attacks  
- expressing mastery through flow  

---

> You are not fighting enemies.  
> You are weaving through them.

---

# Source: docs/gameplay/equipment_slots.md

##### \# Equipment System – Threadbound

##### 

##### Threadbound’s equipment system is built around \*\*real-time expression\*\*, not progression gating.

##### 

##### Each slot modifies how the player interacts with the world and combat—but \*\*never determines whether progress is possible\*\*.

##### 

##### > Equipment changes how you play, not whether you can play.

##### 

##### \---

##### 

##### \## 🧵 Equipment Philosophy

##### 

##### \- No ability is required to complete the game

##### \- Equipment enhances:

##### &#x20; - movement expression

##### &#x20; - combat flow

##### &#x20; - traversal creativity

##### \- Players are encouraged to \*\*swap gear dynamically\*\* using the radial system

##### \- There are \*\*no hybrid bonuses\*\* — power comes from execution, not combinations

##### 

##### \---

##### 

##### \## 🎮 Equipment Slots Overview

##### 

##### | Slot        | Function                        |

##### |-------------|--------------------------------|

##### | Gloves      | Grapple / engagement tool      |

##### | Boots       | Jump / movement modifier       |

##### | Chest/Head  | Utility / special ability      |

##### | Weapon      | Combat style                   |

##### 

##### \---

##### 

##### \# 🧰 Base Equipment (Always Available)

##### 

##### The base kit ensures the game is fully playable without upgrades.

##### 

##### \---

##### 

##### \## 🧤 Base Gloves — Standard Grapple

##### 

##### \- 360° aimable raycast grapple

##### \- Attaches to surfaces and creates a climbable line

##### \- Functions more like a \*\*mobile ladder\*\* than a swing

##### 

##### \*\*Purpose:\*\*

##### \- Reliable, simple traversal

##### \- Low expression, high consistency

##### 

##### \---

##### 

##### \## 👢 Base Boots — Standard Jump

##### 

##### \- Single jump

##### \- No directional modification

##### 

##### \*\*Purpose:\*\*

##### \- Baseline mobility

##### \- Foundation for all jump augments

##### 

##### \---

##### 

##### \## 🧥 Base Chest — Core Utility

##### 

##### \- Provides \*\*base dash\*\* (short, responsive movement burst)

##### \- No special effects

##### 

##### \*\*Purpose:\*\*

##### \- Establish baseline combat mobility

##### \- Future augments expand this

##### 

##### \---

##### 

##### \## 🧵 Base Mechanics (Always Active)

##### 

##### Not tied to equipment:

##### 

##### \- Wall Cling

##### \- Pogo Strike

##### \- Basic Dash behavior

##### \- Core movement + combat actions

##### 

##### \---

##### 

##### \# 🟥 Monarch (Red) — Power

##### 

##### Focused on \*\*force, momentum, and aggression\*\*.

##### 

##### \---

##### 

##### \## 🧤 Red Gloves — Momentum Chain Grapple

##### 

##### \- Chain-based grapple with charge mechanic

##### \- Hold input to build momentum before release

##### \- Pulls the player toward the target (“yoink” effect)

##### 

##### \*\*Key Traits:\*\*

##### \- Medium range (extends via momentum)

##### \- High player displacement

##### \- Aggressive engagement tool

##### 

##### \---

##### 

##### \## 👢 Red Boots — Charge Jump

##### 

##### \- Hold to charge, release for powerful vertical or forward leap

##### 

##### \*\*Key Traits:\*\*

##### \- High force movement

##### \- Rewards commitment and timing

##### 

##### \---

##### 

##### \## 🧥 Red Chest — Unravel

##### 

##### \- Allows breaking specific environmental elements

##### \- Can be tied to charged dash or impact

##### 

##### \*\*Key Traits:\*\*

##### \- Destructive traversal

##### \- Opens alternate paths

##### 

##### \---

##### 

##### \## ⚔️ Weapon — Greatsword

##### 

##### \- Heavy, momentum-driven attacks

##### \- Wide arcs and strong knockback

##### 

##### \---

##### 

##### \# 🟦 Hermit (Blue) — Balance

##### 

##### Focused on \*\*flow, control, and momentum manipulation\*\*.

##### 

##### \---

##### 

##### \## 🧤 Blue Gloves — Pendulum Grapple

##### 

##### \- Long-range grapple

##### \- Allows swinging and momentum building

##### 

##### \*\*Key Traits:\*\*

##### \- Highest range

##### \- Momentum amplification

##### \- Rewards timing and rhythm

##### 

##### \---

##### 

##### \## 👢 Blue Boots — Pole Vault Jump

##### 

##### \- Enhanced jump using staff-like extension

##### \- Can redirect movement mid-air

##### 

##### \*\*Key Traits:\*\*

##### \- Vertical control

##### \- Aerial flexibility

##### \- Extended pogo range

##### 

##### \---

##### 

##### \## 🧥 Blue Chest — Silk Trampoline

##### 

##### \- Creates a temporary bounce surface

##### \- Can be used to build momentum or gain height

##### 

##### \*\*Key Traits:\*\*

##### \- “Slow down to speed up” gameplay

##### \- Setup-based traversal

##### 

##### \---

##### 

##### \## ⚔️ Weapon — Ribbon Staff

##### 

##### \- Medium speed, long reach

##### \- Flowing, continuous strikes

##### 

##### \---

##### 

##### \# 🟨 Sage (Yellow) — Essence

##### 

##### Focused on \*\*control, precision, and repositioning\*\*.

##### 

##### \---

##### 

##### \## 🧤 Yellow Gloves — Snap Grapple

##### 

##### \- Short-range, high-speed grapple

##### \- Instantly pulls the player forward and past the anchor point

##### 

##### \*\*Key Traits:\*\*

##### \- Fastest activation

##### \- Shorter range

##### \- Strong repositioning tool

##### 

##### \---

##### 

##### \## 👢 Yellow Boots — Manifest Foothold

##### 

##### \- Creates a temporary foothold in mid-air

##### \- Allows directional double jump

##### 

##### \*\*Key Traits:\*\*

##### \- Full directional control

##### \- Momentum override

##### \- Fast execution

##### 

##### \---

##### 

##### \## 🧥 Yellow Chest — Manifest Platform

##### 

##### \- Creates a temporary platform at target location

##### \- May interact with world layers or existing geometry

##### 

##### \*\*Key Traits:\*\*

##### \- Spatial control

##### \- Creative traversal

##### \- Setup-based movement

##### 

##### \---

##### 

##### \## ⚔️ Weapon — Talismans

##### 

##### \- Fast, ranged attacks

##### \- Precise and controlled

##### 

##### \---

##### 

##### \# 🔁 System Interaction

##### 

##### All equipment is designed to:

##### 

##### \- Chain into movement

##### \- Chain into combat

##### \- Be swapped mid-action

##### 

##### \---

##### 

##### \### Example Flow

##### 

##### \- Grapple (Blue) → Swing → Jump → Swap Boots → Redirect → Attack → Swap Weapon → Continue

##### 

##### \---

##### 

##### \## 🧠 Design Summary

##### 

##### The equipment system is not about building a perfect loadout.

##### 

##### It is about:

##### 

##### \- adapting in real time

##### \- expressing skill through movement

##### \- choosing the right tool in the moment

##### 

##### \---

##### 

##### > Your power is not what you equip.

##### > It’s how you use it.

---

# Source: docs/gameplay/boss_mechanics.md

\# Boss Mechanics – Threadbound



Boss encounters in Threadbound are designed to test \*\*flow-state mastery\*\*, \*\*adaptability\*\*, and \*\*real-time decision making\*\*.



They are not puzzles with fixed solutions.



They are dynamic systems that challenge the player to:



\- maintain momentum  

\- adapt under pressure  

\- weave abilities in real time  



\---



\## 🧵 Core Boss Philosophy



\- Bosses are an extension of the core gameplay loop  

\- Combat remains fast, fluid, and uninterrupted  

\- There is no “correct loadout” — only better execution  

\- Players are encouraged to \*\*swap equipment mid-fight\*\*  

\- Encounters reward \*\*expression, not memorization\*\*  



\---



\## ⚔️ Boss Structure



Each boss is built around:



\### Phases

\- Defined by health thresholds  

\- Introduce new patterns, pressure, or mechanics  



\### Pressure Patterns

\- Force movement, repositioning, and adaptation  

\- Punish static play  



\### Openings

\- Brief windows for aggressive play  

\- Often follow successful dodges, positioning, or counters  



\---



\## 🎮 Real-Time Adaptation



Bosses are designed to push the player to:



\- swap weapons mid-combat  

\- change traversal tools under pressure  

\- react to evolving attack patterns  



\---



\### Example Flow



\- Boss enters aggressive phase  

\- Player dodges → grapples → repositions  

\- Swaps weapon mid-air  

\- Continues combo without breaking momentum  



\---



\## ✨ Cinematic Weave Moments (RTA Bursts)



Certain moments in boss fights allow for \*\*high-impact, cinematic actions\*\* without breaking flow.



These are inspired by:

\- parry opportunities  

\- stagger windows  

\- finishing strikes  



\---



\### Trigger Conditions



Weave Moments may activate when:



\- Boss reaches a health threshold  

\- Player deals sustained damage  

\- Specific boss actions are countered  

\- Player has unlocked relevant equipment  



\---



\### Execution



When triggered:



\- Time briefly slows (not a full pause)  

\- Player is prompted to:

&#x20; - perform a specific input  

&#x20; - or quickly swap to a required tool  



Examples:

\- Equip Red Grapple → perform slam finisher  

\- Use Blue movement → launch aerial strike  

\- Use Yellow reposition → execute precision finisher  



\---



\### Design Goals



\- Reinforce mastery of the equipment system  

\- Deliver cinematic payoff without removing control  

\- Encourage players to \*\*use the right tool in the moment\*\*  



\---



\## 🧠 Advanced Encounters



Late-game bosses (Weaver, Follower) expand on this system.



They may:



\- require rapid equipment swaps  

\- respond to player behavior dynamically  

\- force use of multiple mechanics in quick succession  



\---



\### Weaver Encounter Direction



\- Designed as a \*\*full-system mastery test\*\*  

\- Encourages use of all threads  

\- May include chained Weave Moments requiring different tools  



\---



\### Follower Encounter Direction



\- Mirrors or surpasses player capability  

\- Uses multiple mechanics fluidly  

\- Tests timing, adaptation, and control  



\---



\## 🎨 Visual \& Audio Feedback



\- Weave Moments trigger clean graphic thread bursts  

\- Boss health visually “frays” as damage accumulates  

\- Successful execution produces strong visual payoff  



\---



\## 🧠 Summary



Bosses in Threadbound are not about waiting for your turn.



They are about:



\- staying in motion  

\- adapting constantly  

\- recognizing opportunity within chaos  



\---



> You do not break the boss.  

> You out-weave it.
