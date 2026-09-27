"""Render an additive petal lifecycle variant from the approved bulb source."""
from pathlib import Path
import math
import bpy

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'ArtSource/BlueBiome/Blender/WaterBulb'
OUT = SOURCE / 'PetalV2'
(OUT / 'frames').mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'WaterBulb_HangingBell_v1.blend'))
bpy.context.preferences.filepaths.save_version = 0
flower = bpy.data.objects['FLOWER_calyx_and_petals']
for frame in range(1, 74):
    if frame <= 24:
        pulse = math.sin((frame-1)/24*math.tau)
        width, depth = .78 + .025*pulse, 1.65 + .10*pulse
    elif frame <= 28:
        t = (frame-24)/4
        width, depth = .78+.34*t, 1.65-1.27*t
    elif frame <= 42:
        width, depth = 1.12, .38
    else:
        t = min(1, (frame-42)/30)
        if t < .35:
            u = t/.35
            width, depth = 1.12-.64*u, .38+1.72*u
        else:
            u = (t-.35)/.65
            width, depth = .48+.30*u, 2.10-.45*u
    flower.scale = (width,width,depth)
    flower.keyframe_insert(data_path='scale', frame=frame)
scene = bpy.context.scene
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'WaterBulb_Petal_v2.blend'))
scene.render.resolution_percentage = 60
scene.cycles.samples = 24
for frame in range(1,73):
    scene.frame_set(frame)
    scene.render.filepath = str(OUT/'frames'/('%03d.png'%frame))
    bpy.ops.render.render(write_still=True)
    print('PETAL_FRAME',frame,flush=True)
