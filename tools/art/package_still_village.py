"""Package rendered pieces, reusable Godot placeables and the bulb atlas."""
import json
import struct
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/'Assets/BlueBiome/StillVillage'
SOURCE=ROOT/'ArtSource/BlueBiome/Blender/StillVillage'
SCENES=ROOT/'Src/Environment/BlueBiome/ArtPlaceables/StillVillage'
SCENES.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ASSETS/'kit_manifest.json').read_text())
model_report=[]
bg=(15,31,45)
board=Image.new('RGB',(1600,1250),bg)
draw=ImageDraw.Draw(board)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',22)
heading=ImageFont.truetype('C:/Windows/Fonts/seguisb.ttf',36)
draw.text((40,22),'STILL VILLAGE  /  BUILT ASSET KIT',fill=(225,239,242),font=heading)
draw.text((40,73),'12 editable 3D sources • orthographic game art • separate decorative layers',fill=(153,192,203),font=font)
for i,item in enumerate(manifest):
    model=(SOURCE/'models'/(item['id']+'.glb')).read_bytes()
    assert model[:4]==b'glTF', item['id']
    json_size=struct.unpack_from('<I',model,12)[0]
    gltf=json.loads(model[20:20+json_size])
    assert len(gltf.get('meshes',[]))>0, item['id']
    triangles=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])
    model_report.append({'id':item['id'],'meshes':len(gltf['meshes']),'triangles':triangles})
    path=ROOT/item['texture']
    with Image.open(path) as source:
        assert source.size==tuple(item['canvas'])
        im=source.convert('RGBA')
        bounds=im.getchannel('A').getbbox()
        assert bounds and bounds[0]>0 and bounds[1]>0 and bounds[2]<im.width and bounds[3]<im.height, item['id']
        im=im.crop(bounds)
        im.thumbnail((350,285),Image.Resampling.LANCZOS)
        x=25+(i%4)*397+(350-im.width)//2; y=145+(i//4)*360+(285-im.height)//2
        board.paste(im,(x,y),im)
    label=f'{i+1:02}  '+item['id'].replace('_',' ').upper()
    draw.text((30+(i%4)*397,440+(i//4)*360),label,fill=(225,239,242),font=font)
    px,py=item['origin_px']
    scene=f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://{item['texture']}" id="1"]

[node name="{item['id']}" type="Node2D"]
metadata/asset_id = "{item['id']}"

[node name="Art" type="Sprite2D" parent="."]
texture = ExtResource("1")
centered = false
offset = Vector2({-px:.5f}, {-py:.5f})
'''
    (SCENES/(item['id']+'.tscn')).write_text(scene)
board.save(SOURCE/'still_village_kit_review.png')
(SOURCE/'model_verification.json').write_text(json.dumps(model_report,indent=2))

BULB=ASSETS/'Bulb'; BULB.mkdir(exist_ok=True)
atlas=Image.new('RGBA',(2160,5760))
resources=[]
for index in range(72):
    path=ROOT/'ArtSource/BlueBiome/Blender/WaterBulb/frames'/f'{index+1:03d}.png'
    with Image.open(path) as im:
        atlas.paste(im,(index%6*360,index//6*480))
    resources.append(f'[sub_resource type="AtlasTexture" id="F{index}"]\natlas = ExtResource("1")\nregion = Rect2({index%6*360}, {index//6*480}, 360, 480)\nfilter_clip = true\n')
atlas.save(BULB/'bulb_lifecycle.png')
animations=[]
for name,first,last,loop in [('rush',0,23,True),('pop',24,35,False),('spent',36,41,True),('refill',42,71,False)]:
    refs=', '.join('{"duration": 1.0, "texture": SubResource("F%d")}'%i for i in range(first,last+1))
    animations.append('{"frames": ['+refs+'], "loop": '+str(loop).lower()+', "name": &"'+name+'", "speed": 24.0}')
(BULB/'bulb_frames.tres').write_text('[gd_resource type="SpriteFrames" load_steps=74 format=3]\n\n[ext_resource type="Texture2D" path="res://Assets/BlueBiome/StillVillage/Bulb/bulb_lifecycle.png" id="1"]\n\n'+'\n'.join(resources)+'\n[resource]\nanimations = ['+',\n'.join(animations)+']\n')
print('PACKAGED',len(manifest),'placeables and 72 bulb frames')
