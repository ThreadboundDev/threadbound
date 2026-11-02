"""Bake the authored doll materials into one embedded, glTF-compatible atlas.

Call ``bake_base_color(body)`` on the joined export-only mesh, *after* saving
the editable source and before exporting. Blender/Cycles and an active scene
are required. The mesh is modified in place; rig weights are not changed.
"""
import bpy


def bake_base_color(body, resolution=2048, margin=4):
    if body.type != 'MESH' or not body.data.polygons:
        raise ValueError('Expected a non-empty export mesh')
    if not body.data.materials or any(m is None or not m.use_nodes for m in body.data.materials):
        raise ValueError('Every material slot must contain a node material')

    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 1
    scene.render.bake.margin = margin
    scene.render.bake.use_clear = True
    scene.render.bake.use_pass_direct = False
    scene.render.bake.use_pass_indirect = False
    scene.render.bake.use_pass_color = True

    # Smart Project handles the many independent carved parts as one atlas.
    # Only the export duplicate is changed; the authored source remains editable.
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=0.006)
    bpy.ops.object.mode_set(mode='OBJECT')

    image = bpy.data.images.new('Doll baked base color', width=resolution,
                                height=resolution, alpha=False)
    targets = []
    for material in body.data.materials:
        nodes = material.node_tree.nodes
        shader = nodes.get('Principled BSDF')
        if shader is None:
            raise ValueError(f'Missing Principled BSDF in {material.name}')
        # Preserve solid-color joint and seam materials as constants. Tiny UV
        # islands can be smaller than a texel and do not need an atlas lookup.
        procedural = bool(shader.inputs['Base Color'].links)
        node = nodes.new('ShaderNodeTexImage')
        node.name = 'Doll base color bake target'
        node.image = image
        nodes.active = node
        targets.append((material, node, procedural))
    bpy.ops.object.bake(type='DIFFUSE')
    image.pack()

    # Keep each material's roughness and only replace procedural color sources.
    for material, node, procedural in targets:
        if not procedural:
            material.node_tree.nodes.remove(node)
            continue
        nodes = material.node_tree.nodes
        shader = nodes.get('Principled BSDF')
        socket = shader.inputs['Base Color']
        for link in list(socket.links):
            material.node_tree.links.remove(link)
        material.node_tree.links.new(node.outputs['Color'], socket)
    return image
