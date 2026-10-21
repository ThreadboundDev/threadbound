from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
tex=ROOT/'work/lakeside-godot/sandbox/Assets/BlueBiome/Art/Lakeside3D/Textures'
for path in tex.glob('*_4K.png.import'):
    text=path.read_text().replace('compress/mode=0','compress/mode=2').replace('compress/high_quality=false','compress/high_quality=true').replace('mipmaps/generate=false','mipmaps/generate=true').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
    if 'NormalGL' in path.name:text=text.replace('compress/normal_map=0','compress/normal_map=1')
    path.write_text(text)
print('HIGH_QUALITY_4K_TEXTURE_IMPORT_CONFIGURED')
