# Threadbound Design Master

> Generated from the maintained source documents by `tools/build_upload_docs.ps1`. Edit the source documents, then regenerate this file.

## Included Sources

- `docs/design/color_system.md`
- `docs/design/enemy_design.md`
- `docs/design/gameplay_philosophy.md`
- `docs/design/identity_and_appearance.md`
- `docs/design/level_design_guidelines.md`
- `docs/design/progression_and_choices.md`
- `docs/design/project_structure_and_naming.md`

---

# Source: docs/design/color_system.md

# Color System – Threadbound

Color in Threadbound is not cosmetic.

It is a direct reflection of:
- player choice  
- identity  
- power  

---

## 🧵 Core Principle

> Color is the visual language of identity.

Every major system reinforces this:
- progression  
- equipment  
- world response  

---

## 🎨 The Three Threads

Each primordial thread corresponds to a color:

- 🟥 Red — Power  
- 🟦 Blue — Balance  
- 🟨 Yellow — Essence  

---

## 🔁 Color Acquisition

Color is gained or lost through player decisions.

---

### Absorb

- Adds that thread’s color to the player  
- Increases saturation  
- Intensifies visual presence  

---

### Spare

- Reduces overall saturation  
- Moves the player toward white  
- Simplifies visual form  

---

## 🎨 Color Blending

When multiple threads are absorbed:

- Colors blend using an additive model  
- Identity becomes layered and complex  

Examples:

| Threads Absorbed | Resulting Color |
|------------------|----------------|
| Red              | Red            |
| Blue             | Blue           |
| Yellow           | Yellow         |
| Red + Blue       | Purple         |
| Red + Yellow     | Orange         |
| Blue + Yellow    | Green          |

---

## 🌑 Extremes

### Full Absorption

- All threads absorbed  
- Color collapses toward **black**  

**Represents:**
- overload  
- dominance  
- total accumulation  

---

### Full Sparing

- No threads absorbed  
- Color fades toward **white**  

**Represents:**
- restraint  
- detachment  
- absence of control  

---

## 🎭 Visual Behavior

Color affects:

- Player silhouette  
- Cloth detailing  
- Glow intensity  
- Environmental reactions  

---

## 🌍 World Interaction

The world subtly reacts to player color:

- NPC tone shifts  
- Environmental lighting adjusts  
- Visual effects reflect identity  

---

## 🎮 Gameplay Integration

Color does NOT:

- lock abilities  
- determine access  

Color DOES:

- reflect player history  
- reinforce identity  
- communicate choices visually  

---

## 🧠 Summary

Color in Threadbound is not a system layered on top.

It is embedded in everything.

---

> You are not choosing a color.

You are revealing one.

---

# Source: docs/design/enemy_design.md

# Enemy Design – Threadbound

Enemies in Threadbound are designed to **reinforce flow-state gameplay**, not interrupt it.

They are not obstacles to stop the player.

They are **forces that shape movement, decision-making, and expression**.

---

## 🧵 Core Philosophy

### Flow First

- Enemies should never force the player to stop moving
- No long invulnerability phases
- No waiting for “turns”

> Combat remains continuous, reactive, and fluid

---

### Movement Pressure

Enemies exist to influence:

- positioning  
- momentum  
- timing  

Not to create puzzles or hard locks.

---

### Expression Over Difficulty

- All enemies are beatable with the base kit
- Skillful players can:
  - chain attacks
  - maintain momentum
  - eliminate enemies efficiently

---

### Thematic Consistency

Enemies reflect the world:

- Monarch → force, domination  
- Hermit → flow, balance  
- Sage → perception, illusion  
- Weaver → imitation, control  
- Reclaimer → removal, correction  

---

## 🧶 Enemy Categories

---

# 1. Universal Enemies

These appear across multiple regions and reinforce core themes.

---

## 🧵 The Frayed (Weaver Constructs)

Humanoid thread-beings created from incomplete or forced weaving.

They resemble the Threadborne—but lack identity, choice, or autonomy.

---

### Visual Identity

- Cloth-based humanoids  
- Slightly distorted proportions  
- Imperfect stitching / frayed edges  
- Muted or unstable coloration  

---

### Behavior

- Basic combat patterns  
- Reactive movement  
- Occasional imitation of player-like actions (imperfect)

---

### Variants

**Frayed Striker**
- Fast melee attacker  
- Low durability  

**Frayed Brute**
- Slow, heavy attacks  
- High durability  

**Frayed Skirmisher**
- Jumps, repositions, avoids direct engagement  

---

### Design Purpose

- Establish combat baseline  
- Reinforce theme of “false Threadborne”  
- Contrast player freedom with artificial behavior  

---

## 🐛 Reclaimer Echoes

Early manifestations of the Reclaimers found throughout the world.

They are not aggressive in a traditional sense.

They **approach, drain, and correct**.

---

### Visual Identity

- Insectoid forms (silk-based, layered bodies)  
- Black / white palette  
- Minimal color presence  

---

### Behavior

- Drift toward the player  
- Apply pressure through proximity  
- Do not “attack” in traditional ways  

---

### Effects on Player

- Slight desaturation of screen  
- Reduced audio clarity  
- Minor ability suppression (subtle early)  

---

### Variants

**Thread Leech**
- Attaches briefly  
- Slows movement  

**Pale Watcher**
- Observes, then emits draining pulse  

---

### Design Purpose

- Foreshadow Reclaimer domain  
- Introduce “loss of power” concept  
- Create unease rather than direct threat  

---

# 🟥 2. Monarch Domain Enemies (Red – Power)

Theme: **Force, aggression, domination**

---

## Core Identity

- Heavy, grounded enemies  
- Direct, forceful attacks  
- Minimal subtlety  

---

### Enemy Types

**Ironbound Soldier**
- Armored melee unit  
- Slow but powerful strikes  

---

**Chain Thrower**
- Launches chain-based projectiles  
- Pulls player or closes distance  

---

**Berserk Thrall**
- Fast, aggressive  
- Rushes the player with little defense  

---

**Siege Beast**
- Large creature or construct  
- Breaks environment and disrupts terrain  

---

## 🟥 Mini-Boss: The Monarch’s War Engine

A massive construct or beast used to enforce rule.

---

### Concept Options

- Living siege engine  
- Bound war creature  
- Thread-infused armored beast  

---

### Mechanics

- Breaks parts of the arena  
- Forces constant movement  
- Heavy, telegraphed attacks  

---

### Purpose

- Introduce large-scale pressure  
- Reinforce Red’s destructive nature  

---

# 🟦 3. Hermit Domain Enemies (Blue – Balance)

Theme: **Flow, rhythm, restraint**

---

## Core Identity

- Movement-based enemies  
- Rhythm and spacing focused  
- Encourage patience and timing  

---

### Enemy Types

**Silk Drifter**
- Floating enemy  
- Slow, controlled movement  

---

**Pole Sentinel**
- Uses vault-like movement  
- Repositions constantly  

---

**Tide Guardian**
- Attacks in rhythmic intervals  
- Moves with environmental timing  

---

**Echo Form**
- Slightly mirrors player movement with delay  

---

## 🟦 Mini-Boss: The Deepbound Leviathan

A massive aquatic or silk-based creature tied to the Hermit’s domain.

---

### Concept

- A creature beneath the water or void  
- Only partially visible at times  

---

### Mechanics

- Arena shifts with movement  
- Forces timing and positioning  
- Movement-based attack patterns  

---

### Purpose

- Reinforce rhythm-based gameplay  
- Contrast Red’s aggression  

---

# 🟨 4. Sage Domain Enemies (Yellow – Essence)

Theme: **Perception, control, illusion**

---

## Core Identity

- Unpredictable behavior  
- Indirect combat  
- Manipulation of space or perception  

---

### Enemy Types

**Mirage Caster**
- Creates illusion copies  
- Real one must be identified  

---

**Talisman Warden**
- Ranged attacker  
- Uses delayed or placed attacks  

---

**Phase Walker**
- Short-range teleportation  
- Difficult to track  

---

**Reality Anchor**
- Distorts space locally  
- Alters player movement behavior  

---

## 🟨 Mini-Boss: The Living Archive

A non-humanoid entity formed from knowledge or memory.

---

### Concept Options

- Sentient book construct  
- Floating library mass  
- Shifting abstract entity  

---

### Mechanics

- Arena changes subtly  
- Illusions affect perception  
- Forces awareness over aggression  

---

### Purpose

- Test player awareness  
- Reinforce illusion mechanics  

---

# 🐛 5. Reclaimer Enemies (Late / Secret Domain)

Theme: **Removal, correction, neutrality**

---

## Core Identity

- Not aggressive  
- Not emotional  
- Pure function  

---

### Behavior Philosophy

They do not attack.

They **undo**.

---

### Effects on Player

- Color desaturation  
- Audio dampening  
- Ability suppression  

---

### Enemy Types

**Thread Leech**
- Drains mobility temporarily  

---

**Silence Weaver**
- Suppresses sound cues  

---

**Null Crawler**
- Reduces visual clarity / color intensity  

---

## 🐛 Mini-Boss: Proto-Reclaimer

A precursor to the main Reclaimer boss.

---

### Concept

- Partially humanoid  
- Partially insectoid  
- Unstable form  

---

### Mechanics

- Temporarily disables abilities  
- Forces base-kit gameplay  
- Slow, oppressive presence  

---

### Purpose

- Prepare player for full Reclaimer encounter  
- Reinforce identity stripping  

---

# 🧠 Design Rules Summary

- Enemies should never halt player flow  
- Enemies should influence movement, not restrict it  
- Enemy complexity should come from interaction, not mechanics overload  
- Each region should contain:
  - 3–4 core enemy types  
  - 1 mini-boss  
  - 1 major boss  

---

# 🧵 Final Design Intent

Enemies in Threadbound are not just opposition.

They are:

- reflections of the world  
- expressions of philosophy  
- pressure against the player’s identity  

---

> You are not fighting enemies.

> You are weaving through resistance.

---

# Source: docs/design/gameplay_philosophy.md

\# Gameplay Philosophy – Threadbound



Threadbound is built on three core pillars:



\---



\## 🧵 Thread = Identity



Every system reinforces identity:



\- Your abilities  

\- Your movement  

\- Your combat style  

\- Your visual form  



are all shaped by your choices.



There are no classes.



> You become your build through action.



\---



\## ⚖️ Choice Matters



Every major decision has lasting impact:



\- Absorb → gain power, change identity  

\- Spare → retain neutrality, reshape the world  



There is no optimal path.



Each choice affects:

\- gameplay expression  

\- world state  

\- narrative outcome  



\---



\## 🌊 Flow-State Gameplay



Threadbound is designed to feel:



\- fast  

\- fluid  

\- expressive  



Movement and combat are one continuous system.



Players are encouraged to:

\- chain actions together  

\- maintain momentum  

\- adapt in real time  



\---



\### Core Loop



> Move → Adapt → Execute → Flow  



\---



\## 🎮 Expression Over Optimization



Threadbound is not about finding the best build.



It is about:

\- mastering systems  

\- expressing skill  

\- adapting dynamically  



\---



\## 🧠 Player Experience Goals



The player should feel:



\- in control at all times  

\- free to experiment  

\- rewarded for creativity  

\- constantly in motion  



\---



\## 🎯 Design Rule



> Systems should enable expression, not restrict it.



\---



\## 🧠 Summary



Threadbound is about:



\- identity through mechanics  

\- meaning through choice  

\- mastery through flow  



\---



> You are not playing a role.  

> You are shaping one.

---

# Source: docs/design/identity_and_appearance.md

\# Identity \& Appearance System – Threadweave



In Threadbound, the player’s appearance is not customized.



It is \*\*earned\*\*.



Your form evolves with every choice, visually telling the story of:

\- what you take  

\- what you reject  

\- and what you become  



\---



\## 🧵 Core Principle



> Your identity is reflected through color, form, and silhouette.



Every major system contributes to how the player looks:

\- progression choices  

\- equipped tools  

\- absorbed threads  



\---



\## 🎮 Base State (Threadborne)



The player begins as a \*\*neutral Threadborne\*\*:



\- Pale, desaturated cloth  

\- Minimal detailing  

\- No dominant color  

\- Simple silhouette  



This represents:

\- potential  

\- lack of identity  

\- unformed purpose  



\---



\## 🎨 Color System (Thread Influence)



Color represents absorbed power.



Each thread corresponds to a color channel:



\- 🟥 Red — Power  

\- 🟦 Blue — Balance  

\- 🟨 Yellow — Essence  



\---



\### Absorb



\- Increases that thread’s color influence  

\- Adds saturation and intensity  

\- Introduces visual complexity  



\---



\### Spare



\- Reduces overall saturation  

\- Pushes the player toward white  

\- Simplifies visual form  



\---



\## 🎨 Color Behavior



| Action        | Result                                  |

|---------------|------------------------------------------|

| Absorb one    | Strong single-color identity             |

| Absorb multiple | Blended color identity (RGB mixing)    |

| Spare         | Desaturated, pale appearance             |

| Absorb all    | Blackened / overloaded appearance        |



\---



\## ✨ Visual Progression



As players absorb more:



\- Colors deepen and intensify  

\- Cloth gains complexity  

\- Subtle glow and energy effects appear  



As players spare:



\- Color fades  

\- Form simplifies  

\- Visual noise decreases  



\---



\## 🧰 Equipment \& Silhouette



Equipment defines silhouette and visual identity.



Each absorbed Thread Master introduces distinct styling:



\---



\### 🟥 Monarch (Red – Power)



\- Heavy, armored elements  

\- Sharp edges, aggressive shapes  

\- Visual weight and impact  



\---



\### 🟦 Hermit (Blue – Balance)



\- Flowing fabrics and ribbons  

\- Smooth, curved silhouettes  

\- Emphasis on motion  



\---



\### 🟨 Sage (Yellow – Essence)



\- Light, layered garments  

\- Floating elements (rings, halos, scrolls)  

\- Subtle, controlled asymmetry  



\---



\## 🎭 Visual Composition



The player’s final appearance is a combination of:



\- equipped gear (form)  

\- absorbed threads (color)  

\- choices made (tone and saturation)  



\---



\### Important Rule



> Form comes from equipment.  

> Color comes from identity.



\---



\## 🔁 Dynamic Expression



As players swap equipment:



\- silhouette changes in real time  

\- visual identity shifts moment-to-moment  



This reinforces:

\- gameplay expression  

\- system mastery  

\- player agency  



\---



\## 🧠 Narrative Reinforcement



Appearance communicates narrative state:



\- Saturated → powerful, consumed, dominant  

\- Desaturated → restrained, distant, detached  

\- Mixed → conflicted, evolving  



\---



\## 🌑 End-State Visuals



Final appearance reflects the player’s journey:



\- Pale (Spared path) → clarity, restraint  

\- Mixed → balance, conflict  

\- Blackened (Absorbed all) → overload, corruption  



\---



\## 🧠 Summary



Threadbound’s visual identity system ensures:



\- no two players look the same  

\- choices are always visible  

\- gameplay and narrative are visually unified  



\---



> You do not choose how you look.  

> You become it.

---

# Source: docs/design/level_design_guidelines.md

\# Level Design Guidelines – Threadbound



Threadbound levels are designed to support \*\*flow-state traversal\*\* and \*\*player expression\*\*.



The world is static at its core, but subtly reacts to the player’s identity and equipment.



\---



\## 🧵 Core Principles



\### 1. No Hard Gating



All critical paths must be completable using \*\*base abilities only\*\*.



Equipment should:

\- enhance traversal  

\- open alternate routes  

\- reward mastery  



—but never block progression.



\---



\### 2. One Path, Many Expressions



Every space should support:



\- a baseline route (safe, reliable)  

\- multiple expressive routes (faster, riskier, more complex)  



\---



\### 3. Reward Skill, Not Unlocks



Players who master movement should:



\- move faster  

\- take better routes  

\- discover hidden paths  



\---



\### 4. Maintain Flow



Level layouts should:



\- encourage continuous movement  

\- avoid forced stops or waiting  

\- support chaining actions  



\---



\### 5. Subtle World Reactivity



The environment may respond to:



\- equipped tools  

\- player identity (color state)  

\- progression choices  



This should feel \*\*natural and woven into the world\*\*, not mechanical.



\---



\## 🎮 Traversal Design



Rooms should include:



\- a clear baseline route  

\- optional expressive routes  

\- opportunities for chaining movement  



\---



\### Example Structure



\- Entry → neutral traversal  

\- Mid-section → branching expressive paths  

\- Exit → convergence  



\---



\## 🧩 Environmental Interaction



Examples of responsive elements:



\- destructible surfaces (Red)  

\- swing points (Blue)  

\- illusion-based paths (Yellow)  

\- temporary platforms or tools  



\---



\## 🔁 Backtracking



Levels should reward revisiting:



\- new routes  

\- faster traversal  

\- hidden areas  

\- environmental changes  



\---



\## 🌍 Region Identity



Each region should reinforce its thread:



\- \*\*Red (Monarch)\*\* → force, collapse, destruction  

\- \*\*Blue (Hermit)\*\* → flow, balance, verticality  

\- \*\*Yellow (Sage)\*\* → illusion, control, manipulation  



\---



\## 🧠 Playtesting Checklist



\- Can the level be completed with base abilities?  

\- Do advanced tools improve flow without gating progress?  

\- Are alternate routes meaningful?  

\- Does the level support continuous movement?  

\- Does the environment reflect the player’s identity?  



\---



\## 🧠 Summary



Level design in Threadbound is about:



\- supporting movement  

\- enabling expression  

\- rewarding mastery  



\---



> The world is not an obstacle.  

> It is something to be woven through.

---

# Source: docs/design/progression_and_choices.md

# Progression & Player Choices – Threadbound

Progression in Threadbound is not about unlocking access.

It is about **transforming identity**.

Every major choice reshapes:
- your abilities  
- your appearance  
- the world around you  

---

## 🧵 Core Progression Philosophy

- Progression does **not gate movement or access**  
- The entire game is completable with the base kit  
- Choices change:
  - how you play  
  - how the world reacts  
  - how the story unfolds  

---

## 🎮 Starting State

The player begins as the **Threadborne**:

- Neutral, unbound form  
- Access to base equipment:
  - Standard Grapple  
  - Base Jump  
  - Base Dash  
- No color dominance  

---

## 🌍 World Structure

- Three primary regions:
  - Monarch (Red — Power)  
  - Hermit (Blue — Balance)  
  - Sage (Yellow — Essence)  

- Regions can be completed in **any order** after the opening sequence  

---

## ⚔️ Thread Master Decisions

After defeating a Thread Master, the player must choose:

| Choice     | Mechanical Effect                                      | Visual / Narrative Effect                          |
|------------|--------------------------------------------------------|---------------------------------------------------|
| **Absorb** | Unlock that Master's equipment set (Gloves/Boots/Chest + Weapon) | Color shifts toward that thread, world reacts with fear or tension |
| **Spare**  | No equipment gained                                    | Character desaturates toward white, world becomes calmer / hopeful |

---

## 🎨 Identity Through Color

Your appearance reflects your choices:

- Absorbing a thread increases that color influence  
- Sparing reduces saturation (toward white)  
- Multiple absorbs blend colors  
- Full saturation leads toward **black (overload of threads)**  

---

### Example Outcomes

| Choices              | Resulting Identity        |
|----------------------|--------------------------|
| Spare all            | Pale / white (detached)  |
| Absorb one           | Dominant single color    |
| Absorb multiple      | Blended identity         |
| Absorb all           | Blackened / overwhelmed  |

---

## 🧰 Equipment Progression

Each absorbed Thread Master grants:

- Gloves (Grapple variant)  
- Boots (Movement variant)  
- Chest/Head (Utility ability)  
- Weapon (Combat style)  

---

### Important Rule

> Equipment expands expression — it does not unlock progression.

---

## 🔁 Player Expression

As progression continues, players:

- gain more tools  
- swap between them in real time  
- develop a unique playstyle  

---

## 🧠 World Reaction

The world subtly changes based on your choices:

- NPC behavior shifts  
- Environmental tone changes  
- Dialogue reflects your path  
- Visual atmosphere responds to your identity  

---

## 🕳️ Endgame Direction

Player choices determine:

- final encounter tone  
- available paths and encounters  
- visual state of the world  
- ending outcome  

---

## 🧠 Summary

Progression in Threadbound is about:

- what you choose to take  
- what you choose to leave behind  
- and what those choices make you  

---

> You are not unlocking power.  
> You are becoming it.

---

# Source: docs/design/project_structure_and_naming.md

# Project Structure and Naming

This document defines the cleanup direction for Threadbound files and folders. It is meant to keep the project readable for collaborators without forcing risky path renames during unrelated gameplay work.

## Current Roots

- `Assets/` stores art, UI images, animation source exports, and importable visual assets.
- `Src/` stores Godot scenes, scripts, resources, UI, characters, environment, equipment, and managers.
- `docs/` stores design, gameplay, narrative, art direction, and archived historical notes.

Keep these root folders as-is until a dedicated project-structure migration is planned.

## New Files

Use Godot-friendly naming for new runtime files:

- Files and folders: `snake_case`
- GDScript classes: `PascalCase`
- Scene node names: `PascalCase`
- Signals, variables, functions, and input actions: `snake_case`

Examples:

- `base_gloves.gd`
- `base_grapple_state.gd`
- `radial_menu.tscn`
- `threadborne_player.tscn`
- `class_name BaseGloves`

## Runtime Paths

Avoid spaces, punctuation-heavy names, and temporary suffixes in paths that Godot loads directly.

Preferred:

- `Assets/threadborne/equipment/base_grapple_rope.png`
- `Src/equipment/base_gloves.gd`

Avoid:

- `Base Grapple Rope.png`
- `Base_Grapple_Rope&Needle.png`
- `radial_menu.tscn11067775801.tmp`
- `SomeSprite.png~`

Existing paths do not need to be renamed immediately. Rename old paths only in focused cleanup commits where Godot import files, scene references, and scripts can be checked together.

## Art Assets

For exported runtime art, prefer stable descriptive filenames in `snake_case`.

For source art files, keep the original working files when they are useful, but do not commit editor backups or autosaves. The `.gitignore` excludes common temporary files such as `*~`, `*.tmp`, and Godot temporary scene saves.

## Documentation

Use lowercase `snake_case` for new docs:

- `base_kit_polish_plan.md`
- `combat_direction.md`
- `project_structure_and_naming.md`

When a document becomes obsolete but still has reference value, move it to:

`docs/archive/YYYY-MM-DD_short_reason/`

Each archive folder should include a short `README.md` explaining why the material was archived.

## Branches and Pull Requests

Use short branch names that describe the work:

- `docs-cleanup`
- `base-grapple-polish`
- `animation-state-cleanup`
- `equipment-ui-pass`

Keep pull requests focused around one kind of change so review stays approachable.
