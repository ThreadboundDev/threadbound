"""Gameplay-scale appearance evidence. Insets are explicitly enlarged."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
p=Path(__file__).resolve().parent
assert not json.loads((p/'validation.json').read_text())['failures']
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
def strip(files,titles,path,cols=4):
    rows=(len(files)+cols-1)//cols
    out=Image.new('RGB',(cols*300,rows*380+40),'#18252d')
    d=ImageDraw.Draw(out)
    d.text((12,8),'Body crops at native gameplay pixel scale (0.83); lower insets enlarged 4x.',font=small,fill='white')
    for i,(file,title) in enumerate(zip(files,titles)):
        x=(i%cols)*300;y=(i//cols)*380+40
        im=Image.open(p/(file+'.png')).convert('RGB')
        d.text((x+8,y+4),title,font=font,fill='#eee4cc')
        out.paste(im.crop((880,615,1080,815)),(x+50,y+35))
        face=im.crop((953,640,985,675)).resize((128,140),Image.Resampling.NEAREST)
        out.paste(face,(x+85,y+235))
    out.save(p/path,quality=94)
strip([f'look_{i}' for i in range(4)],['Plain','Pattern','Mask','Both'],'looks-comparison.jpg')
strip([f'mask_{i}' for i in range(3)],['Double seam','Split porcelain','Diagonal mark'],'mask-comparison.jpg',3)
strip([f'palette_{i}' for i in range(9)],['Current neutral','Red','Blue','Yellow','Red + Blue','Blue + Yellow','Red + Yellow','All absorbed','Spared / pale'],'identity-comparison.jpg',3)
strip(['math_0','math_1','gear_proxy','softer_porcelain'],['Weighted RGB B+Y','Authored RYB B+Y','Gear silhouette proxies','Softer porcelain trial'],'math-gear-comparison.jpg')
print('Packaged native-scale looks, three mask treatments and nine Identity presets.')
