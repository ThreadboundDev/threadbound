# Blue Biome Swordfish Ecosystem and Environmental Combat

Status: Approved direction for prototyping. Specific timings, damage values, and encounter layouts remain subject to playtesting.

This document records the approved enemy concepts and environmental interactions for the Blue Biome. The biome centers on stillness, balance, and the redirection of stored motion. Its creatures should affect combat, traversal, environmental puzzles, and one another rather than functioning as isolated obstacles.

## Core Philosophy

The Blue Biome explores Stillness and Balance through creatures that conserve motion before releasing it in decisive bursts. The player succeeds by reading commitment, controlling position, and redirecting force instead of overcoming resistance through raw damage.

## Swordfish Duelist - Common Enemy

A native aquatic predator inspired by swordfish anatomy and the principles of battōjutsu and iaijutsu, without presenting the creature as a literal samurai. Its identity comes from restraint, alignment, a readable point of commitment, and one precise release of speed.

### Behavior Loop

**Still -> Detect -> Align -> Lock -> Dash -> Recover -> Still**

- **Still:** Remains stationary and conserves motion until it acquires the player within line of sight.
- **Detect:** Recognizes a valid target and begins the attack sequence.
- **Align:** Turns toward the player's position before committing to a fixed trajectory.
- **Lock:** Clearly telegraphs that the attack direction is fixed, giving the player a readable dodge and redirection window.
- **Dash:** Executes a rapid, straight-line piercing attack. The dash can damage the player, other enemies, and designated environmental surfaces.
- **Recover:** Completes a committed recovery, settles into a new stationary position, and becomes ready to begin the loop again.

### Combat and Ecosystem Rules

- The attack direction becomes fixed before the dash and remains fixed throughout the committed attack.
- The telegraph must communicate the lock state clearly enough for deliberate baiting and redirection.
- The dash can damage other enemies, allowing the swordfish to become part of the biome's broader ecosystem.
- After each dash, the swordfish resets into stillness at its new location instead of becoming a conventional roaming pursuer.

### Elite Variant

The elite variant uses a restrained color or marking change so it remains recognizable as the same species. It executes multiple consecutive dashes before returning to stillness, while preserving the common enemy's alignment, trajectory lock, commitment, and recovery rules.

## Environmental Interaction

Swordfish dashes can fracture designated barriers that resist the player's ordinary attacks. These barriers turn the enemy's existing combat behavior into a traversal and puzzle tool without introducing a separate command or control mechanic.

### Potential Applications

- Hidden passages and optional rewards.
- Breakable obstacles in submerged ruins.
- Multi-step puzzles that require the player to relocate a swordfish through successive dashes.
- Interactions with water bulbs and other momentum-based traversal systems.

### Teaching and Consistency Rules

- Fracturable barriers use consistent visual and audio cues wherever they appear.
- The player's first lesson should be an authored, natural encounter in which a swordfish breaks a barrier without requiring prior knowledge.
- Later optional uses should be discoverable through observation and experimentation.
- Puzzle relocation relies on the swordfish's normal dash and reset loop. The creature should not become an ordinary roaming pursuer for these scenarios.

## Bellstriker - Elite Enemy

The Bellstriker is an aggressive amphibious mantis shrimp that pursues the player through water and onto nearby land. It attacks with explosive claw strikes followed by committed recovery windows. Its active pursuit and blunt aggression create a deliberate contrast with the Swordfish Duelist's stationary, precision-based hunting behavior.

## Stillwater Tortoise - Midpoint Boss

The Stillwater Tortoise is an ancient, heavily armored creature whose shell resists direct attacks. The name is provisional.

### Core Encounter Mechanic

The player breaks the tortoise's defense by redirecting Swordfish Duelists into its shell. The player baits a swordfish attack, waits for trajectory lock, then dodges so the committed dash strikes the boss.

- Successful swordfish impacts fracture the shell.
- Each fracture creates a temporary opportunity for direct damage.
- The tortoise uses slow, deliberate defensive movements and heavy attacks to disrupt positioning and complicate the baiting setup.
- The encounter tests a mechanic already introduced through ordinary combat and environmental exploration instead of relying on a new boss-specific ability.

## Prototype Priorities

1. Implement the common swordfish's complete behavior loop.
2. Enable swordfish collision damage against other enemies.
3. Add a recognizable barrier that can be fractured by a swordfish dash.
4. Test swordfish redirection puzzles and relocation across successive dashes.
5. Implement the Bellstriker's amphibious pursuit behavior.
6. Prototype the Stillwater Tortoise shell-breaking encounter.
7. Tune group encounters, recovery windows, and interactions with water bulbs.

## Design Principle

**The player learns to redirect motion rather than overcome resistance through force.**
