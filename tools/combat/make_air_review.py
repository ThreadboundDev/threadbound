"""Assemble Godot QA screenshots; does not alter production artwork."""
from pathlib import Path
from PIL import Image, ImageDraw

folder = Path('C:/Users/chase/.codex/visualizations/2026/09/14/01a0a082-1409-7791-a66d-d1c90fee4a99/implementation')
frames = []
board = Image.new('RGB', (1110, 700), (20, 31, 42))
for frame in range(17):
    panel = Image.new('RGB', (740, 350), (20, 31, 42))
    for side, prefix in enumerate(('air_body', 'air_review')):
        capture = Image.open(folder / f'{prefix}_{frame:02}.png')
        panel.paste(capture.crop((280, 30, 650, 350)), (370 * side, 30))
    ImageDraw.Draw(panel).text((12, 10), 'Body only | With VFX — slow-motion review', fill='white')
    frames.append(panel)
    if frame in (1, 3, 5, 6, 8, 14):
        index = (1, 3, 5, 6, 8, 14).index(frame)
        cell = panel.crop((0, 0, 370, 350))
        ImageDraw.Draw(cell).rectangle((0, 0, 370, 28), fill=(20, 31, 42))
        ImageDraw.Draw(cell).text((12, 10), f'Source frame {frame}', fill='white')
        board.paste(cell, ((index % 3) * 370, (index // 3) * 350))
frames[0].save(folder / 'air_v3_motion.gif', save_all=True, append_images=frames[1:],
               duration=[80] * 16 + [650], loop=0)
board.save(folder / 'air_v3_body_review.png')
for panel in frames:
    draw = ImageDraw.Draw(panel)
    draw.rectangle((0, 0, 740, 28), fill=(20, 31, 42))
    draw.text((12, 10), 'Body only | With VFX — normal speed, pause between repeats', fill='white')
frames[0].save(folder / 'air_v3_realtime.gif', save_all=True, append_images=frames[1:],
               duration=[20] * 16 + [650], loop=0)
