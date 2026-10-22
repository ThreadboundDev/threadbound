"""Concept-led hood refinement for the separate Eave Runner v4 candidate.

Call refine(scene, rig) after loading the retained v3 source. This helper changes
only hood cloth; the ceramic face, eye apertures, rig and actions are untouched.
"""
import math
from collections import Counter

import bpy
import bmesh
from mathutils import Vector


_OLD_HOOD_PREFIXES = (
    'Tailored hood panel ', 'Hood folded charcoal lining',
    'Rolled dark face opening ', 'Hand sewn opening stitch ',
    'Hood tailored crown seam ', 'Sparse crown topstitch',
    'Hood old offset square repair', 'Hood patch fastening',
)

# z, half-width, front/back depth, centre-y, half-opening angle.
# A broad back pouch covers the original skull, unlike the shallow v3 shell.
_ROWS = (
    (1.540, .083, .100, .005, .95),
    (1.580, .094, .111, .008, .83),
    (1.625, .103, .121, .009, .76),
    (1.670, .107, .121, .009, .74),
    (1.715, .109, .122, .010, .72),
    (1.753, .107, .122, .014, .55),
    (1.780, .101, .119, .018, .00),
    (1.798, .088, .112, .025, .00),
    (1.817, .065, .089, .037, .00),
    (1.832, .032, .050, .054, .00),
    (1.837, .001, .003, .065, .00),
)


def _surface(v, u, inset=0.0):
    q = min(len(_ROWS) - 2, int(v * (len(_ROWS) - 1)))
    f = v * (len(_ROWS) - 1) - q
    z, rx, ry, cy, gap = [
        _ROWS[q][i] * (1 - f) + _ROWS[q + 1][i] * f for i in range(5)
    ]
    angle = -math.pi + gap + (math.tau - 2 * gap) * u
    front = max(0.0, -math.cos(angle))
    height = (z - 1.54) / .297
    inset = min(inset, .35 * min(rx, ry))
    # Two broad fabric gathers, not high-frequency ridges or raised wire seams.
    fold = .0
    for centre, strength in ((.105 + .025 * height, .007),
                              (.884 - .030 * height, .008)):
        d = (u - centre) / .065
        fold += strength * math.exp(-d * d)
        fold -= .003 * math.exp(-((d - 1.25) / .85) ** 2)
    fold *= (math.sin(math.pi * max(.0, min(1.0, height)))
             * math.sin(math.pi * u))
    # A broad diagonal compression fold crosses the side/back of the hood.
    # Its crest and adjacent valley interrupt the round-cap highlight without
    # introducing a floating seam or touching the ceramic's face clearance.
    crease_height = .60 + .75 * (u - .5)
    side_weight = math.sin(math.pi * u) ** 2 * math.exp(-((u - .70) / .19) ** 2)
    fold += side_weight * (
        .014 * math.exp(-((height - crease_height) / .048) ** 2)
        - .0045 * math.exp(-((height - crease_height + .070) / .040) ** 2)
    )
    # Brow projects past the ceramic without a tall squared-off helmet front.
    # Cloth flanks the ceramic rim, rather than leaving the face plate hanging
    # far in front of a shallow shell. The higher lobe supplies the brow peak.
    brow = .065 * front ** 2 * math.sin(math.pi * min(1.0, height) * .76)
    brow += .014 * front ** 6 * math.exp(-((z - 1.785) / .062) ** 2)
    brow *= min(1.0, rx / .06)
    x = (rx + fold - inset) * math.sin(angle)
    x -= .008 * max(0.0, height) ** 3
    y = cy + (ry + fold - inset) * math.cos(angle) - brow
    # Gently descending back crown and an offset tip suggest soft cloth weight.
    z += .0035 * math.sin(angle * 2 + .35) * math.sin(math.pi * height)
    z -= .005 * (1 - front) * math.exp(-((height - .9) / .17) ** 2)
    # Let the spare cloth fall a little behind/right of the crown. The front
    # opening is unaffected, and the back remains outside the underlying skull.
    back = max(0.0, math.cos(angle))
    slouch = math.exp(-((height - .87) / .145) ** 2)
    y += .010 * back ** 3 * slouch
    x += .006 * back ** 2 * slouch
    z -= .009 * back ** 2 * slouch * (.8 + .2 * math.sin(angle))
    return Vector((x, y, z))


def refine(scene, rig):
    """Replace v3's open, panelled helmet shell with one skinned cloth hood."""
    old = [o for o in scene.objects if o.type == 'MESH'
           and o.name.startswith(_OLD_HOOD_PREFIXES)]
    if not old:
        raise RuntimeError('Expected retained v3 hood components were not found')
    outer_material = bpy.data.materials.get('Eave V3 | tailored indigo linen')
    inner_material = bpy.data.materials.get('Eave V3 | folded navy lining')
    if not outer_material or not inner_material:
        raise RuntimeError('Expected retained indigo cloth and navy lining')
    old_faces = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in old)
    head = rig.data.bones['head'].head_local
    offset = Vector((head.x, head.y, head.z - 1.61))
    nx, ny = 64, 40
    count = (nx + 1) * (ny + 1)
    verts = []
    uv = []
    for inset in (0.0, .005):
        for j in range(ny + 1):
            for i in range(nx + 1):
                verts.append(_surface(j / ny, i / nx, inset) + offset)
                uv.append((i / nx * 1.25, j / ny * 1.45))
    faces = []
    mats = []
    for inside in (False, True):
        start = count if inside else 0
        for j in range(ny):
            for i in range(nx):
                q = start + j * (nx + 1) + i
                face = (q, q + 1, q + nx + 2, q + nx + 1)
                faces.append(tuple(reversed(face)) if inside else face)
                mats.append(1 if inside else 0)
    # Turn the opening and hem into actual cloth thickness rather than floating
    # rolled tubes. The rear crown seam closes through geometric welding below.
    boundary = list(range(nx + 1))
    boundary += [j * (nx + 1) + nx for j in range(1, ny + 1)]
    boundary += [ny * (nx + 1) + i for i in range(nx - 1, -1, -1)]
    boundary += [j * (nx + 1) for j in range(ny - 1, 0, -1)]
    rim_faces = [(a, b, b + count, a + count)
                 for a, b in zip(boundary, boundary[1:] + boundary[:1])]
    def rim_key(face):
        return tuple(sorted(tuple(round(float(c), 6) for c in verts[i])
                            for i in face))
    rim_counts = Counter(rim_key(face) for face in rim_faces)
    for face in rim_faces:
        # Above the brow the left/right boundary coincides: those two walls
        # would be duplicate internal sheets after welding, so omit both.
        if rim_counts[rim_key(face)] != 1:
            continue
        faces.append(face)
        mats.append(1)
    mesh = bpy.data.meshes.new('V4 draped hood continuous cloth topology')
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(outer_material)
    mesh.materials.append(inner_material)
    mesh.update()
    tex = mesh.uv_layers.new(name='UVMap')
    for polygon, material in zip(mesh.polygons, mats):
        polygon.use_smooth = True
        polygon.material_index = material
        for loop_index in polygon.loop_indices:
            tex.data[loop_index].uv = uv[mesh.loops[loop_index].vertex_index]
    hood = bpy.data.objects.new('V4 continuous draped indigo hood with lined brow', mesh)
    scene.collection.objects.link(hood)
    group = hood.vertex_groups.new(name='head')
    group.add(list(range(len(mesh.vertices))), 1.0, 'REPLACE')
    hood.parent = rig
    armature = hood.modifiers.new('Retained head deformation', 'ARMATURE')
    armature.object = rig
    # Closed crown rows contain duplicate endpoints once the face opening ends.
    # Weld before recomputing normals so no six-panel lighting seams remain.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.000001)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    non_manifold_edges = sum(not edge.is_manifold for edge in bm.edges)
    if non_manifold_edges:
        bad = [(tuple(edge.verts[0].co), tuple(edge.verts[1].co), len(edge.link_faces))
               for edge in bm.edges if not edge.is_manifold]
        raise RuntimeError('New hood has %d non-manifold edges: %r' % (non_manifold_edges, bad))
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    hood['art_component'] = 'crafted garment'
    hood['candidate_refinement'] = 'Continuous lined cloth, overhanging brow, covered skull and broad gathers'
    removed_names = [o.name for o in old]
    for obj in old:
        bpy.data.objects.remove(obj, do_unlink=True)
    # Existing short fastening cords belong inside the hood, not poking out
    # sideways as bright twig ends. Preserve their skinning while tucking them.
    for obj in scene.objects:
        if obj.type == 'MESH' and obj.name.startswith('Ceramic side fastening cord'):
            for vertex in obj.data.vertices:
                vertex.co.x *= .93
                vertex.co.y += .012
            obj.data.update()
    return {
        'removed_hood_components': removed_names,
        'old_hood_triangles': old_faces,
        'new_hood_triangles': sum(len(p.vertices) - 2 for p in mesh.polygons),
        'mask_geometry_changed': False,
        'side_fastening_cords_tucked': True,
        'non_manifold_edges': non_manifold_edges,
        'skin_bone': 'head',
        'notes': 'Removes exposed skull at back and disconnected fine trim; preserves all rig actions and ceramic details',
    }
