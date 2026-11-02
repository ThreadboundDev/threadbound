"""Check the saved v3 GLB against the existing player skeleton and clips.

This reads the exported file directly; it does not import or change project
assets. Visual shape, joint clearance, clothing fit and gameplay still need
separate review.
"""
from pathlib import Path
import hashlib
import json
import math
import struct

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'
EXPORT = ROOT / 'ArtSource/Player/Blender/PaleDollStudy/Threadborne_Pale_Doll_Base_v3_final.glb'
REPORT = ROOT / 'work/pale-doll-base-v3/export_verification.json'


def read_glb(path):
    raw = path.read_bytes()
    magic, version, total = struct.unpack_from('<III', raw)
    if magic != 0x46546c67 or version != 2 or total != len(raw):
        raise ValueError(f'Invalid GLB header: {path}')
    offset, document, binary = 12, None, None
    while offset < len(raw):
        if offset + 8 > len(raw):
            raise ValueError('Truncated GLB chunk header')
        size, kind = struct.unpack_from('<II', raw, offset)
        offset += 8
        if offset + size > len(raw):
            raise ValueError('Truncated GLB chunk')
        data = raw[offset:offset + size]
        offset += size
        if kind == 0x4e4f534a:
            document = json.loads(data)
        elif kind == 0x004e4942:
            binary = data
    if document is None or binary is None:
        raise ValueError('GLB needs JSON and binary chunks')
    return document, binary, raw


def values(doc, binary, index):
    a = doc['accessors'][index]
    if 'sparse' in a:
        raise ValueError('Sparse accessors are not supported by this verifier')
    view = doc['bufferViews'][a['bufferView']]
    if view.get('buffer', 0) != 0:
        raise ValueError('External buffers are not supported')
    fmt = {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}[a['componentType']]
    count = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    size = struct.calcsize(fmt) * count
    stride = view.get('byteStride', size)
    start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    end = start + (a['count'] - 1) * stride + size if a['count'] else start
    view_end = view.get('byteOffset', 0) + view['byteLength']
    if stride < size or end > view_end or end > len(binary):
        raise ValueError(f'Accessor {index} exceeds its buffer view')
    rows = [struct.unpack_from('<' + fmt * count, binary, start + i * stride)
            for i in range(a['count'])]
    if a.get('normalized') and fmt != 'f':
        limit = {5121: 255, 5123: 65535}[a['componentType']]
        rows = [tuple(v / limit for v in row) for row in rows]
    return rows


def multiply(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def rest_matrices(doc):
    parents = {child: i for i, node in enumerate(doc['nodes']) for child in node.get('children', [])}
    cache = {}

    def world(i):
        if i in cache:
            return cache[i]
        n = doc['nodes'][i]
        if 'matrix' in n:
            m = [[n['matrix'][4 * j + row] for j in range(4)] for row in range(4)]
        else:
            x, y, z, w = n.get('rotation', [0, 0, 0, 1])
            s = n.get('scale', [1, 1, 1])
            t = n.get('translation', [0, 0, 0])
            m = [[1 - 2*y*y - 2*z*z, 2*x*y - 2*z*w, 2*x*z + 2*y*w, t[0]],
                 [2*x*y + 2*z*w, 1 - 2*x*x - 2*z*z, 2*y*z - 2*x*w, t[1]],
                 [2*x*z - 2*y*w, 2*y*z + 2*x*w, 1 - 2*x*x - 2*y*y, t[2]],
                 [0, 0, 0, 1]]
            for row in range(3):
                for col in range(3):
                    m[row][col] *= s[col]
        cache[i] = multiply(world(parents[i]), m) if i in parents else m
        return cache[i]
    return {doc['nodes'][i]['name']: world(i) for i in doc['skins'][0]['joints']}


def duration(doc, binary, animation):
    times = [v[0] for sampler in animation['samplers'] for v in values(doc, binary, sampler['input'])]
    return max(times) - min(times)


def main():
    source, source_bin, source_raw = read_glb(SOURCE)
    result, result_bin, result_raw = read_glb(EXPORT)
    checks = []

    def check(name, passed, detail=None):
        checks.append({'name': name, 'passed': bool(passed), 'detail': detail})
        if not passed:
            raise AssertionError(f'{name}: {detail}')

    check('one exported skin', len(result.get('skins', [])) == 1)
    original_joints = {source['nodes'][i]['name'] for i in source['skins'][0]['joints']}
    new_joints = {result['nodes'][i]['name'] for i in result['skins'][0]['joints']}
    check('same 62 unique joint names', original_joints == new_joints and len(new_joints) == 62)
    original_rest, new_rest = rest_matrices(source), rest_matrices(result)
    max_error = max(abs(original_rest[n][i][j] - new_rest[n][i][j])
                    for n in original_rest for i in range(4) for j in range(4))
    check('joint world rest transforms preserved', max_error < 1e-5, max_error)
    original_actions = {a['name']: a for a in source.get('animations', [])}
    new_actions = {a['name']: a for a in result.get('animations', [])}
    check('same 48 animation names', original_actions.keys() == new_actions.keys() and len(new_actions) == 48)
    duration_errors = {n: abs(duration(source, source_bin, original_actions[n]) -
                              duration(result, result_bin, new_actions[n])) for n in original_actions}
    check('clip durations within one 24 fps frame', max(duration_errors.values()) <= 1/24 + 1e-4,
          max(duration_errors.values()))
    check('one joined body mesh', len(result.get('meshes', [])) == 1)
    nodes = [n for n in result['nodes'] if 'mesh' in n]
    check('body uses the exported skin', len(nodes) == 1 and nodes[0].get('skin') == 0)
    check('no exported studio camera or lights', not result.get('cameras') and
          'KHR_lights_punctual' not in result.get('extensions', {}))
    check('no external images', all('uri' not in i for i in result.get('images', [])))
    ivory = [i for i, m in enumerate(result.get('materials', []))
             if m.get('name') == 'Doll | warm worn ivory lacquer']
    check('one named ivory material', len(ivory) == 1)
    texture_info = result['materials'][ivory[0]].get('pbrMetallicRoughness', {}).get('baseColorTexture')
    check('ivory base color has a texture', texture_info is not None)
    texture = result['textures'][texture_info['index']]
    image = result['images'][texture['source']]
    check('ivory texture image is embedded', 'bufferView' in image and 'uri' not in image)
    view = result['bufferViews'][image['bufferView']]
    start, length = view.get('byteOffset', 0), view['byteLength']
    data = result_bin[start:start + length]
    check('embedded ivory image has valid header and content', len(data) == length and length > 100 and
          ((image.get('mimeType') == 'image/png' and data.startswith(b'\x89PNG\r\n\x1a\n')) or
           (image.get('mimeType') == 'image/jpeg' and data.startswith(b'\xff\xd8\xff'))))
    uv_attribute = f"TEXCOORD_{texture_info.get('texCoord', 0)}"
    ivory_primitives = 0

    vertices = triangles = 0
    for number, primitive in enumerate(result['meshes'][0]['primitives']):
        attrs = primitive['attributes']
        check(f'primitive {number}: required attributes',
              all(k in attrs for k in ('POSITION', 'NORMAL', 'JOINTS_0', 'WEIGHTS_0')))
        points = values(result, result_bin, attrs['POSITION'])
        normals = values(result, result_bin, attrs['NORMAL'])
        joints = values(result, result_bin, attrs['JOINTS_0'])
        weights = values(result, result_bin, attrs['WEIGHTS_0'])
        check(f'primitive {number}: matching nonempty vertex attributes',
              len(points) > 0 and len(points) == len(normals) == len(joints) == len(weights))
        check(f'primitive {number}: finite positions and normals',
              all(math.isfinite(v) for row in points + normals for v in row))
        check(f'primitive {number}: finite normalized nonnegative weights',
              all(all(math.isfinite(v) and v >= 0 for v in row) and abs(sum(row) - 1) < .002 for row in weights))
        check(f'primitive {number}: joint indices in range',
              all(0 <= j < len(new_joints) for row in joints for j in row))
        check(f'primitive {number}: triangle topology', primitive.get('mode', 4) == 4 and 'indices' in primitive)
        indices = values(result, result_bin, primitive['indices'])
        check(f'primitive {number}: valid triangle indices',
              len(indices) % 3 == 0 and all(0 <= index[0] < len(points) for index in indices))
        check(f'primitive {number}: valid material',
              0 <= primitive.get('material', -1) < len(result.get('materials', [])))
        if primitive.get('material') == ivory[0]:
            ivory_primitives += 1
            check(f'primitive {number}: ivory texture UVs present', uv_attribute in attrs)
            uv = values(result, result_bin, attrs[uv_attribute])
            check(f'primitive {number}: ivory UVs finite and match positions',
                  len(uv) == len(points) and all(math.isfinite(v) for row in uv for v in row))
        vertices += len(points)
        triangles += len(indices) // 3
    check('ivory material is used by body', ivory_primitives > 0)
    check('nonempty body geometry', vertices > 0 and triangles > 0, {'vertices': vertices, 'triangles': triangles})
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps({'checks': checks, 'source_sha256': hashlib.sha256(source_raw).hexdigest(),
                                  'export_sha256': hashlib.sha256(result_raw).hexdigest(),
                                  'vertices': vertices, 'triangles': triangles,
                                  'animation_duration_differences_seconds': duration_errors}, indent=2))
    print(f'PALE_DOLL_BASE_V3_VERIFIED {len(checks)} checks; {vertices} vertices; {triangles} triangles')


if __name__ == '__main__':
    main()
