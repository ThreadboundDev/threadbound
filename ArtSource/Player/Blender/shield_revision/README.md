# Threadborne sword and shield — rear repair

Open `Threadborne_Sword_Shield_Rear_Fix.blend` to review. The source GLB contained a sword and shield in one mesh; both sides of the shield carried the front ornament. `Shield_Imported_Source.blend` preserves that import.

The repair separates the sword into `Threadborne_Sword_ROOT` and the shield assembly into `Threadborne_Shield_ROOT`. Imported sword geometry and UVs are retained. The shield front half retains its original geometry and UVs; the duplicated rear half is replaced by dark boards, a flat brass rim, sewn braces, leather arm loops, anchor plates and rivets. Straps are raised geometry with clearance behind them, not merely painted details. Rear construction follows the supplied reference, with procedural worn materials rather than an exact painted replica.

Use the ROOT empties to move each weapon as a unit. The sword root is an approximate handle pivot; final scale, hand grip and shield-arm placement still need fitting to the character. This is not yet attached to a rig and does not change the game's equipment system.

The original combined import remains in a disabled SOURCE collection. The user's live Blender scene and input GLB are untouched. Review images include the preserved front, rebuilt rear, rear three-quarter and side. Rebuild offline with `tools/art/rebuild_threadborne_shield_back.py` after running the import inspection script.
