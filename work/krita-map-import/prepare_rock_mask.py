from pathlib import Path
import json
from PIL import Image, ImageChops, ImageFilter
WORK=Path(__file__).resolve().parent
size=(6912,5888)
mask=Image.new('L',size)
# Supports are on layer20 and intentionally excluded from terrain collision.
for name in ['layer18','layer16','layer15','layer19']:
    alpha=Image.open(WORK/(name+'.png')).getchannel('A')
    if name=='layer19':
        # This layer also contains the dark rear face visible THROUGH the upper
        # cave entrance. Use the foreground rock contour, never its backdrop.
        alpha.paste(0,(0,1350,1150,2050))
    mask=ImageChops.lighter(mask,alpha)
mask=mask.point(lambda a:255 if a>=128 else 0)
# Remove isolated sub-pixel paint flecks, retaining the actual rock contour.
mask=mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
raw=Image.new('RGBA',size,'white');raw.putalpha(mask);raw.save(WORK/'rock_mask_raw.png')
# Round short sawtooth edges into ramps, then pull the whole outline into the
# art. Do this BEFORE sectioning so shared seams remain exactly coincident.
mask=mask.filter(ImageFilter.GaussianBlur(8)).point(lambda a:255 if a>=128 else 0)
mask=mask.filter(ImageFilter.MinFilter(9))  # four pixels on each side
im=Image.new('RGBA',size,'white');im.putalpha(mask);im.save(WORK/'rock_mask.png')
(WORK/'rock_mask_recipe.json').write_text(json.dumps({'solid_layers':['Cave Walls','Under Path Above Cave','Stone paths','Under Cave Mouth (except cave backdrop)'],'non_solid':['STAMP REAR SUPPORTS','upper cave recessed backdrop'],'alpha_threshold':128,'inset_pixels':4,'smoothing_radius_pixels':8,'simplification_pixels':5,'world_origin':[-1408,-2560]},indent=2))
print('ROCK_MASK_READY')
