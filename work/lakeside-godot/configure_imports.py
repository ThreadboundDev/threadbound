from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
runtime=ROOT/'work/lakeside-godot/runtime/Godot_v4.7.2-stable_mono_win64'
(runtime/'_sc_').touch()
tex=ROOT/'work/lakeside-godot/sandbox/Assets/BlueBiome/Art/Lakeside3D/Textures'
for p in tex.glob('*.import'):
    text=p.read_text().replace('compress/mode=0','compress/mode=2').replace('mipmaps/generate=false','mipmaps/generate=true').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
    if 'NormalGL' in p.name:text=text.replace('compress/normal_map=0','compress/normal_map=1')
    p.write_text(text)
print('VRAM_COMPRESSION_AND_MIPMAPS_CONFIGURED')
