"""Lossless KRA layer extraction for this saved RGBA8, normal-blend map.

Reads the documented Krita VERSION 2 64px LZF tile format. Never writes KRA.
The recomposed visible layers are checked against Krita's saved projection.
"""
from pathlib import Path
import argparse, hashlib, io, json, sys, zipfile
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
WORK = Path(__file__).resolve().parent
SOURCE = Path('C:/Users/chase/Documents/Codex/2026-10-07/ri/outputs/blue_village_stamp_pack/cave_connections_v1/Blue_Village_Connections_Review.kra')
OUT = ROOT / 'Assets/BlueBiome/Art/LakesideMap'
OUT.mkdir(parents=True, exist_ok=True)
NS = {'k': 'http://www.calligra.org/DTD/krita'}
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--rear-supports-only', action='store_true', help='Update only the approved rear wood/rock layer split')
parser.add_argument('--underwater-only', action='store_true', help='Import only the named underwater background; preserve all existing artwork and physics')
args = parser.parse_args()
SUPPORTS_ONLY = args.rear_supports_only
assert not (SUPPORTS_ONLY and args.underwater_only), 'Choose one scoped import'


def chunk_images(canvas, label):
    for y in range(0, canvas.height, 1024):
        for x in range(0, canvas.width, 1024):
            chunk = canvas.crop((x, y, min(x+1024, canvas.width), min(y+1024, canvas.height)))
            if chunk.getchannel('A').getbbox():
                yield dict(group=label, path=f'{label}_{x//1024:02}_{y//1024:02}.png',
                           position=[x-1408, y-2560], size=list(chunk.size)), chunk


def layer_mapping():
    return {'rear_supports': ['STAMP REAR SUPPORTS'],
            'rear_cave': ['Under Cave Mouth', 'Cave Walls']}

UNDERWATER_PRESENTATION = dict(scroll_scale=[0.50, 0.75], anchor_world=[2048, 1600], depth_offset=[0,600],
                               reference_viewport=[1920, 1080], water_surface_y=411, z_index=-8)

def compose_underwater_scene(scene, entries):
    """Scoped reimport preserves independent far parallax and world-space clipping."""
    import re
    scene = re.sub(r'^\[ext_resource[^\n]* id="underwater_(?:\d+|scroll|material)"\]\n', '', scene, flags=re.M)
    scene = re.sub(r'\n\[node (?:name="underwater_background" type="(?:Node2D|Parallax2D)" parent="\."|name="Rock_\d+" type="Sprite2D" parent="underwater_background")\]\n.*?(?=\n\[|\Z)', '', scene, flags=re.S)
    resources = '\n'.join(f'[ext_resource type="Texture2D" path="res://Assets/BlueBiome/Art/LakesideMap/{entry["path"]}" id="underwater_{i}"]' for i,entry in enumerate(entries))
    resources += '\n[ext_resource type="Script" path="res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/anchored_parallax_2d.gd" id="underwater_scroll"]'
    resources += '\n[ext_resource type="Material" path="res://Src/Environment/BlueBiome/ArtPlaceables/Background/underwater_rock_clip.tres" id="underwater_material"]'
    offset = scene.index('[node ')
    scene = scene[:offset].rstrip()+'\n\n'+resources+'\n\n'+scene[offset:]
    sx,sy = UNDERWATER_PRESENTATION['scroll_scale']
    ax,ay = UNDERWATER_PRESENTATION['anchor_world']
    vw,vh = UNDERWATER_PRESENTATION['reference_viewport']
    dx,dy = UNDERWATER_PRESENTATION.get('depth_offset',[0,0])
    scene += '\n[node name="underwater_background" type="Parallax2D" parent="."]\nz_index = -8\n'
    scene += 'editor_description = "Far underwater rock only; timber stays in its independent world-locked rear_supports group. Original coordinates agree at the lake-center camera anchor."\n'
    scene += 'material = ExtResource("underwater_material")\nscript = ExtResource("underwater_scroll")\n'
    # Native centered Camera2D scrolling includes half the logical viewport.
    # Preserve authored coordinates at this camera-center reference (GPU checked).
    scene += f'scroll_scale = Vector2({sx}, {sy})\nplacement_anchor_path = NodePath("..")\nplacement_offset = Vector2({-(ax-vw/2)*(1-sx)+dx:.3f}, {-(ay-vh/2)*(1-sy)+dy:.3f})\n'
    for i,entry in enumerate(entries):
        x,y = entry['position']
        scene += f'\n[node name="Rock_{i:02}" type="Sprite2D" parent="underwater_background"]\nposition = Vector2({x}, {y})\ntexture = ExtResource("underwater_{i}")\ncentered = false\nuse_parent_material = true\n'
    return scene.rstrip()+'\n'

def lzf(data):
    out = bytearray()
    i = 0
    while i < len(data):
        ctrl = data[i]; i += 1
        if ctrl < 32:
            length = ctrl + 1
            out.extend(data[i:i+length]); i += length
        else:
            length = ctrl >> 5
            offset = (ctrl & 31) << 8
            if length == 7:
                length += data[i]; i += 1
            offset += data[i] + 1; i += 1
            for _ in range(length + 2):
                out.append(out[-offset])
    assert len(out) == 16384, len(out)
    return out

with zipfile.ZipFile(SOURCE) as z:
    doc = ET.fromstring(z.read('maindoc.xml'))
    image = doc.find('k:IMAGE', NS)
    size = (int(image.get('width')), int(image.get('height')))
    iname = image.get('name')
    manifest = dict(source=str(SOURCE), source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(), canvas=list(size), world_origin=[-1408,-2560], pixels_per_unit=1, groups=[], chunks=[])

    def decode(node):
        assert node.get('colorspacename') == 'RGBA'
        assert node.get('compositeop') == 'normal'
        key = iname + '/layers/' + node.get('filename')
        assert z.read(key + '.defaultpixel') == bytes(4)
        stream = io.BytesIO(z.read(key))
        header = [stream.readline().strip() for _ in range(5)]
        assert header[:4] == [b'VERSION 2', b'TILEWIDTH 64', b'TILEHEIGHT 64', b'PIXELSIZE 4'], header
        count = int(header[4].split()[1])
        canvas = Image.new('RGBA', size)
        for _ in range(count):
            x,y,codec,length = stream.readline().strip().split(b',')
            assert codec == b'LZF'
            block = stream.read(int(length))
            if block[0] == 1:
                raw = np.frombuffer(lzf(block[1:]), dtype=np.uint8).reshape(4,4096).T.copy().tobytes()
            else:
                assert block[0] == 0
                raw = block[1:]
            tile = Image.frombytes('RGBA',(64,64),raw,'raw','BGRA')
            canvas.paste(tile,(int(x)+int(node.get('x','0')),int(y)+int(node.get('y','0'))))
        opacity = int(node.get('opacity','255'))
        if opacity != 255:
            canvas.putalpha(canvas.getchannel('A').point(lambda a: round(a*opacity/255)))
        return canvas

    groups = image.find('k:layers', NS)
    if args.underwater_only:
        nodes = [node for node in image.iter() if node.get('name', '').strip().casefold() == 'underwater background']
        assert len(nodes) == 1, 'Expected exactly one Underwater background layer'
        node = nodes[0]
        assert node.get('nodetype') == 'paintlayer'
        assert size == (6912, 5888), 'Map canvas changed; review alignment first'
        canvas = decode(node)
        chunks = list(chunk_images(canvas, 'underwater_background'))
        assert chunks, 'Underwater background is empty'
        reconstructed = Image.new('RGBA', size)
        for entry, chunk in chunks:
            x, y = entry['position']
            reconstructed.paste(chunk, (x+1408, y+2560))
        assert ImageChops.difference(canvas, reconstructed).getbbox(alpha_only=False) is None
        scene_path = ROOT/'Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_krita_artwork.tscn'
        scene = scene_path.read_text()
        # Replace only this import's resources/nodes on rerun. Existing node
        # names, order, materials, positions and all gameplay remain intact.
        scene = compose_underwater_scene(scene,[entry for entry,_ in chunks])
        for entry, chunk in chunks:
            chunk.save(OUT/entry['path'])
        scene_path.write_text(scene.rstrip()+'\n')
        record = dict(source=manifest['source'], source_sha256=manifest['source_sha256'],
                      layer=node.get('name'), layer_uuid=node.get('uuid'), canvas=list(size),
                      world_origin=[-1408, -2560], pixels_per_unit=1, z_index=-8,
                      bounds=list(canvas.getbbox()), reconstruction='pixel-exact RGBA',
                      chunks=[entry for entry, _ in chunks])
        record['presentation'] = UNDERWATER_PRESENTATION
        (OUT/'underwater_background_manifest.json').write_text(json.dumps(record, indent=2)+'\n')
        print('UNDERWATER_ONLY', len(chunks), 'chunks; pixel-exact reconstruction; existing artwork and physics preserved')
        sys.exit(0)
    if SUPPORTS_ONLY:
        # Update only this approved layer split. Never regenerate physics, the
        # playable room, unrelated textures, or historical source/preview files.
        previous = json.loads((OUT/'map_manifest.json').read_text())
        assert previous['source_sha256'] == manifest['source_sha256'], 'Source changed; review a full map reimport first'
        rear = next(group for group in groups if group.get('filename') == 'layer17')
        rocks = Image.new('RGBA', size)
        wood = Image.new('RGBA', size)
        original = Image.new('RGBA', size)
        for node in reversed(list(rear.find('k:layers', NS))):
            if node.get('visible') != '1':
                continue
            leaf = decode(node)
            original.alpha_composite(leaf)
            if node.get('filename') == 'layer20':
                assert node.get('name') == 'STAMP REAR SUPPORTS'
                wood.alpha_composite(leaf)
            else:
                assert node.get('filename') in ('layer18', 'layer19'), 'Unexpected rear layer: review scope'
                rocks.alpha_composite(leaf)
        wood_chunks = list(chunk_images(wood, 'rear_supports'))
        rock_chunks = list(chunk_images(rocks, 'rear_cave'))
        affected = {entry['path'].replace('rear_supports_', 'rear_cave_') for entry, _ in wood_chunks}
        old_rocks = {c['path']: c for c in previous['chunks'] if c['group'] == 'rear_cave'}
        old_wood = {c['path']: c for c in previous['chunks'] if c['group'] == 'rear_supports'}
        max_error = 0
        pixels_over_two = 0
        # Validate the split BEFORE overwriting any runtime files. Joining the
        # unfiltered layers must recover the original imported projection.
        for entry, rock in rock_chunks:
            x, y = entry['position'][0]+1408, entry['position'][1]+2560
            box = (x, y, x+rock.width, y+rock.height)
            joined = wood.crop(box)
            joined.alpha_composite(rock)
            expected = original.crop(box)
            diff = np.abs(np.asarray(joined, dtype=np.int16) - np.asarray(expected, dtype=np.int16))
            max_error = max(max_error, int(diff.max()))
            pixels_over_two += int(np.count_nonzero(np.max(diff, axis=2) > 2))
            assert entry['path'] in old_rocks, 'Unexpected new rock tile outside scoped import'
            imported = Image.open(OUT/entry['path']).convert('RGBA')
            support_path = entry['path'].replace('rear_cave_', 'rear_supports_')
            if support_path in old_wood:
                previous_join = Image.open(OUT/support_path).convert('RGBA')
                previous_join.alpha_composite(imported)
                imported = previous_join
            old_diff = np.abs(np.asarray(imported, dtype=np.int16) - np.asarray(expected, dtype=np.int16))
            assert old_diff.max() <= 2, 'Imported rear artwork differs from the verified source'
            if entry['path'] not in affected:
                assert np.array_equal(np.asarray(rock), np.asarray(Image.open(OUT/entry['path']))), 'Unrelated rock tile changed'
        assert pixels_over_two == 0, 'Separated layers do not reconstruct the source'
        for entry, chunk in rock_chunks:
            if entry['path'] in affected:
                chunk.save(OUT/entry['path'])
        for entry, chunk in wood_chunks:
            chunk.save(OUT/entry['path'])
        previous['groups'] = [g for g in previous['groups'] if g['name'] not in ('rear_supports', 'rear_cave')]
        previous['groups'][0:0] = [dict(name='rear_supports', bounds=wood.getchannel('A').getbbox()),
                                  dict(name='rear_cave', bounds=rocks.getchannel('A').getbbox())]
        previous['chunks'] = [entry for entry, _ in rock_chunks] + [c for c in previous['chunks'] if c['group'] not in ('rear_supports', 'rear_cave')] + [entry for entry, _ in wood_chunks]
        previous['rear_layer_sources'] = layer_mapping()
        previous['rear_layer_split_check'] = dict(max_channel_error=max_error, pixels_over_two=pixels_over_two)
        (OUT/'map_manifest.json').write_text(json.dumps(previous, indent=2)+'\n')
        print('REAR_SUPPORT_SPLIT', json.dumps(dict(rock_chunks=len(rock_chunks), support_chunks=len(wood_chunks), max_channel_error=max_error, pixels_over_two=pixels_over_two)), flush=True)
        sys.exit(0)

    visible = Image.new('RGBA',size)
    artwork = Image.new('RGBA',size)
    names = {'layer7':'foreground','layer9':'bridges','layer12':'breakables','layer14':'terrain','layer17':'rear_cave'}
    for group in reversed(list(groups)):
        merged = Image.new('RGBA',size)
        rear_rocks = Image.new('RGBA',size)
        rear_wood = Image.new('RGBA',size)
        for node in reversed(list(group.find('k:layers',NS))):
            if node.get('visible') != '1': continue
            leaf = decode(node)
            merged.alpha_composite(leaf)
            if group.get('filename') == 'layer17':
                if node.get('filename') == 'layer20':
                    rear_wood.alpha_composite(leaf)
                else:
                    rear_rocks.alpha_composite(leaf)
            bbox = leaf.getchannel('A').getbbox()
            if bbox:
                leaf.save(WORK/(node.get('filename')+'.png'))
            print(node.get('name'),bbox,flush=True)
        visible.alpha_composite(merged)
        label = names.get(group.get('filename'))
        if not label: continue
        artwork.alpha_composite(merged)
        if label == 'rear_cave':
            joined = rear_wood.copy()
            joined.alpha_composite(rear_rocks)
            diff = np.abs(np.asarray(joined, dtype=np.int16) - np.asarray(merged, dtype=np.int16))
            manifest['rear_layer_split_check'] = dict(max_channel_error=int(diff.max()), pixels_over_two=int(np.count_nonzero(np.max(diff, axis=2) > 2)))
            assert manifest['rear_layer_split_check']['pixels_over_two'] == 0
        exports = [('rear_supports', rear_wood), ('rear_cave', rear_rocks)] if label == 'rear_cave' else [(label, merged)]
        for export_label, canvas in exports:
            manifest['groups'].append(dict(name=export_label,bounds=canvas.getchannel('A').getbbox()))
            # Independent 1024px chunks preserve alpha margins and 1:1 scale.
            for entry, chunk in chunk_images(canvas, export_label):
                chunk.save(OUT/entry['path'])
                manifest['chunks'].append(entry)
    manifest['rear_layer_sources'] = layer_mapping()
    saved=Image.open(io.BytesIO(z.read('mergedimage.png'))).convert('RGBA')
    # Krita and Pillow round 8-bit compositing slightly differently.
    dif=np.abs(np.asarray(visible,dtype=np.int16)-np.asarray(saved,dtype=np.int16))
    manifest['projection_check']=dict(max_channel_error=int(dif.max()),mean_channel_error=float(dif.mean()),fraction_over_two=float(np.mean(np.max(dif,axis=2)>2)))
    print('PROJECTION_CHECK',manifest['projection_check'],flush=True)
    assert manifest['projection_check']['fraction_over_two'] < .002, 'Layer decoding does not match saved Krita projection'
    visible.thumbnail((1382,1178));visible.save(WORK/'reference_preview.png')
    artwork.thumbnail((1382,1178));artwork.save(WORK/'art_preview.png')
    (OUT/'map_manifest.json').write_text(json.dumps(manifest,indent=2))
    print('CHUNKS',len(manifest['chunks']),flush=True)
