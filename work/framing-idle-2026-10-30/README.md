# Live camera and upright idle — October 30, 2026

Chase authorized zoom 0.83 and an upright-posture attempt. The demo and Blue
gameplay Camera2D nodes now use 0.83; the painted comparison inherits Blue's
setting. The overview camera keeps its existing purpose/zoom.

The shared character visual makes per-instance copies of the idle animations
and partially blends leg/torso rotations toward the rig rest pose. Facing,
breathing, arms/equipment and existing crossfades are retained. Set
`upright_idle_strength` to zero to recover the old selection/pose. The same
clips are installed in the grapple leg sampler. The former deep idle variation
is omitted from the automatic sequence. Source GLBs/Blender files and all
non-idle animations, collision, combat timing and movement are untouched.

`upright-comparison.jpg` compares identical pixel scale with both players
actually grounded. Previous idle: about 173 world units, 13.3% at 0.83.
Upright trial: about 185.5 units, 14.3%. Boot contact is within one world pixel
of the floor in both samples. This is a procedural first pass; Chase's manual
pose work can still improve weight, equipment presentation and transitions.

Validation: `tools/player_animation/verify_upright_idle.gd` passes 19 GPU checks
covering ground contact, imported-source isolation, unchanged non-idle source
keys, installed grapple sampling, real throw/return and both authored camera
zooms and the delayed idle variation after more than six seconds. An initial
conditional-array typing error was caught during longer captures and corrected
with a typed list before this extended verification. The existing demo
jump/lighting regression passes 134 checks. Its
temporary SceneTree copy redirects report output and assigns the current scene
before tutorial ready; the check logic is unchanged. `render.json` and
`demo-regression.json` record results.
Known baseline texture/RID/ObjectDB shutdown diagnostics remain; no clean-log or
hands-on feel acceptance is claimed. The comparison was visually inspected.

Reproduce with Godot 4.7.2, normal project imports, a task-local `APPDATA` and:

```text
--path . --resolution 1920x1080 --fixed-fps 60 --disable-vsync --script res://tools/player_animation/verify_upright_idle.gd
```

Run `build_review.py` with Python/Pillow to package the images. `inspect_idle.gd`
is the exploratory clip inventory; its raw output stays in ignored `tmp/`.
The `.gdignore` excludes review material from normal Godot imports.
