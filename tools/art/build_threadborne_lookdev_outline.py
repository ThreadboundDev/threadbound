"""Build a stable 1px-at-game-scale exterior outline and comparison sheet."""
from pathlib import Path
from PIL import Image,ImageFilter,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'Assets/Threadborne/Player/LookDev'
relit=Image.open(OUT/'02_relit.png').convert('RGBA');alpha=relit.getchannel('A')
# Four source pixels become one pixel at the intended 0.25 gameplay scale.
dilated=alpha.filter(ImageFilter.MaxFilter(9));edge=Image.eval(dilated,lambda p:p)
edge.point(lambda p:p)
outline=Image.new('RGBA',relit.size,(15,12,12,0));outline.putalpha(edge)
outlined=Image.alpha_composite(outline,relit);outlined.save(OUT/'03_relit_outline.png')
images=[Image.open(OUT/f).convert('RGBA') for f in ['01_current.png','02_relit.png','03_relit_outline.png']]
w,h=540,720;sheet=Image.new('RGB',(w*3,h+70),(22,31,38));draw=ImageDraw.Draw(sheet)
for i,(im,label) in enumerate(zip(images,['CURRENT','RELIT','RELIT + 1PX OUTLINE'])):
    im.thumbnail((w,h),Image.Resampling.LANCZOS);x=i*w+(w-im.width)//2;y=h-im.height
    sheet.paste(im,(x,y),im);draw.text((i*w+18,h+22),label,fill=(235,220,191),font=ImageFont.load_default())
sheet.save(OUT/'lookdev_comparison.png')
print('LOOKDEV_OUTLINE_COMPLETE')
