from pathlib import Path
from collections import defaultdict
import bpy
import json

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'work/eave-runner-v3'


def bounds(points):
    if not points:
        return None
    low = [min(p[i] for p in points) for i in range(3)]
    high = [max(p[i] for p in points) for i in range(3)]
    return {'minimum': low, 'maximum': high, 'dimensions': [high[i]-low[i] for i in range(3)]}


def examine(path, rig_name):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    rig = bpy.data.objects[rig_name]
    rig.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH' and (obj.parent == rig or any(
        m.type == 'ARMATURE' and m.object == rig for m in obj.modifiers))]
    if not meshes:
        print('EMPTY_MESH_DIAGNOSTIC', [(obj.name, obj.type, obj.parent.name if obj.parent else None,
              [(m.type, m.object.name if m.type == 'ARMATURE' and m.object else None) for m in obj.modifiers])
             for obj in bpy.data.objects], flush=True)
    records = {'path': str(path), 'rig': rig.name, 'meshes': [], 'bone_heads_tails': {},
               'strongest_bone_vertex_counts': {}, 'material_surfaces': {}}
    all_points, all_bone_points = [], defaultdict(list)
    material_points = defaultdict(list)
    material_faces = defaultdict(int)
    material_bones = defaultdict(lambda: defaultdict(int))
    for bone in rig.data.bones:
        records['bone_heads_tails'][bone.name] = {
            'head': list(rig.matrix_world @ bone.head_local),
            'tail': list(rig.matrix_world @ bone.tail_local),
            'length': bone.length, 'parent': bone.parent.name if bone.parent else None}
    for obj in meshes:
        data = obj.data
        points = [obj.matrix_world @ vertex.co for vertex in data.vertices]
        all_points.extend(points)
        dominant = []
        for vertex in data.vertices:
            items = [(obj.vertex_groups[g.group].name, g.weight) for g in vertex.groups if g.weight > 1e-7]
            name = max(items, key=lambda item: item[1])[0] if items else 'UNWEIGHTED'
            dominant.append(name)
            all_bone_points[name].append(points[vertex.index])
        per_mesh_material = defaultdict(set)
        for polygon in data.polygons:
            material = data.materials[polygon.material_index] if polygon.material_index < len(data.materials) else None
            name = material.name if material else 'NONE'
            material_faces[name] += len(polygon.vertices)-2
            per_mesh_material[name].update(polygon.vertices)
        for name, ids in per_mesh_material.items():
            material_points[name].extend(points[i] for i in ids)
            for index in ids:
                material_bones[name][dominant[index]] += 1
        if obj.name == 'Threadborne_Character':
            parent = list(range(len(points)))
            def find(index):
                while parent[index] != index:
                    parent[index] = parent[parent[index]]
                    index = parent[index]
                return index
            def union(a, b):
                root_a, root_b = find(a), find(b)
                if root_a != root_b:
                    parent[root_b] = root_a
            same_positions = {}
            for index, point in enumerate(points):
                key = tuple(round(axis*100000) for axis in point)
                if key in same_positions:
                    union(index, same_positions[key])
                else:
                    same_positions[key] = index
            for face in data.polygons:
                first = face.vertices[0]
                for index in face.vertices[1:]:
                    union(first, index)
            components = defaultdict(list)
            for index in range(len(points)):
                components[find(index)].append(index)
            records['geometrically_connected_components'] = []
            for ids in sorted(components.values(), key=len, reverse=True):
                if len(ids) < 128:
                    continue
                counts = defaultdict(int)
                for index in ids:
                    counts[dominant[index]] += 1
                records['geometrically_connected_components'].append({
                    'vertices': len(ids), 'bounds': bounds([points[index] for index in ids]),
                    'strongest_bones': dict(counts)})
        records['meshes'].append({'name': obj.name, 'vertices': len(data.vertices),
                                 'triangles': sum(len(p.vertices)-2 for p in data.polygons),
                                 'bounds': bounds(points), 'materials': list(per_mesh_material)})
    records['bounds'] = bounds(all_points)
    for name, points in all_bone_points.items():
        records['strongest_bone_vertex_counts'][name] = {'vertices': len(points), 'bounds': bounds(points)}
    for name, points in material_points.items():
        records['material_surfaces'][name] = {'triangles': material_faces[name], 'vertices': len(points),
                                             'bounds': bounds(points), 'strongest_bones': dict(material_bones[name])}
    records['horizontal_slices'] = {}
    for height in [.15, .3, .5, .7, .9, 1.0, 1.1, 1.2, 1.35, 1.45, 1.5, 1.6, 1.7]:
        records['horizontal_slices'][str(height)] = bounds([p for p in all_points if abs(p.z-height) <= .025])
    return records


player = examine(OUT / 'player_reference_only.blend', 'Threadborne_Rig')
eave = examine(ROOT / 'ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v3.blend', 'EaveRunner_Rig')
(OUT / 'player_shape_analysis.json').write_text(json.dumps({'player': player, 'eave_v3': eave}, indent=2))
for name, result in [('PLAYER', player), ('EAVE', eave)]:
    print(name, 'meshcount', len(result['meshes']), 'bounds', result['bounds'], flush=True)
    print(name, 'bones', json.dumps(result['bone_heads_tails']), flush=True)
    print(name, 'materials', json.dumps(result['material_surfaces']), flush=True)
