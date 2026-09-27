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
- Baseline action that costs no AP and does not restore AP, grapple, or air jump
- Successful contact immediately recovers the aerial strike for continued pogo chains
- Rebound launches at normal-jump strength and briefly ignores jump-cut gravity, since pogo uses Attack + Down rather than requiring Jump to remain held
- Horizontal momentum and air control remain available during the rebound
- Uses frames 1–11 of the aerial double attack as a dedicated single-strike clip
- Red greybox hazards are pogoable during block-tool traversal prototyping

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

## Impact Feedback Rules

Combat feedback is resolved from the accepted hit at the receiver. Attacker-side
hit-confirm callbacks may update gameplay state such as momentum, but they must
not request a second global hit pause or camera shake for the same collision.

- `DamageData.hitstun` controls the receiver's hurt duration.
- Concurrent hit-pause requests share one real-time window and use the longest
  requested end time.
- Concurrent camera-shake requests share one camera tween, preserve its original
  offset, and use the strongest requested shake.
- Multi-target attacks therefore create one deliberate impact beat instead of
  stacking independent feedback effects.

## Current Attack Roles

The first universal attack set uses different commitment and reward profiles
instead of treating every animation as the same hit:

- Moving opener: 25 damage with moderate hitstun and knockback.
- Moving finisher: two hits at 18 and 25 damage, with the second hit providing
  the stronger finish.
- Stationary combo: 23 damage followed by a committed 30-damage strike. The
  player is rooted through the second hit, then may dash-cancel the
  recovery.
- Backpedal combo: a spacing-focused 21-damage opener followed by 17- and
  23-damage hits.
- Air combo: the fastest and most flexible profile, dealing 16 then 21 damage.

Normal recovery may be dash-cancelled. Committed attacks cannot be cancelled
before their impact. High momentum grants 5% damage and 10% attack speed; full Flow
grants 10% damage and 15% attack speed.

### Neutral Special: Smash

The neutral special is a stationary, two-action-point commitment that controls
space around the weapon's ground contact.

- It can only begin while grounded; jumping and horizontal movement remain
  committed through impact.
- Charges around the raised weapon, follows its overhead swing, and releases
  when the weapon reaches the ground on animation frame 18.
- Hits once in a 220-pixel circular area centered on that ground contact.
- Deals 70 damage within the inner 99 pixels, then smoothly falls to about 39
  damage at the outer edge.
- Hitstun falls from 0.30 to 0.24 seconds with distance; radial knockback retains
  at least 75% of its inner strength and adds upward lift.
- Telegraphs the release with inward-gathering threads around the weapon, then
  expands from the impact through a bright inner core, an ivory-and-gold outer
  ring, and ground fragments.
- Uses one stronger release shake and one coalesced hit-pause window.
- Roots the player through impact, then permits a dash cancel during the final
  recovery window.

Its purpose is crowd control and breathing-room creation. Basic attacks remain
the faster and more efficient option against a single exposed target.

### Dash / Thread Dodge

The dash is both a repositioning tool and the player's deliberate evade:

- Moves at 1,150 pixels per second for 0.30 seconds. Even at low momentum, the
  resulting distance clears the widest current enemy with a safety margin.
- Uses a 0.65-second cooldown measured from dash start.
- Removes the player hurtbox from enemy contact queries for the movement window
  plus 0.06 seconds of grace, preventing contact separation from shoving an
  enemy instead of carrying the player through it.
- Keeps world collision active and does not pass through walls.
- Blocks attacks from starting mid-dash and overriding the evade movement.
- Uses a universal ivory-and-gold afterimage so the protected window is readable
  regardless of equipped chest color.

### Grapple Strike

Pressing Attack while tethered to an enemy performs a dedicated grapple strike
instead of pulling the player into the enemy body.

- The approach stops outside the combined player and enemy collision shapes.
- The dedicated approach pose renders at `0.82` of the ordinary Dash sprite
  scale so its apparent body size matches the rest of the player animation set.
- Contact damage is ignored only during the approach; authored enemy attack
  hitboxes remain dangerous.
- The confirmed strike starts at 30 damage, applies 0.22 seconds of hitstun,
  strong knockback, and a small upward player recoil that restores safe spacing.
- Grapples launched from less than 35% of maximum range retain base damage.
  Beyond that point, a smooth distance bonus rises to 25% at full range.
- The distance bonus multiplies the existing momentum attack bonus. A full-range
  Flow strike therefore deals about 41 damage instead of 30.
- The grapple retracts after one confirmed strike. Ordinary grapple arrival no
  longer deals an automatic damage tap.
- Blue and Yellow grapples can target enemies. Yellow uses the strike branch
  rather than teleporting into an enemy. Red's charged attach damage remains a
  separate setup hit and cannot double-trigger the grapple strike.

## Meditation Recovery

Meditation is an intentional pause in combat rather than a source of free
momentum. After a short hold, the player enters a one-shot sitting transition
and remains in the final seated pose until the input is released or another
action interrupts it.

- Spent action points recharge one at a time while meditating, beginning with
  the point closest to being restored.
- Meditation doubles AP recharge speed; ordinary combat recharge remains
  parallel across all spent points.
- Once fully seated, healing pulses every 0.8 seconds and consumes 10 momentum
  per pulse.
- Healing has diminishing returns: each pulse restores 5% of maximum health
  below 35% health, 4% from 35% to 55%, and 3% from 55% to 75%.
- Meditation cannot restore health above 75%; save points remain the full-heal
  recovery option.
- Entering meditation during Flow shortens the pulse interval to 0.6 seconds
  without improving total momentum efficiency.
- Meditation displays the same character-bound outline and glow as Flow at
  reduced strength. Its lower-pitched, quieter ignition sound communicates
  reaching toward Flow rather than fully entering it.
- Movement, jumping, dashing, attacking, taking damage, leaving the ground, or
  releasing the meditation input interrupts the state.

### Flow Presentation

Full Flow must read as a peak combat state at normal gameplay zoom:

- A bright identity-tinted silhouette hugs the complete character.
- The live player frame drives both the close silhouette halo and short upward
  energy licks, so the effect follows every pose instead of relying on a fixed
  humanoid-shaped gap.
- A soft local glow blends the player's equipped thread identities and pulses
  with Flow intensity.
- Persistent rear loops, orbiting filaments, chest knots, and grounded weaves
  are intentionally omitted so the character outline remains clean.
- Brief ignition, movement trails, and action bursts provide event emphasis
  without obscuring the character or exceeding the 32-effect safety cap.

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
