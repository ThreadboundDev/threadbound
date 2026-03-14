\# Contributing to Threadbound



Welcome! Threadbound is a painterly 2.5D metroidvania built in Godot 4.5xx, inspired by Hollow Knight's tight movement/combat feel, choice-driven progression, and melancholic atmosphere.



This guide is for new contributors (programmers, designers, etc.). Read this first, then dive in.



\## 1. Project Overview (Quick Read)

\- \*\*Genre\*\*: 2D/2.5D metroidvania platformer with thread-weaving mechanics

\- \*\*Engine\*\*: Godot 4.5xx (GDScript primary, some shaders)

\- \*\*Core Pillars\*\*:

&#x20; - Thread = Identity (starting color + absorbed powers shape movement/combat/visuals)

&#x20; - Choice Matters (spare/absorb Thread Masters changes world, abilities, endings)

&#x20; - Flow-State Traversal \& Combat (Hollow Knight fluidity, momentum chaining, no slow pacing)

\- \*\*Tone \& Art\*\*: Melancholic/hopeful painterly style — muted fraying backgrounds, vibrant glowing threads, silk/cloth motifs, stained-glass cinematics

\- \*\*Current Branch Focus\*\*: `feat/equipment-system`



See `docs/overview.md` for full vision \& quick reference table.



\## 2. Repo Structure (Where Things Live)
threadbound/

├── Assets/               # Sprites, tilesets, audio, concepts

├── Src/                  # All GDScript + scenes (player, archetypes, UI, etc.)

│   ├── player/           # Player controller, state machine

│   ├── archetypes/       # Red/Blue/Yellow logic (or equipment-based now)

│   ├── ui/               # HUD, radial menu, pause

│   └── ...               # bosses, levels, etc.

├── addons/               # PhantomCamera, other plugins

├── docs/                 # All design docs (source of truth for mechanics/lore)

│   ├── gameplay\_design/  # Traversal, archetypes, combat, equipment, bosses

│   ├── narrative/        # Lore, story, characters, endings

│   └── ...               # overview.md, visual\_style\_and\_palette.md, etc.

├── project.godot         # Main project file

├── CONTRIBUTING.md       # ← This file!

└── README.md             # High-level pitch + setup instructions



\## 3. Key Documents to Read First (Order Matters)

1\. `docs/overview.md` — Game vision, themes, quick reference

2\. `docs/gameplay\_design/core\_mechanics.md` — Traversal loop, universal tools, grapples

3\. `docs/gameplay\_design/archetypes.md` — Red/Blue/Yellow primaries, hybrids, pole vault, portal leap

4\. `docs/gameplay\_design/equipment\_system.md` — Slots (Gloves=grapple, Boots=jump, Chest/Head=special), palette mixing

5\. `docs/gameplay\_design/combat\_system.md` — Fast Hollow Knight-style action, weapon flavors, thread tension meter

6\. `docs/gameplay\_design/boss\_mechanics.md` — RTA cinematic bursts (Expedition 33 inspired)

7\. `docs/visual\_style\_and\_palette.md` — RGB mixing, shaders, painterly reactivity



\## 4. Things That Need Done

These are the big systems we’re focusing on right now. Work in whatever order makes sense, but the three below are the current priorities:



\*\*Equipment System\*\*  

\- Finish the radial equipment menu UI  

\- Add all nine equippable items as selectable options in the menu  

\- Implement and test each of the nine equipped abilities (grapple/jump/special variants)



\*\*Base Character Controller\*\* (very high priority — everything else builds on this)  

\- Implement the core un-augmented abilities: base jump, base pogo, base wall cling, base grapple, and base combat (fists)  

\- This is the foundation for all later augmentation via equipment



\*\*Full Combat System\*\*  

\- Character combat actions and combos  

\- Complex integration for all equipped items (aerial combat, grapple attacks, special interactions, etc.)  

\- Enemy behaviors and enemy systems

\- Action Guage + Super Moves



See GitHub Issues for any smaller tasks or bugs that branch off these.



\## 5. Development Workflow

\- Branch naming: `feat/`, `fix/`, `refactor/`, `docs/`

\- Commits: Conventional style (e.g. `feat: implement Blue pole vault`, `fix: grapple raycast collision`)

\- Pull requests: Small \& focused; reference issues/docs

\- Testing: Run on Windows/Linux; always test pure Red/Blue/Yellow runs

\- Godot settings: Use PhantomCamera addon, 2.5D parallax layers enabled

\- Communication: \[your chat tool] + GitHub comments



\## 6. Quick Start (Get Running in <5 min)

1\. Clone repo: `git clone https://github.com/ChaseKing77/threadbound.git`

2\. Checkout branch: `git checkout feat/equipment-system`

3\. Open in Godot 4.5xx

4\. Run main scene (usually `main.tscn` or `test\_level.tscn`)

5\. Read `docs/overview.md` and `docs/gameplay\_design/core\_mechanics.md`



Questions? Ping Chase in chat or open an issue. Welcome aboard — let's weave something special! 🧵

