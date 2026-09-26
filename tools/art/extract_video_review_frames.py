"""Extract evenly spaced review frames from the supplied Blender-readable video."""
import sys
from pathlib import Path

import bpy

video = Path(sys.argv[sys.argv.index("--") + 1])
output = Path(sys.argv[sys.argv.index("--") + 2])
output.mkdir(parents=True, exist_ok=True)

scene = bpy.context.scene
editor = scene.sequence_editor_create()
strip = editor.strips.new_movie("Review", str(video), channel=1, frame_start=1)
scene.render.resolution_x = strip.elements[0].orig_width
scene.render.resolution_y = strip.elements[0].orig_height
scene.render.resolution_percentage = 50
scene.render.image_settings.file_format = "PNG"
scene.render.use_file_extension = True
scene.render.use_sequencer = True

duration = strip.frame_final_duration
samples = 8
for index in range(samples):
    frame = 1 + round((duration - 1) * index / (samples - 1))
    scene.frame_set(frame)
    scene.render.filepath = str(output / f"review_{index:02d}.png")
    bpy.ops.render.render(write_still=True)
print("VIDEO_REVIEW_FRAMES", duration, strip.elements[0].orig_width, strip.elements[0].orig_height, flush=True)
