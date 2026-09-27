"""Package the approved 30 FPS look into a compact review GIF and validate bounds."""
from pathlib import Path
import json
from PIL import Image,ImageEnhance,ImageFilter
ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'ArtSource/Player/Blender/imported_character/mixamo_test/godot_export_30fps'
dest=ROOT/'Assets/Threadborne/Player/EquippedTest'
manifest=json.loads((source/'manifest.json').read_text());frames=[];clipped=[]
for item in manifest:
    with Image.open(source/item['file']) as raw:
        im=raw.convert('RGBA');bounds=im.getchannel('A').getbbox()
        if bounds and (bounds[0]==0 or bounds[1]==0 or bounds[2]==im.width or bounds[3]==im.height):clipped.append(item['file'])
        alpha=im.getchannel('A')
        rgb=Image.new('RGB',im.size);rgb.paste(im.convert('RGB'),mask=alpha)
        rgb=ImageEnhance.Brightness(rgb).enhance(.88)
        rgb=ImageEnhance.Contrast(rgb).enhance(1.08)
        rgb=ImageEnhance.Color(rgb).enhance(1.04)
        im=rgb.convert('RGBA');im.putalpha(alpha)
        expanded=alpha.filter(ImageFilter.MaxFilter(9));outline=Image.new('RGBA',im.size,(15,12,12,0));outline.putalpha(expanded)
        im=Image.alpha_composite(outline,im).resize((225,300),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',im.size,(22,31,38,255));canvas.alpha_composite(im);frames.append(canvas.convert('RGB'))
frames[0].save(dest/'equipped_30fps_preview.gif',save_all=True,append_images=frames[1:],duration=33,loop=0,disposal=2,optimize=False)
(dest/'frame_bounds_validation.json').write_text(json.dumps({'frames':len(frames),'fps':30,'frames_touching_edge':clipped},indent=2))
print('EQUIPPED_30FPS_PREVIEW_READY',len(frames),'CLIPPED',len(clipped))
