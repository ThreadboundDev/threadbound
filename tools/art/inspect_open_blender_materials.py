"""Read-only inventory of the open Blender scene and material availability."""
import bpy
import json

print(json.dumps({
    'file': bpy.data.filepath,
    'active_viewports': [{'screen': w.screen.name, 'shading': a.spaces.active.shading.type}
                        for w in bpy.context.window_manager.windows
                        for a in w.screen.areas if a.type == 'VIEW_3D'],
    'objects': [{'name': o.name, 'type': o.type,
                 'vertices': len(o.data.vertices) if o.type == 'MESH' else None,
                 'materials': [s.material.name if s.material else None for s in o.material_slots],
                 'uvs': len(o.data.uv_layers) if o.type == 'MESH' else None,
                 'modifiers': [m.type for m in o.modifiers]}
                for o in bpy.context.scene.objects],
    'materials': [{'name': m.name,
                   'links': [(l.from_node.type, l.from_socket.name, l.to_node.type, l.to_socket.name)
                             for l in m.node_tree.links] if m.use_nodes else [],
                   'nodes': [(n.type, n.image.name if n.type == 'TEX_IMAGE' and n.image else None)
                             for n in m.node_tree.nodes] if m.use_nodes else [],
                   'color': list(m.diffuse_color)} for m in bpy.data.materials],
    'images': [{'name': i.name, 'path': i.filepath, 'packed': bool(i.packed_file),
                'size': list(i.size)} for i in bpy.data.images],
    'viewports': [a.spaces.active.shading.type for s in bpy.data.screens
                  for a in s.areas if a.type == 'VIEW_3D'],
}, indent=2))
