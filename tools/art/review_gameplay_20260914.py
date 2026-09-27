"""Extract local gameplay evidence; does not alter game assets."""
import bpy
from pathlib import Path
import sys

args = sys.argv[sys.argv.index('--') + 1:]
out = Path(args[1])
out.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
scene.render.fps = 60
strip = scene.sequence_editor_create().strips.new_movie('Review', args[0], channel=1, frame_start=1)
scene.render.resolution_x = strip.elements[0].orig_width
scene.render.resolution_y = strip.elements[0].orig_height
scene.render.resolution_percentage = 25
scene.render.image_settings.file_format = 'PNG'
scene.render.use_sequencer = True
scene.view_settings.view_transform = 'Standard'
times = [float(t) for t in args[2:]] if len(args) > 2 else list(range(52))
for second in times:
    scene.frame_set(1 + round(second * 60))
    scene.render.filepath = str(out / f'{second:06.2f}.png')
    bpy.ops.render.render(write_still=True)
