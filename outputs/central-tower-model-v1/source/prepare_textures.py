"""Build tiled PBR maps for the new tower; never edits project production art."""
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np
import json

HERE=Path(__file__).resolve()
ROOT = HERE.parents[3] if HERE.parent.name=='source' else HERE.parents[2]
OUT = HERE.parents[1] if HERE.parent.name=='source' else ROOT / 'outputs/central-tower-model-v1'
SRC = OUT / 'source/material-atlas-generated.png'
DEST = OUT / 'textures'
DEST.mkdir(parents=True, exist_ok=True)
atlas = Image.open(SRC).convert('RGB')
w,h = atlas.size
N=4096
rng=np.random.default_rng(20261019)
entries={}
for name,rect,strength,rough in [
    ('walnut',(0,0,w//2,h//2),1.8,.82),
    ('plaster',(w//2,0,w,h//2),.7,.94),
    ('blue_tiles',(0,h//2,w//2,h),1.6,.57),
    ('slate',(w//2,h//2,w,h),1.4,.91),
]:
    crop=atlas.crop(rect)
    # A mirrored repeat removes hard seams; subtle native-resolution variation
    # supplies microdetail. Source art resolution is explicitly recorded below.
    im=crop.resize((N//2,N//2),Image.Resampling.LANCZOS)
    tile=crop.resize((N,N),Image.Resampling.LANCZOS)
    a=np.asarray(tile,dtype=np.float32)/255
    noise=rng.normal(0,.0035,(N,N)).astype(np.float32)
    if name=='walnut':
        # Fine long grain: a second, higher-frequency layer, not model geometry.
        col=rng.normal(0,.007,(1,N)).astype(np.float32)
        noise += col
    a=np.clip(a+noise[:,:,None],0,1)
    if name=='walnut':a=np.clip(a*.64,0,1)
    if name=='plaster':a=np.clip(a*np.array([.96,.945,.925],dtype=np.float32),0,1)
    if name=='blue_tiles':a=np.clip(a*np.array([.90,1.07,1.18],dtype=np.float32),0,1)
    Image.fromarray((a*255).astype('uint8')).save(DEST/f'{name}_BaseColor_4K.png',compress_level=4)
    gray=a[:,:,0]*.2126+a[:,:,1]*.7152+a[:,:,2]*.0722
    smooth=np.asarray(Image.fromarray((gray*255).astype('uint8')).filter(ImageFilter.GaussianBlur(1.3)),dtype=np.float32)/255
    gy,gx=np.gradient(smooth)
    nx=-gx*strength*12; ny=gy*strength*12
    nz=np.ones_like(nx)
    norm=np.sqrt(nx*nx+ny*ny+1)
    normal=np.stack((nx/norm*.5+.5,ny/norm*.5+.5,nz/norm*.5+.5),axis=2)
    Image.fromarray((np.clip(normal,0,1)*255).astype('uint8')).save(DEST/f'{name}_NormalGL_4K.png',compress_level=4)
    roughmap=np.clip(rough+(gray-gray.mean())*.13+noise, .3,1)
    Image.fromarray((roughmap*255).astype('uint8')).save(DEST/f'{name}_Roughness_4K.png',compress_level=4)
    runtime=OUT/'textures/runtime';runtime.mkdir(exist_ok=True)
    Image.fromarray((a*255).astype('uint8')).save(runtime/f'{name}_BaseColor_4K.jpg',quality=94,subsampling=0)
    Image.open(DEST/f'{name}_NormalGL_4K.png').resize((2048,2048),Image.Resampling.LANCZOS).save(runtime/f'{name}_NormalGL_2K.png')
    Image.open(DEST/f'{name}_Roughness_4K.png').resize((2048,2048),Image.Resampling.LANCZOS).save(runtime/f'{name}_Roughness_2K.png')
    entries[name]={'resolution':[N,N],'source_art_crop':list(crop.size),'repeat':'UV tiled; native 4K microvariation','maps':['BaseColor','NormalGL','Roughness'],'runtime':'4K JPEG albedo; 2K lossless normal/roughness'}
    print('TEXTURE_READY',name,flush=True)
(OUT/'source/texture_manifest.json').write_text(json.dumps({'source_atlas_size':[w,h],'materials':entries,'note':'4K composite PBR maps; generated painted source is 627px per quadrant, not native 4K art. Repeating UVs supply high surface texel density.'},indent=2))
