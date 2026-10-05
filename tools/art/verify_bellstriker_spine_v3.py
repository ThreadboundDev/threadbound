"""Inspect the saved v3's actual weights, chain continuity and claw deformation."""
from pathlib import Path
import bpy
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Enemies/Bellstriker_Boxing_v3.blend'))
rig = bpy.data.objects['Bellstriker_Rig']
scene = bpy.context.scene
assert len(rig.data.bones) == 44
chain = ['abdomen', 'tail.01', 'tail.02', 'tail.03', 'tail.04', 'tail_fan']
for i, name in enumerate(chain):
    bone = rig.data.bones[name]
    assert bone.parent.name == ('body' if i == 0 else chain[i-1])
    if i:
        assert bone.use_connect and (bone.head_local-bone.parent.tail_local).length < .0001
shell = bpy.data.objects['Bellstriker_Shell']
assert rig.data.bones['tail_fan'].tail_local.x < min(v.co.x for v in shell.data.vertices)
fan_vertices = 0
for mesh in [o for o in scene.objects if o.type == 'MESH']:
    for vertex in mesh.data.vertices:
        assert abs(sum(g.weight for g in vertex.groups)-1) < .0001
        if mesh == shell and vertex.co.x < -1.75:
            weights = [(mesh.vertex_groups[g.group].name, g.weight) for g in vertex.groups if g.weight > .001]
            assert weights == [('tail_fan', 1.0)], weights
            fan_vertices += 1
assert fan_vertices > 5
print('PASS connected tail reaches beyond mesh tip; every vertex normalized; fan is rigidly attached')
bands = [(-.8, -.35), (-1.3, -.8), (-1.8, -1.3)]
heights = [[] for _ in bands]
rig.animation_data.action = bpy.data.actions['swim']
for frame in [1, 10, 19, 28, 37]:
    scene.frame_set(frame)
    graph = bpy.context.evaluated_depsgraph_get()
    evaluated_shell = shell.evaluated_get(graph)
    deformed = evaluated_shell.to_mesh()
    for index, (low, high) in enumerate(bands):
        vertices = [v.index for v in shell.data.vertices if low <= v.co.x < high and v.co.z > .40]
        assert vertices
        heights[index].append(sum(deformed.vertices[i].co.z for i in vertices)/len(vertices))
    evaluated_shell.to_mesh_clear()
for index, samples in enumerate(heights):
    span = max(samples)-min(samples)
    print('SWIM_LOWER_BODY_BAND', bands[index], 'vertical range', span)
    assert span > [.025, .08, .15][index], 'Entire lower body must move, not just its end'
for clip, frame in [('box_idle', 1), ('water_charge_3', 20), ('water_jab', 7)]:
    rig.animation_data.action = bpy.data.actions[clip]
    scene.frame_set(frame)
    graph = bpy.context.evaluated_depsgraph_get()
    for side in ['L', 'R']:
        mesh = bpy.data.objects['Bellstriker_Claw_'+side]
        group_names = {mesh.vertex_groups[g.group].name for v in mesh.data.vertices for g in v.groups if g.weight > .001}
        assert group_names == {'claw.'+side}, group_names
        evaluated = mesh.evaluated_get(graph).to_mesh()
        for a, b in [(0, len(mesh.data.vertices)-1), (len(mesh.data.vertices)//4, 3*len(mesh.data.vertices)//4)]:
            original_length = (mesh.data.vertices[a].co-mesh.data.vertices[b].co).length
            posed_length = (evaluated.vertices[a].co-evaluated.vertices[b].co).length
            assert abs(original_length-posed_length) < .0001, 'Claw shell must remain rigid through the punch'
        center = sum((v.co for v in evaluated.vertices), Vector())/len(evaluated.vertices)
        print('DEFORMED_CLAW', clip, side, tuple(center), 'bone', tuple(rig.pose.bones['claw.'+side].head))
        mesh.evaluated_get(graph).to_mesh_clear()
print('BELL_SPINE_SOURCE_CHECKS_PASS')
