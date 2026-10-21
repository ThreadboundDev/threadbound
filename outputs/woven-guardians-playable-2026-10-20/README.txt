WOVEN GUARDIANS — PLAYABLE REVIEW / October 20, 2026

Both enemies are installed in the existing Threadbound project.
Run this scene with F6:
C:/Users/chase/Documents/threadbound/Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn

Use the bottom Eave Runner / Loom Heron buttons to visit each encounter.
F2 respawns all five enemies. Normal attack, dodge and shield controls apply.

Eave Runner: tower guardian; real wall brace/climb, locked leap/blade sweep,
landing recovery, and a straight throwing pin when walls are unavailable.
Loom Heron: cloth-wing flyer by the boat slip; tell, committed diagonal dive,
low vulnerable brake recovery, reposition. Perch animation is included in the
model; the placed instance patrols in flight rather than landing on perches.

Both Blender files include packed textures, deform bones and named animation
Actions. Eave Runner has 60 bones and 12 clips. Heron has 17 bones and 8 clips.
The GLBs use external texture folders; keep Models and Textures together.

Woven_Guardians_Runtime.zip contains project-relative new enemy assets/scripts
and prefab scenes, plus the small EnemyBase death/reset timer fix. It is a
backup/import package for the existing project, not a standalone Godot game.
The existing project components remain required.
The current map already contains the placed enemies; the zip need not be imported.

The PNGs and GIFs marked In_Game are actual Forward+ Godot captures, cropped
for the GIFs. They show the real map, player, materials and skeletal animations.
The still marked Model is a Blender studio render of the saved heron mesh.
No screenshot is a substitute for the in-game models.

Validation: 106 saved-heron-source checks; 80 isolated combat checks; 19
headless checks on the real map/player; 97 rendered checks / 80 captured frames.
Rendered captures precede the final wall-search range improvement; the final
headless run also verifies returning to another wall and repeated leaps.
Existing engine shutdown resource/texture diagnostics appear in the rendering
log; no gameplay/source check failures or script errors remain.

This is the first playable tuning pass; Chase's hands-on feel/art review remains.
Full implementation notes are included as Gameplay_Notes.md.
