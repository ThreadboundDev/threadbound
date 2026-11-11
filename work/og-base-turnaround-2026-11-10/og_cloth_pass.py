from pathlib import Path
import bpy

out = Path(bpy.data.filepath).parent
scene = bpy.context.scene
body = next(o for o in scene.objects if o.type == 'MESH')
material = body.data.materials[0]
nodes, links = material.node_tree.nodes, material.node_tree.links
geo = next(n for n in nodes if n.type == 'NEW_GEOMETRY')
texture = next(n for n in nodes if n.type == 'TEX_IMAGE')
ink = next(n for n in nodes if n.label == 'OG oval eye paint')
shade = ink.inputs[1].links[0].from_socket
position = nodes.new('ShaderNodeSeparateXYZ')
links.new(geo.outputs['Position'], position.inputs[0])
colors = nodes.new('ShaderNodeSeparateColor')
links.new(texture.outputs['Color'], colors.inputs[0])
x, _, z = position.outputs
red, green, _ = colors.outputs

def calc(op, a, b):
    node = nodes.new('ShaderNodeMath')
    node.operation = op
    for value, socket in zip((a, b), node.inputs):
        if isinstance(value, (int, float)):
            socket.default_value = value
        else:
            links.new(value, socket)
    return node.outputs[0]

def interval(value, low, high):
    return calc('MULTIPLY', calc('GREATER_THAN', value, low), calc('LESS_THAN', value, high))

def tint(label, mask, input_color, replacement):
    node = nodes.new('ShaderNodeMixRGB')
    node.label = label
    links.new(mask, node.inputs[0])
    links.new(input_color, node.inputs[1])
    node.inputs[2].default_value = replacement
    return node.outputs[0]

hem = calc('MAXIMUM', interval(z, .208, .254), interval(z, .423, .483))
arm = calc('MULTIPLY', interval(calc('ABSOLUTE', x, 0), .16, .235), interval(z, .706, .795))
edges = calc('MAXIMUM', hem, arm)
ochre = calc('GREATER_THAN', red, calc('MULTIPLY', green, 1.46))
midtones = interval(red, .065, .43)
trim_mask = calc('MULTIPLY', .76, calc('MULTIPLY', edges, calc('MULTIPLY', ochre, midtones)))
quiet = tint('Quiet ochre fraying', trim_mask, shade, (.041, .037, .042, 1))
leg_mask = calc('MULTIPLY', interval(z, .198, .247), calc('GREATER_THAN', green, .205))
bare = tint('Plain ivory above boot cuffs', leg_mask, quiet, (.67, .43, .235, 1))
links.new(bare, ink.inputs[1])

line = scene.view_layers[0].freestyle_settings.linesets[0]
line.linestyle.thickness = 2.2
line.select_border = False
line.select_crease = False
line.select_silhouette = True
scene.camera = bpy.data.objects['Review — front three-quarter']
scene.render.filepath = str(out / 'OG_Cloth_Front.png')
bpy.ops.wm.save_as_mainfile(filepath=str(out / 'OG_Cloth_Review.blend'))
for label, camera in [('Front', 'Review — front three-quarter'), ('Side', 'Review — level side')]:
    scene.camera = bpy.data.objects[camera]
    scene.render.filepath = str(out / f'OG_Cloth_{label}.png')
    bpy.ops.render.render(write_still=True)
print('Cloth review renders saved', flush=True)
