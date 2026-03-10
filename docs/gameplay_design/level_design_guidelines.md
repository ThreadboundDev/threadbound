\# Level Design Guidelines – Threadbound



Threadbound levels are hand-crafted, painterly spaces that breathe with the player's choices. The world is static at its core, but \*\*thread-responsive elements\*\* subtly adapt to the player's identity (starting archetype + absorbed colors + equipped tools). This creates the illusion of a living tapestry that rewrites itself around the Threadborne.



\## Core Principles



1\. \*\*One Path, Many Expressions\*\*

   Every critical progression path must be traversable using \*\*only the base abilities of any single starting archetype\*\* (pure Red, pure Blue, or pure Yellow).

   No section may require an absorbed tool or hybrid ability to pass.



2\. \*\*The World Reacts\*\*

   Use \*\*thread-responsive elements\*\* (platforms, walls, hazards, decorations) that appear, disappear, modify, or change behavior based on:

   - Current archetype

   - Absorbed colors

   - Equipped tools (Gloves/Boots/Chest-Head)

   - Spare/Absorb choices (global flags)



3\. \*\*Equip Value Through Transformation, Not Gating\*\*

   Unlocked tools should \*\*transform\*\* how a section feels to traverse:

   - Faster / Safer / More expressive

   - Reveal secrets or alternate storytelling

   But never create a hard gate.



4\. \*\*Favor Subtlety and Theme\*\*

   Changes should feel woven:

   - Platforms manifest as glowing threads in palette color

   - Destructible elements fray/unravel

   - Illusion walls shimmer if Yellow-equipped

   - Swing points appear as hanging silk



5\. \*\*Backtracking Encouraged\*\*

   Design for return visits—neutral first pass, rich shortcuts/secrets later.



\## Thread-Responsive Element Types



| Element Type         | Behavior Example                                                                 | Favored By                  | Visual/Audio Cue                          |

|----------------------|----------------------------------------------------------------------------------|-----------------------------|-------------------------------------------|

| Helper Platform      | Appears if lacking mobility tool                                                 | 0-equip / pure base         | Soft neutral/white glow                   |

| Crumbling Block      | Stable if no Red; breaks if absorbed                                             | Red archetype/equip         | Pulsing red cracks                        |

| Needle Swing Point   | Inert unless Blue tool equipped                                                  | Blue equip                  | Dangling silk strands                     |

| Illusion Wall        | Solid unless Yellow; faint shimmer if equipped                                   | Yellow equip                | Distorted air + particles                 |

| Pullable Object      | Stuck if no Reverse Grapple; movable if equipped                                 | Red Gloves                  | Wrapped glowing red threads               |

| Temporary Bridge     | Auto-mends if Blue spared; manual if absorbed                                    | Spare Blue                  | Blue silk weaving animation               |

| Destructible Barrier | Unbreakable pure run; shatters with Red burst                                    | Red mobility                | RedBreakablePlat shader pulses            |



\## Room Design Template

\- \*\*Neutral Route\*\* (60–70% space): Worst-case base mobility.

\- \*\*Expressive Lanes\*\* (1–3): Color-themed shortcuts/risks.

\- \*\*Secret Nooks\*\*: Hidden by destruction/illusion/grapple.

\- \*\*Responsive Feedback\*\*: ArchetypeUI prompts, glow changes, Follower commentary.



\## Region Flavor

\- \*\*Monarch's Dominion (Red)\*\*: Oppressive, crumbling architecture → momentum lanes.

\- \*\*Hermit's Veil (Blue)\*\*: Floating islands, silk → graceful chains.

\- \*\*Sage's Labyrinth (Yellow)\*\*: Illusions, mirrors → mind-bending skips.



\## Playtesting Checklist

\- Pure Red/Blue/Yellow completable?

\- Absorbing dramatically changes fun/expressiveness?

\- Changes clear thematically?

\- Backtracking rewarding?

\- Environment tells story (fraying, saturation)?

