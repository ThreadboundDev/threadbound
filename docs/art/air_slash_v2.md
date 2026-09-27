# Air slash V2 — September 14 reference revision

The neutral air attack uses the actual `jump_1` pelvis and leg pose at frame 14, with a separately authored sword arm. The previous generator accidentally overwrote the jump with idle and then posed new legs; V2 preserves the source jump lower body.

The hand path is relative to the airborne shoulder, moving from above/behind it through a forward downward cut. The clip is 12 frames at 30 fps, with one contact window at source frames 3–6. Runtime playback multipliers shorten both motion and the attached smear together. Horizontal attack input updates facing before the strike.

Source: `ArtSource/Player/Blender/imported_character/mixamo_library/Threadborne_Air_Light_v2.blend`.
Runtime: `Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_air_light_v2_review.glb`.
Rebuild: `tools/art/build_air_light_animation.py`, then `tools/art/export_equipped_live_3d_test.py` with those source/output paths.

This revision concentrates on the neutral slash silhouette and speed. The existing downward pogo behavior is retained; a unified up/down/diagonal visual aiming treatment is the next stage after the neutral pose is reviewed, as requested. The reference sheet is pose guidance, not literal frame-by-frame motion or a request to replace the character artwork.

Validation: Godot captures with and without VFX, and single-hit checks at 30/60/120 fps with 1.0/1.35/1.8/2.5 playback multipliers. Animation checks establish functionality; final animation appeal remains a gameplay review decision.
