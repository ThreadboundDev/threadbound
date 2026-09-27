"""Pack PetalV2 without changing the original bulb atlas."""
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[2]
source = ROOT/'ArtSource/BlueBiome/Blender/WaterBulb/PetalV2'
dest = ROOT/'Assets/BlueBiome/StillVillage/Bulb/PetalV2'
dest.mkdir(parents=True, exist_ok=True)
atlas = Image.new('RGBA',(2160,5760))
for i in range(72):
    im = Image.open(source/'frames'/f'{i+1:03d}.png').convert('RGBA')
    assert im.size == (360,480)
    atlas.paste(im,(i%6*360,i//6*480))
atlas.save(dest/'bulb_lifecycle.png')
resource = (dest.parent/'bulb_frames.tres').read_text().replace('Bulb/bulb_lifecycle.png','Bulb/PetalV2/bulb_lifecycle.png')
(dest/'bulb_frames.tres').write_text(resource)
sheet = Image.new('RGBA',(360*4,480),(24,43,57,255))
for i,f in enumerate([1,28,49,72]):
    im = Image.open(source/'frames'/f'{f:03d}.png')
    sheet.paste(im,(i*360,0),im)
sheet.convert('RGB').save(source/'petal_lifecycle_review.png')
print('PETAL PACK: PASS — 72 frames, original framing preserved')
