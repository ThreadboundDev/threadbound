THREADBOUND — CHARACTER QUALITY V2 / October 20, 2026

Installed in the existing Godot project. Run the lakeside Krita playtest with F6.
Use Eave Runner / Loom Heron / Net mender / Boatwright landmark buttons.
F2 restores all five enemies.

Heron now aims and fires one ceramic needle, then descends to a low vulnerable
hover. It no longer deals damage by diving or body contact. Aim locks before
release; normal shield rules, terrain blocking and hurt interruption apply.

Both villagers and both enemies have about four times their old geometry,
refined cloth/face/cord surfaces and real 4K PBR/skin maps. Source proportions,
existing rigs, NPC interactions and 2D collision remain intact. Native v1 files
remain available in the project for comparison.

The packed Blender files can be opened directly. GLBs in the project reference
shared texture folders; keep those dependencies if copying them elsewhere.

The PNG contact sheet and GIF are renders of the actual saved Blender models,
not concept art and not new in-game screenshots. Godot checks were headless;
no graphical game/editor window was launched. Test visual feel and frame rate
in your next hands-on session: higher geometry, texture and supersampling
settings increase rendering cost. Quality controls remain in the inspectors.

Implementation_and_Review.md describes source files, tuning and reproduction.
Verification reports/logs accompany this delivery. Existing engine shutdown
cleanup warnings are distinct from check failures and script errors.
