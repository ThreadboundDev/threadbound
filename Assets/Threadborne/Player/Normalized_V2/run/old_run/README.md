# Archived run animation

This folder is the canonical source for the exact runtime PNGs and playback
order restored after the July 2026 run cleanup was rejected as jittery. The
numbered `frame_00` through `frame_10` prefixes are the original Godot playback
order:

1. `run_001`
2. `run_002`
3. `run_003`
4. `run_004`
5. `run_005`
6. `run_006`
7. `run_012`
8. `run_020`
9. `run_007`
10. `run_018`
11. `run_008`

The player scene references matching copies in the parent `run` directory.
The normalizer copies these files without registration, scaling, generated
bridge poses, or other pixel changes. This folder remains ignored by Godot so
it acts as a stable, lossless source archive.
