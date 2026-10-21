from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
HERE=Path(__file__).resolve()
ROOT=HERE.parents[3] if HERE.parent.name=='source' else HERE.parents[2]
OUT=HERE.parents[1] if HERE.parent.name=='source' else ROOT/'outputs/central-tower-model-v1'
P=OUT/'previews'
BG=(224,220,212)
sheet=Image.new('RGB',(2280,1580),BG)
draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',38)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',25)
draw.text((1140,24),'CENTRAL TOWER / ACTUAL 3D MODEL',font=font,fill=(35,43,48),anchor='mt')
draw.line((65,88,2215,88),fill=(110,111,110),width=2)
for j,(fn,label) in enumerate([('cutaway_front.png','FRONT / CUTAWAY'),('exterior_front.png','FRONT / EXTERIOR'),('exterior_three_quarter.png','THREE-QUARTER / EXTERIOR')]):
    im=Image.open(P/fn).convert('RGBA');bbox=im.getchannel('A').getbbox();im=im.crop(bbox)
    im.thumbnail((690,1340),Image.Resampling.LANCZOS)
    x=380+j*760-im.width//2;y=115+1340-im.height
    sheet.paste(im,(x,y),im)
    draw.text((380+j*760,1480),label,font=small,fill=(35,43,48),anchor='mm')
report=json.loads((OUT/'verification.json').read_text())
tri=report['exterior']['triangles']
draw.text((1140,1540),f'4100 × 1200 gameplay px  |  {tri:,} triangles  |  Removable facade  |  Open-bottom basin',font=small,fill=(62,67,69),anchor='mm')
sheet.save(P/'CentralTower_3D_review.png')
details=Image.new('RGB',(2400,1050),BG);d=ImageDraw.Draw(details)
for j,(fn,label) in enumerate([('detail_roof_and_joinery.png','ROOF TILES, LATTICE & JOINERY'),('detail_open_basin.png','OPEN UNDERSIDE / BASIN RING')]):
    im=Image.open(P/fn).convert('RGBA');im.thumbnail((1180,900),Image.Resampling.LANCZOS)
    details.paste(im,(j*1200+(1200-im.width)//2,80),im)
    d.text((j*1200+600,34),label,font=small,fill=(35,43,48),anchor='mt')
details.save(P/'CentralTower_detail_review.png')
print('PREVIEWS_PACKAGED')
