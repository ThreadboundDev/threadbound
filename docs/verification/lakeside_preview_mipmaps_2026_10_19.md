# Lakeside editor preview: invalid mipmap cascade

The user reported `Too many mipmaps requested ... (5), maximum allowed: (2)`,
followed by invalid texture IDs, missing named textures and unbound uniforms
when opening the lakeside playtest in Godot 4.7.2.

An actual Forward+ reproducer placed the existing art stage inside a 2x2 host
SubViewport. Its 1.25 render scale resized both building passes to 3x3. That
reproduced the exact reported error chain in both passes. The contact-shading
depth buffer requests five mip levels at half resolution, which cannot fit in
this transient startup size. The editor viewport becomes usable afterward, so
normal full-resolution runtime checks had not exposed the startup condition.

The stage now retains its last valid render targets until both requested
dimensions are at least 64 pixels. This applies before camera/sprite updates,
so a temporary tiny editor viewport cannot change either pass to invalid sizes
or trigger extreme-aspect buffer allocations. The initial 1280x720 targets are
already valid. Once the editor or game viewport is ready, normal supersampling,
camera registration, 4x MSAA, contact shading and glow proceed as before.

Only the existing stage script changes at runtime:
`Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_art_stage_2d.gd`.
There are no scene, artwork, texture-import, lighting-preset or player changes.

`tools/environment/verify_lakeside_preview_resize.gd` passes **149 checks**
with actual Vulkan Forward+ rendering on the Radeon RX 6800 XT. It exercises
startup at 2x2; wide/short and tall/narrow temporary hosts; 16/32/64/128 pixel
views; 320x180, 1280x720 and 1920x1080; render scales 0.5, 1.25 and 2.0; and
shrinking a valid view before restoring it. Both passes retain matching valid
buffers, restore requested resolution, preserve 2D/3D point registration, and
keep their quality settings. No mipmap, invalid texture or missing-uniform
errors occur during the passing test. The full lakeside map verification also
passes with actual Forward+ rendering after this fix.

Logs and the 36-case size report are under `work/lakeside-preview-error/`.
The project's previously observed texture-resource shutdown diagnostics remain
after test completion; they are separate from the repaired scene-load cascade.

Engine reference: [Godot screen-space depth downsampling](https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_rd/effects/ss_effects.cpp),
`SSEffects::downsample_depth`, allocates the half-resolution five-level depth
texture. The local reproducer confirms the same behavior in the installed build.
