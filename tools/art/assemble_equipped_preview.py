"""Package rendered frames as a review GIF; do not alter source renders."""
from pathlib import Path
import json
from PIL import Image
out=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
manifest=json.loads((out/'preview_manifest.json').read_text())
frames=[]
clipped=[]
for item in manifest:
    with Image.open(out/'preview_frames'/item['file']) as image:
        bounds=image.convert('RGBA').getchannel('A').getbbox()
        if bounds and (bounds[0]==0 or bounds[1]==0 or bounds[2]==image.width or bounds[3]==image.height):
            clipped.append(item['file'])
        canvas=Image.new('RGBA',image.size,(38,40,43,255));canvas.alpha_composite(image.convert('RGBA'));frames.append(canvas.convert('RGB'))
frames[0].save(out/'equipped_animation_preview.gif',save_all=True,append_images=frames[1:],duration=[i['duration_ms'] for i in manifest],loop=0,disposal=2)
print('GIF_COMPLETE',len(frames),'frames')
print('FRAME_EDGE_CHECK',clipped)
(out/'frame_bounds_validation.json').write_text(json.dumps({'sampled_frames':len(frames),'frames_touching_canvas_edge':clipped},indent=2))
