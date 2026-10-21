"""Assemble a separate playable room from the saved layout and approved assets."""
from pathlib import Path
import argparse, base64, hashlib, json, re, shutil, struct, sys

parser = argparse.ArgumentParser(description=__doc__)
mode = parser.add_mutually_exclusive_group(required=True)
mode.add_argument('--artwork-only', action='store_true', help='Refresh painted chunks without touching the playable room')
mode.add_argument('--rebuild-legacy-room', action='store_true', help='Rebuild the original room, overwriting later manual layout and gameplay edits; requires separate review')
args = parser.parse_args()

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'Assets/BlueBiome/Art/LakesideMap'
SCENES=ROOT/'Src/Environment/BlueBiome/Prototypes/Rooms'
BASE='res://Src/Environment/BlueBiome/Buildings/Lakeside3D/'
manifest=json.loads((ART/'map_manifest.json').read_text())
STAMP=Path('C:/Users/chase/Documents/Codex/2026-10-07/ri/outputs/blue_village_stamp_pack')
sources={'walking_deck.png':'japanese_construction_v3/stamps/D01_Deck_Edge.png','quarry_block.png':'slate_village_library/stamps/S03_Tall_Quarry_Block.png','small_stone.png':'slate_village_library/stamps/S02_Short_Chunk.png'}
artwork_only = args.artwork_only
if not artwork_only:
    for out,src in sources.items():shutil.copy2(STAMP/src,ART/out)

art=['[gd_scene format=3]','']
for i,c in enumerate(manifest['chunks']):art.append(f'[ext_resource type="Texture2D" path="res://Assets/BlueBiome/Art/LakesideMap/{c["path"]}" id="{i+1}"]')
art.append('[ext_resource type="Material" path="res://Src/Environment/BlueBiome/ArtPlaceables/Background/rear_support_depth.tres" id="support_depth"]')
art+=['','[node name="TerrainArtwork" type="Node2D"]','editor_description = "Saved Krita artwork, 6912 x 5888, world origin (-1408,-2560), scale 1:1. Reference guides excluded; independent layers retain alpha. Add foliage as separate scene instances."']
zs={'rear_supports':-7,'rear_cave':-6,'terrain':5,'bridges':6,'breakables':7,'foreground':9}
for g in manifest['groups']:
    name=g['name'];art += [f'\n[node name="{name}" type="Node2D" parent="."]',f'z_index = {zs[name]}']
    if name == 'rear_supports':
        art += ['editor_description = "Krita STAMP REAR SUPPORTS only. Non-solid wood behind cave rocks; tune the shared depth material here."', 'material = ExtResource("support_depth")']
for i,c in enumerate(manifest['chunks']):
    art += [f'\n[node name="Chunk_{i+1:02}" type="Sprite2D" parent="{c["group"]}"]',f'position = Vector2({c["position"][0]}, {c["position"][1]})',f'texture = ExtResource("{i+1}")','centered = false']
    if c['group'] == 'rear_supports':
        art += ['use_parent_material = true']
(SCENES/'lakeside_krita_artwork.tscn').write_text('\n'.join(art)+'\n')
if artwork_only:
    print('ASSEMBLED_ARTWORK_ONLY', len(manifest['chunks']), 'chunks; playable room untouched')
    sys.exit(0)

source=SCENES/'blue_lake_greybox.tscn'
s=source.read_text()
source_hash=hashlib.sha256(source.read_bytes()).hexdigest()
raw=base64.b64decode(re.search(r'tile_map_data = PackedByteArray\("([^"]+)',s)[1])
cells=list(struct.iter_unpack('<hhHHHH',raw[2:]))
removed=[];kept=[]
for c in cells:
    x,y,_,kind,*_=c; wx,wy=x*128,y*128
    tower=896<=wx<2048 and -2176<=wy<1920
    house=128<=wx<512 and -512<=wy<0 and kind==0
    workshop=2304<=wx<2944 and -1536<=wy<-768 and kind==0
    slip=2432<=wx<3200 and -256<=wy<512
    cave=x in [-9,-8] and -9<=y<=-5
    # The original artist explicitly marks this upper boundary as open air.
    ceiling=y<-17 and -896<=wx<5376
    if tower or house or workshop or slip or cave or ceiling:removed.append(c)
    else:kept.append(c)
encoded=base64.b64encode(raw[:2]+b''.join(struct.pack('<hhHHHH',*c) for c in kept)).decode()
s=re.sub(r'(tile_map_data = PackedByteArray\(")[^"]+',lambda m:m[1]+encoded,s)
s=re.sub(r'^\[gd_scene[^\n]+','[gd_scene format=4]',s)
s=s.replace('[node name="BlueLakeGreybox"','[node name="BlueLakesideKritaPlaytest"',1)
s=s.replace('editor_description = "Lake authoring starter. Swimming unlocked here only. Draw water and air pockets with Room Greybox; paint the underwater route on GreyboxTerrain."','editor_description = "F6: saved Krita map at 1:1 scale plus approved 3D village buildings. Original terrain, water, air pockets, breakables and actors retained. Building guides replaced by matching 2D collision. Lights and foliage remain editable nodes."\nscript = ExtResource("map_script")')
exts=[('Script','res://Src/Environment/BlueBiome/Prototypes/lakeside_krita_playtest.gd','map_script'),('PackedScene','res://Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_krita_artwork.tscn','map_art'),('PackedScene',BASE+'lakeside_art_stage_2d.tscn','map_stage'),('PackedScene',BASE+'central_tower_2d.tscn','map_tower'),('PackedScene',BASE+'covered_boat_slip_2d.tscn','map_slip'),('PackedScene',BASE+'net_workshop_2d.tscn','map_workshop'),('PackedScene',BASE+'fishers_house_2d.tscn','map_house'),('PackedScene',BASE+'lakeside_lantern_2d.tscn','map_lantern')]
exts.append(('PackedScene','res://Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_rock_collision.tscn','map_rocks'))
for file in sources:exts.append(('Texture2D','res://Assets/BlueBiome/Art/LakesideMap/'+file,'stamp_'+file.split('.')[0]))
pos=s.index('[node ')
s=s[:pos]+'\n'.join(f'[ext_resource type="{typ}" path="{path}" id="{key}"]' for typ,path,key in exts)+'\n\n'+s[pos:]
s=s.replace('[node name="LakePresentation" type="Node2D" parent="." unique_id=21909911]\nscript = ExtResource("5_art")','[node name="LakePresentation" type="Node2D" parent="." unique_id=21909911]\nscript = ExtResource("5_art")\nshow_terrain_art = true')
for old,new in [('limit_left = -966','limit_left = -1408'),('limit_top = -1722','limit_top = -2560'),('limit_right = 4933','limit_right = 5504'),('limit_bottom = 2669','limit_bottom = 3328')]:s=s.replace(old,new)
s=s.replace('position = Vector2(0, -80)\nlimit_left','position = Vector2(0, -80)\nzoom = Vector2(0.9, 0.9)\nlimit_left')
s=s.replace('position = Vector2(291, 275)','position = Vector2(128, 275)')
s=re.sub(r'(\[node name="GreyboxTerrain"[^\n]+\])',r'\1\ncollision_enabled = false',s)
# This obsolete rectangular test-water volume floats above the lake in the art.
s=re.sub(r'\[node name="Water" parent="Geometry"[^\n]+\][\s\S]*?(?=\[node name="BreakableWall")','',s,count=1)
s=s.replace('[editable path="Geometry/Water"]\n','')
tail=['\n[node name="TerrainArtwork" parent="Geometry" instance=ExtResource("map_art")]','\n[node name="LakesideArtStage" parent="." instance=ExtResource("map_stage")]','preview_center = Vector2(2048, 384)','preview_zoom = 0.17','\n[node name="Buildings" type="Node2D" parent="."]']
tail.insert(1,'\n[node name="RockCollision" parent="Geometry" instance=ExtResource("map_rocks")]')
places={'Tower':('map_tower',1472,1920),'BoatSlip':('map_slip',2816,477.44),'Workshop':('map_workshop',2688,-960.64),'FisherHouse':('map_house',320,-46.72)}
for name,(key,x,y) in places.items():tail += [f'\n[node name="{name}" parent="Buildings" instance=ExtResource("{key}")]',f'position = Vector2({x}, {y})']
tail += ['\n[node name="BuildingCollision" type="Node2D" parent="Geometry"]','editor_description = "2D physics matching the model surfaces at 128 px per Blender unit. No collision across the boat-slip center or tower basin opening."']
shapes=[]; surfaces=[]
def rect(name,x0,y0,x1,y1,oneway=False):
    assert x1>x0 and y1>y0
    w=(x1-x0)/2;h=(y1-y0)/2
    tail.extend([f'\n[node name="{name}" type="StaticBody2D" parent="Geometry/BuildingCollision"]',f'position = Vector2({(x0+x1)/2:.4f}, {(y0+y1)/2:.4f})','collision_layer = 1','collision_mask = 0',f'\n[node name="Outline" type="CollisionPolygon2D" parent="Geometry/BuildingCollision/{name}"]',f'polygon = PackedVector2Array({-w:.4f}, {-h:.4f}, {w:.4f}, {-h:.4f}, {w:.4f}, {h:.4f}, {-w:.4f}, {h:.4f})'])
    if oneway:tail.extend(['one_way_collision = true','one_way_collision_margin = 12.0'])
    surfaces.append(dict(name=name,rect=[x0,y0,x1,y1],one_way=oneway))
def floor(name,cx,anchor,x0,x1,z):rect(name,cx+x0*128,anchor-z*128,cx+x1*128,anchor-z*128+12,True)
for j,(za,zb,cx,th) in enumerate([(0,.82,4.3775,.62),(.82,5.9,3.53,1.05),(5.9,24.9,2.95,.82),(24.9,29.65,2.15,.78),(29.65,31.48,2.28,1.05)]):
    for sign,label in [(-1,'Left'),(1,'Right')]:
        xx=sign*cx
        rect(f'TowerWall{label}{j}',1472+(xx-th/2)*128,1920-zb*128,1472+(xx+th/2)*128,1920-za*128)
for j,(z,kind) in enumerate([(6.35,'full'),(8.24,'leftshort'),(8.98,'rightshort'),(11.48,'full'),(14.30,'right'),(17,'left'),(19.65,'full'),(23,'full'),(26.65,'upper')]):
    x0,x1={'full':(-2.6,2.6),'leftshort':(-2.6,-.5),'rightshort':(.45,2.6),'right':(-.25,2.6),'left':(-2.6,.2),'upper':(-1.82,1.82)}[kind]
    floor('TowerPlatform'+str(j),1472,1920,x0,x1,z)
floor('WorkshopFloor',2688,-960.64,-3.14,3.14,.495)
floor('FisherFloor',320,-46.72,-2.14,2.14,.635)
floor('FisherLoft',320,-46.72,-1.97,1.97,3.10)
for sign,label in [(-1,'Left'),(1,'Right')]:floor('SlipDeck'+label,2816,477.44,sign*2.85-.46,sign*2.85+.46,.73)
# Roof walking follows the hip silhouette; narrow one-way slabs allow jumping up.
for prefix,cx,anchor,w,d,eave,rise in [('Fisher',320,-46.72,5.68,5.08,4.85,1.38),('Workshop',2688,-960.64,7.68,5.18,3.46,1.22),('Slip',2816,477.44,7.94,4.94,6.13,1.2)]:
    A=w/2;r=(w-d)/2
    def roof_top(x):
        t=max(0,min(1,(abs(x)-r)/(A-r)))
        return anchor-128*(eave+rise*(1-t)**1.14+.095*t**8+.21*t**4+.10)
    for i in range(20):
        x0=-A+i*w/20;x1=-A+(i+1)*w/20;x=(x0+x1)/2
        t=max(0,min(1,(abs(x)-r)/(A-r)))
        z=eave+rise*(1-t)**1.14+.095*t**8+.21*t**4+.10
        floor(prefix+'Roof'+str(i),cx,anchor,x0,x1,z)
        # Shared endpoints form a continuous ramp instead of stair-step slabs.
        body_y=anchor-z*128+6;half_width=(x1-x0)*64
        left,right=roof_top(x0)-body_y,roof_top(x1)-body_y
        points=[-half_width,left,half_width,right,half_width,right+12,-half_width,left+12]
        tail[-3]='polygon = PackedVector2Array('+', '.join(f'{p:.4f}' for p in points)+')'
# The artist's original bridge landings remain one-way. Give each visible deck art.
tail+=['\n[node name="BridgeLandings" type="Node2D" parent="Geometry"]','z_index = 6']
oneways={(c[0],c[1]) for c in kept if c[3]==1}
idx=0
for x,y in sorted(oneways,key=lambda c:(c[1],c[0])):
    if (x-1,y) in oneways:continue
    end=x+1
    while (end,y) in oneways:end+=1
    idx+=1;width=(end-x)*128
    tail += [f'\n[node name="Deck{idx:02}" type="Sprite2D" parent="Geometry/BridgeLandings"]',f'position = Vector2({x*128}, {y*128})',f'scale = Vector2({width/512:.5f}, 0.65)','texture = ExtResource("stamp_walking_deck")','centered = false']
    rect(f'BridgeLanding{idx:02}',x*128,y*128,end*128,y*128+10,True)
# Parent breakables retain their existing fracture behavior; only their drawing changes.
from PIL import Image
im=Image.open(ART/'quarry_block.png')
for parent in ['Geometry/BreakableWall','Volumes/BreakableWall','BreakableWall']:
    node_header=next(m for m in re.finditer(r'\[node [^\n]+',s) if f'name="BreakableWall"' in m[0] and (f'parent="{parent.rsplit("/",1)[0]}"' in m[0] if '/' in parent else 'parent="."' in m[0]))
    insert=node_header.end();s=s[:insert]+'\nself_modulate = Color(1, 1, 1, 0)'+s[insert:]
    tail += [f'\n[node name="StoneSealArtwork" type="Sprite2D" parent="{parent}"]',f'scale = Vector2({128/im.width}, {384/im.height})','texture = ExtResource("stamp_quarry_block")']
tail += ['\n[node name="Lighting" type="Node2D" parent="."]','editor_description = "Editable 3D+2D lantern instances. Add more here; tune sunlight on LakesideArtStage."']
for name,x,y in [('CaveLantern',-1080,-650),('FisherLantern',84,-332),('WorkshopLantern',2381,-1245),('SlipLantern',2460,-242)]:
    tail += [f'\n[node name="{name}" parent="Lighting" instance=ExtResource("map_lantern")]',f'position = Vector2({x}, {y})']
for name,z in [('RearFoliage',-5),('FrontFoliage',9)]:tail += [f'\n[node name="{name}" type="Node2D" parent="."]',f'z_index = {z}','editor_description = "Place separate foliage scenes here so sway and lights remain editable in Godot."']
tail += ['\n[node name="OverviewCamera" type="Camera2D" parent="."]','position = Vector2(2048, 384)','zoom = Vector2(0.17, 0.17)','enabled = false']
pos=s.index('[node ');s=s[:pos]+'\n'.join(shapes)+'\n\n'+s[pos:]
pos=s.index('[editable path=');s=s[:pos]+'\n'.join(tail)+'\n\n'+s[pos:]
s+='\n[editable path="Geometry/RockCollision"]\n[editable path="Geometry/TerrainArtwork"]\n'
(SCENES/'blue_lakeside_krita_playtest.tscn').write_text(s)
manifest['assembly']=dict(source_room_sha256=source_hash,source_cells=len(cells),retained_cells=len(kept),removed_cells=len(removed),legacy_tiles_collide=False,terrain_collision='Editable polygons traced from painted stone alpha; no greybox physics',building_positions={k:[v[1],v[2]] for k,v in places.items()},surfaces=surfaces,stamp_sources=sources)
(ART/'map_manifest.json').write_text(json.dumps(manifest,indent=2))
print('ASSEMBLED',len(kept),'retained tiles;',len(removed),'obsolete guide/cave tiles removed;',len(surfaces),'matching model collision surfaces')
