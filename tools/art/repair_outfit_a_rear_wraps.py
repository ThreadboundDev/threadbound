"""Restore the overlapping rear leather wraps on the Outfit A fitting mesh."""
import bpy
import bmesh
import math
from statistics import median
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

outfit = bpy.data.objects["A - Original pieces, unified outfit"]
assert not outfit.get("rear_leather_wraps_v1")
rig = outfit.find_armature()
assert rig.animation_data.action.name == "Fit | T-pose, seated wrists"
mesh = outfit.data
tree = BVHTree.FromObject(outfit, bpy.context.evaluated_depsgraph_get())
bm = bmesh.new()
bm.from_mesh(mesh)
weights = bm.verts.layers.deform.verify()
uv_layers = list(bm.loops.layers.uv.values())
material = next(i for i, m in enumerate(mesh.materials) if any(
    n.type == "TEX_IMAGE" and n.image and n.image.name.lower() == "base_chest_3d_basecolor"
    for n in m.node_tree.nodes))

def depth(x, z):
    hits = []
    for dx in (-.005, 0, .005):
        for dz in (-.005, 0, .005):
            p = tree.ray_cast(Vector((x+dx, 1, z+dz)), Vector((0,-1,0)))[0]
            if p:
                hits.append(p.y)
    return median(sorted(hits)[:6])

# Shallow rolled edges let the surviving crossing strap sit above the repair.
for band in range(4):
    cols = []
    for col in range(51):
        t = col/50
        x = -.139 + .286*t
        curve = .036*(x/.15)**2 - .009*x/.15
        low = 1.100 + curve + .028*band + .005*math.sin(4*t+band) + .006*(t-.5)*(band-1)
        row = []
        for s, relief in [(0,-.002),(.08,.001),(.45,.0015),(.91,.002),(1,0)]:
            z = low+(.043 if band==2 else .032)*s
            fade = max(0,1-min(t,1-t)/.16)
            y = .144 - .35*(z-1.1) - 1.85*x*x - .035*x + relief - .031*fade
            if band == 3:
                # Follow the diagonal keeper from the loose tail into the pouch.
                # Its lift across the hip distinguishes it from the horizontal turns.
                x = -.119 + .245*t
                low = 1.079 + .103*(1-t)**1.45 + .004*math.sin(6*t)
                z = low + .022*s
                y = max(.150 - .35*(z-1.1) - 1.85*x*x - .035*x, depth(x,z)+.003) + relief - .025*fade
            # Bind to the same waist bones as the adjacent leather, and
            # transform the fitted sample back into the mesh's rest space.
            hit = tree.ray_cast(Vector((x,1,z)),Vector((0,-1,0)))
            poly = mesh.polygons[hit[2]]
            influence = {}
            for i in poly.vertices:
                for w in mesh.vertices[i].groups:
                    influence[w.group] = influence.get(w.group,0)+w.weight/len(poly.vertices)
            transform = Matrix([[0]*4 for _ in range(4)])
            for idx, weight in influence.items():
                bone = rig.pose.bones[outfit.vertex_groups[idx].name]
                transform += (bone.matrix @ bone.bone.matrix_local.inverted())*weight
            v = bm.verts.new(transform.inverted_safe() @ Vector((x,y,z)))
            for idx, weight in influence.items():
                v[weights][idx] = weight
            row.append(v)
        if cols:
            for j in range(4):
                f = bm.faces.new((cols[-1][j],cols[-1][j+1],row[j+1],row[j]))
                f.material_index = material
                f.smooth = True
                for layer in uv_layers:
                    for loop, c, h in zip(f.loops,(col-1,col-1,col,col),(j,j+1,j+1,j)):
                        # Intact brown leather from the original tunic atlas.
                        loop[layer].uv = ((249+18*(1-abs((c+band*6)%32-16)/16))/840,1-(776+12*h/4)/840)
        cols.append(row)
bm.to_mesh(mesh)
bm.free()
mesh.update()
outfit["rear_leather_wraps_v1"] = True
