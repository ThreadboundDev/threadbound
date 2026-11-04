"""Author the shared fitted mask and two finishes without changing runtime assets.

Blender --background --factory-startup --python-exit-code 1 --python <this file>
Optional arguments after --: --no-render (build/export only).
All generated character art stays under LocalOnly/Equipment/Masks.
"""

import bpy
import bmesh
import hashlib
import json
import math
import sys
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import closest_point_on_tri

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "LocalOnly/Equipment/Masks"
SOURCE = ROOT / "LocalOnly/Equipment/BaseBlue/BaseBlue_Fitted.blend"
OUT.mkdir(parents=True, exist_ok=True)
(OUT / ".gdignore").touch()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
rig = bpy.data.objects["Threadborne_Rig"]
rig.animation_data_clear()
rig.data.pose_position = "REST"
references = [o for o in scene.objects if o.type == "MESH"]
for obj in references:
    obj.hide_set(False)
    obj.hide_render = True
    obj.hide_select = True
reference_collection = bpy.data.collections.new("00 • Fitting references — original geometry")
scene.collection.children.link(reference_collection)
for obj in references + [rig]:
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    reference_collection.objects.link(obj)


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


master_collection = collection("01 • MASTER — shared shell mesh")
finish_collections = {key: collection(f"02 • {key} finish") for key in ("Loomed", "Hermit")}
stitch_collection = collection("03 • Fitted embroidery studies")
swatch_collection = collection("04 • Repeatable embroidery strips")
created = []


def move(obj, dest):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    dest.objects.link(obj)
    created.append(obj)
    return obj


def material(name, color, metallic=0, roughness=.4):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


ivory = material("Warm satin porcelain", (.72, .63, .47), roughness=.31)
gold = material("Repair • warm gold", (.64, .36, .095), .78, .28)
black = material("Eye paint • charcoal black", (.0015, .002, .0025), roughness=.93)
black.node_tree.nodes["Principled BSDF"].inputs["Specular IOR Level"].default_value = .05
ink = material("Hermit • slate indigo brush glaze", (.025, .045, .072), roughness=.4)
umber = material("Loomed • warm umber knot", (.105, .052, .018), roughness=.48)
cream_thread = material("Embroidery • flax thread", (.64, .53, .34), roughness=.84)
gold_thread = material("Embroidery • ochre thread", (.43, .25, .065), roughness=.85)
blue_thread = material("Embroidery • blue thread", (.14, .25, .34), roughness=.88)
brown_cloth = material("Swatch • charcoal brown cloth", (.049, .032, .023), roughness=.98)
blue_cloth = material("Swatch • deep indigo cloth", (.018, .032, .055), roughness=.98)

# The editable source retains a subtle glaze; this is baked for the GLBs below.
nodes = ivory.node_tree.nodes
links = ivory.node_tree.links
tex = nodes.new("ShaderNodeTexNoise")
tex.inputs["Scale"].default_value = 145
tex.inputs["Detail"].default_value = 3
ramp = nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = .18
ramp.color_ramp.elements[0].color = (.60, .51, .37, 1)
ramp.color_ramp.elements[1].position = .82
ramp.color_ramp.elements[1].color = (.80, .72, .57, 1)
links.new(tex.outputs["Fac"], ramp.inputs[0])
links.new(ramp.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])

ZC = 1.757
HEIGHT = .110
WIDTH = .100


def depth(x, z):
    """Smooth front envelope of the doll and both fitted donor heads, in metres."""
    chin_clearance = .007 * max(0, min(1, (1.690-z)/.043)) ** 2
    return -.146 + .044 * (x / WIDTH) ** 2 + .024 * ((z - 1.766) / .111) ** 4 - chin_clearance


def face_point(x, z, lift=0):
    return (x, depth(x, z) - lift, z)


def mesh_object(name, vertices, faces, mat, dest):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    dest.objects.link(obj)
    created.append(obj)
    if mat:
        mesh.materials.append(mat)
    return obj


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def bind(obj, bone="head"):
    group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1, "REPLACE")
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    mod = obj.modifiers.new("Shared doll skeleton", "ARMATURE")
    mod.object = rig


def normals(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    for face in obj.data.polygons:
        face.use_smooth = True


# A shallow oval disk with a tapered chin, solidified before the two real eye cuts.
verts = [face_point(0, ZC)]
faces = []
RINGS, STEPS = 32, 128
for ring in range(1, RINGS + 1):
    r = ring / RINGS
    for i in range(STEPS):
        a = math.tau * i / STEPS
        x = WIDTH * r * math.sin(a) * (1 + .15 * r * math.cos(a))
        z = ZC + HEIGHT * r * math.cos(a)
        verts.append(face_point(x, z))
        j = 1 + (ring - 1) * STEPS + i
        k = 1 + (ring - 1) * STEPS + (i + 1) % STEPS
        faces.append((0, j, k) if ring == 1 else (j-STEPS, j, k, k-STEPS))
shell = mesh_object("MASTER_Shell", verts, faces, ivory, master_collection)
normals(shell)
activate(shell)
solid = shell.modifiers.new("Porcelain thickness • 2.4 mm", "SOLIDIFY")
solid.thickness = .0024
solid.offset = -1
bpy.ops.object.modifier_apply(modifier=solid.name)


def almond(side, scale=1):
    points = []
    for i in range(96):
        a = math.tau * i / 96
        u = math.cos(a)
        x = .049 + .032 * u * scale
        z = 1.756 + .014 * u * scale + .0095 * math.sin(a) * abs(math.sin(a)) ** .45 * scale
        points.append((side*x, z))
    return points


for side in (-1, 1):
    outline = almond(side)
    cut_verts = [(x, y, z) for y in (-.30, .05) for x, z in outline]
    n = len(outline)
    cut_faces = [tuple(range(n-1, -1, -1)), tuple(range(n, 2*n))]
    cut_faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
    cutter = mesh_object("temporary eye cutter", cut_verts, cut_faces, None, master_collection)
    normals(cutter)
    activate(shell)
    mod = shell.modifiers.new("Almond eye opening", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.object = cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    created.remove(cutter)
    bpy.data.objects.remove(cutter, do_unlink=True)
normals(shell)
custom_normals = []
for poly in shell.data.polygons:
    for li in poly.loop_indices:
        p=shell.data.vertices[shell.data.loops[li].vertex_index].co
        if abs(poly.normal.y)>.4:
            step=.00001
            dx=(depth(p.x+step,p.z)-depth(p.x-step,p.z))/(2*step)
            dz=(depth(p.x,p.z+step)-depth(p.x,p.z-step))/(2*step)
            normal=Vector((dx,-1,dz)).normalized()
            if poly.normal.y>0:
                normal=-normal
            custom_normals.append(normal)
        else:
            custom_normals.append(poly.normal)
# Boolean eye cuts leave long, thin triangles. Analytic shell normals preserve
# the intended smooth glaze instead of triangular highlights around the eyes.
shell.data.normals_split_custom_set(custom_normals)
uv = shell.data.uv_layers.new(name="Mask planar finish")
for poly in shell.data.polygons:
    for li in poly.loop_indices:
        p = shell.data.vertices[shell.data.loops[li].vertex_index].co
        u,v = (p.x + .115) / .230, (p.z - 1.635) / .245
        # Rear and cut-wall UVs occupy unused corners instead of overwriting the
        # front during pigment baking. The front remains a paint-friendly map.
        if poly.normal.y > .4:
            u,v = .006+u*.025,.006+v*.025
        elif poly.normal.y >= -.4:
            u,v = .964+u*.025,.006+v*.025
        uv.data[li].uv = (u,v)
shell["purpose"] = "One source mesh; Loomed and Hermit use linked mesh data. Dimensions in metres."
shell["thickness_m"] = .0024
bind(shell)
shell.hide_render = True
shell.hide_set(True)


def sampled(points, resolution=12, closed=False):
    """Catmull-Rom interpolation keeps all decoration paths editable in this source."""
    pts = [Vector(p) for p in points]
    padded = ([pts[-1]] + pts + pts[:2]) if closed else ([pts[0]] + pts + [pts[-1]])
    result = []
    for i in range(len(pts) if closed else len(pts)-1):
        a, b, c, d = padded[i:i+4]
        for k in range(resolution):
            t = k/resolution
            result.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    if not closed:
        result.append(pts[-1])
    return result


def tube(name, points, radius, mat, dest, closed=False, bone="head"):
    points = [Vector(p) for p in points]
    vertices, faces = [], []
    sides = 8
    for i,p in enumerate(points):
        before = points[(i-1)%len(points)] if closed else points[max(0,i-1)]
        after = points[(i+1)%len(points)] if closed else points[min(len(points)-1,i+1)]
        tangent = (after-before).normalized()
        a = tangent.cross(Vector((0,1,0))).normalized()
        b = tangent.cross(a).normalized()
        for j in range(sides):
            angle = math.tau*j/sides
            vertices.append(p+radius*(math.cos(angle)*a+math.sin(angle)*b))
    for i in range(len(points) if closed else len(points)-1):
        for j in range(sides):
            n=(i+1)%len(points)
            faces.append((i*sides+j,i*sides+(j+1)%sides,n*sides+(j+1)%sides,n*sides+j))
    if not closed:
        faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(points)-1)*sides+j for j in range(sides))])
    obj = mesh_object(name,vertices,faces,mat,dest)
    for face in obj.data.polygons:
        face.use_smooth=True
    if bone:
        bind(obj, bone)
    return obj


def face_line(name, points, radius, mat, dest, closed=False, smooth=True):
    pts = sampled(points, 8, closed) if smooth else [Vector(p) for p in points]
    return tube(name, [face_point(p.x, p.y, .0008) for p in pts], radius, mat, dest, closed)


def brush(name, points, width, mat, dest):
    pts = sampled(points, 12)
    vertices = []
    across = 8
    for i, p in enumerate(pts):
        direction = (pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)]).normalized()
        normal = Vector((-direction.y, direction.x))
        taper = max(.05, math.sin(math.pi * i/(len(pts)-1))**.55)
        for j in range(across+1):
            side = 2*j/across-1
            x,z = p + normal * side * width * taper / 2
            vertices.append(face_point(x,z,.0014 if mat==black else .00065))
    faces = []
    for i in range(len(pts)-1):
        for j in range(across):
            a=i*(across+1)+j
            faces.append((a,a+1,a+across+2,a+across+1))
    obj = mesh_object(name, vertices, faces,mat,dest)
    bind(obj)
    return obj


finish_objects = {}
for key, dest in finish_collections.items():
    start = len(created)
    obj = bpy.data.objects.new(key+"_Shell", shell.data)
    dest.objects.link(obj)
    created.append(obj)
    bind(obj)
    for side in (-1,1):
        outline = almond(side)
        # A recessed black backing keeps the donor's ivory face out of the eye cut.
        liner_verts = [face_point(side*.049,1.756,-.0010)]
        liner_faces = []
        for ring in range(1,9):
            for i,(x,z) in enumerate(almond(side,1.08*ring/8)):
                liner_verts.append(face_point(x,z,-.0010))
                j=1+(ring-1)*96+i
                k=1+(ring-1)*96+(i+1)%96
                liner_faces.append((0,j,k) if ring==1 else (j-96,j,k,k-96))
        liner = mesh_object(key+"_Eye_Recess",liner_verts,liner_faces,black,dest)
        normals(liner)
        bind(liner)
        face_line(key+"_Eye_Gold_Lip", outline, .00065, gold, dest, True, False)
        if key == "Loomed":
            brush(key+"_Black_Eye_Wing", [(side*.015,1.743),(side*.053,1.750),(side*.088,1.777)], .009,black,dest)
            brush(key+"_Black_Tear", [(side*.025,1.744),(side*.032,1.727),(side*.030,1.717)], .005,black,dest)
        else:
            brush(key+"_Black_Eye_Sweep", [(side*.013,1.741),(side*.049,1.743),(side*.082,1.765),(side*.091,1.779)], .010,black,dest)
    if key == "Loomed":
        repair = [(.0443,1.8583),(.041,1.836),(.044,1.827),(.033,1.808),(.030,1.797),(.016,1.779),
                  (.010,1.766),(-.004,1.751),(-.009,1.740),(-.028,1.724),(-.041,1.717),(-.0705,1.6879)]
        face_line("Loomed_Long_Diagonal_Repair",repair,.0010,gold,dest,smooth=False)
        face_line("Loomed_Repair_Fork",[(-.009,1.740),(.008,1.733),(.021,1.735),(.039,1.723)],.00055,gold,dest,smooth=False)
        knot_ring=[(.015*math.cos(math.tau*i/128),1.821+.016*math.sin(math.tau*i/128)) for i in range(128)]
        knot_weave=[(.023*math.sin(math.tau*i/128),1.821+.011*math.sin(2*math.tau*i/128)) for i in range(128)]
        face_line("Loomed_Brow_Knot_Ring",knot_ring,.00095,umber,dest,True,False)
        face_line("Loomed_Brow_Knot_Weave",knot_weave,.00085,gold,dest,True,False)
    else:
        brush("Hermit_Main_Wave",[(-.026,1.675),(-.034,1.701),(-.068,1.739),(-.075,1.784),(-.054,1.822),(-.017,1.835),(.012,1.819),(.004,1.803),(-.008,1.808)],.018,ink,dest)
        brush("Hermit_Wave_Echo",[(-.022,1.677),(-.022,1.707),(-.054,1.745),(-.060,1.788),(-.035,1.817)],.0045,ink,dest)
        brush("Hermit_Lower_Wave",[(.010,1.668),(.028,1.690),(.044,1.714),(.065,1.720)],.010,ink,dest)
        repair = [(.0911,1.724),(.072,1.718),(.065,1.710),(.063,1.701),(.049,1.690),(.039,1.679),(.0349,1.6565)]
        face_line("Hermit_Local_Cheek_Repair",repair,.00095,gold,dest,smooth=False)
        face_line("Hermit_Shard_Fork",[(.039,1.679),(.046,1.675),(.048,1.670)],.00055,gold,dest,smooth=False)
    finish_objects[key] = created[start:]


def surface_tree(obj):
    return BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],
                               [list(p.vertices) for p in obj.data.polygons])


trees = {name:surface_tree(bpy.data.objects[name]) for name in ("Threadborne_Doll","base_HeadChest","blue_HeadChest")}


def inherit_cloth_weights(obj, source, tree):
    """Interpolate the actual donor cloth skin, including its hanging-sash hints."""
    source.data.calc_loop_triangles()
    by_polygon = {}
    for triangle in source.data.loop_triangles:
        by_polygon.setdefault(triangle.polygon_index, []).append(triangle)
    obj.vertex_groups.clear()
    for vertex in obj.data.vertices:
        hit,_,index,_ = tree.find_nearest(vertex.co)
        best = None
        for triangle in by_polygon[index]:
            coords = [source.matrix_world@source.data.vertices[i].co for i in triangle.vertices]
            projected = closest_point_on_tri(hit,*coords)
            distance = (projected-hit).length
            if best is None or distance < best[0]:
                best = (distance,triangle,coords,projected)
        _,triangle,(a,b,c),point = best
        ab,ac,ap = b-a,c-a,point-a
        d00,d01,d11 = ab.dot(ab),ab.dot(ac),ac.dot(ac)
        denom = d00*d11-d01*d01
        if abs(denom) < 1e-16:
            factors = (1,0,0)
        else:
            v=(d11*ap.dot(ab)-d01*ap.dot(ac))/denom
            w=(d00*ap.dot(ac)-d01*ap.dot(ab))/denom
            factors = (1-v-w,v,w)
        weights = {}
        for vi,factor in zip(triangle.vertices,factors):
            for group in source.data.vertices[vi].groups:
                name=source.vertex_groups[group.group].name
                if name in rig.data.bones:
                    weights[name]=weights.get(name,0)+max(0,factor)*group.weight
        weights=dict(sorted(weights.items(),key=lambda item:item[1],reverse=True)[:4])
        total=sum(weights.values())
        if total <= 0:
            raise RuntimeError("Cloth sample has no skin weights")
        for name,weight in weights.items():
            if weight > 1e-7:
                group=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                group.add([vertex.index],weight/total,"REPLACE")


def pattern_paths(key):
    """Periodic paths in a unit repeat. Endpoints and slopes tile continuously."""
    paths = []
    if key == "Loomed":
        for offset in (0, math.pi):
            paths.append(([(i/128,.5+.29*math.sin(math.tau*i/128+offset)) for i in range(129)],gold_thread))
        paths.append(([(.5+.29*math.cos(math.tau*i/128),.5+.39*math.sin(math.tau*i/128)) for i in range(129)],cream_thread))
    else:
        for v,mat in ((.39,blue_thread),(.66,cream_thread)):
            paths.append(([(i/128,v+.14*math.sin(math.tau*i/128)) for i in range(129)],mat))
        # The small inward curl is the crest of each broad repeating wave.
        paths.append(([(.38,.77),(.53,.85),(.67,.83),(.73,.74),(.69,.67),(.61,.69)],cream_thread))
    return paths


embroidery_objects = {}
for key, gear in (("Loomed","base"),("Hermit","blue")):
    objects = []
    tree = trees[gear+"_HeadChest"]
    def fitted(u,v):
        # Base waist wrap; Hermit front sash. Neither touches leather fasteners.
        if gear == "base":
            x,z = -.108 + u*.216, 1.055 + v*.042
        else:
            x,z = -.022 + v*.042, .810 + u*.180
        hit = tree.ray_cast(Vector((x,-.7,z)),Vector((0,1,0)))[0]
        if hit is None:
            raise RuntimeError(f"Embroidery misses {gear} cloth at {x}, {z}")
        return (x,hit.y-.0016,z)
    for repeat in range(3):
        for pi,(path,mat) in enumerate(pattern_paths(key)):
            coords = sampled(path,6) if len(path)<20 else [Vector(p) for p in path]
            points = [fitted((repeat+p.x)/3,p.y) for p in coords]
            objects.append(tube(f"{key}_Fitted_Repeat_{repeat}_{pi}",points,.0011,mat,stitch_collection,bone="pelvis"))
            inherit_cloth_weights(objects[-1],bpy.data.objects[gear+"_HeadChest"],tree)
    embroidery_objects[key] = objects

# Independent flat source strips render to orthographic texture maps. Fine cross
# stitches and a woven bump distinguish thread from the mask's glaze and metal.
swatches = {}
for key, cloth in (("Loomed",brown_cloth),("Hermit",blue_cloth)):
    start = len(created)
    mesh_object(key+"_Swatch_Cloth",[(-.30,0,-.05),(.30,0,-.05),(.30,0,.05),(-.30,0,.05)],[(0,1,2,3)],cloth,swatch_collection)
    for repeat in range(3):
        for pi,(path,mat) in enumerate(pattern_paths(key)):
            coords = sampled(path,6) if len(path)<20 else [Vector(p) for p in path]
            pts = [(-.30+(repeat+p.x)*.20,-.0016, -.043+p.y*.086) for p in coords]
            tube(f"{key}_Strip_Thread_{repeat}_{pi}",pts,.0015,mat,swatch_collection,bone=None)
            for i in range(3,len(pts)-3,5):
                p=Vector(pts[i]);t=(Vector(pts[i+1])-Vector(pts[i-1])).normalized()
                normal=Vector((-t.z,0,t.x))*.0016
                tube(f"{key}_Thread_Twist",[p-normal+Vector((0,-.0008,0)),p+normal+Vector((0,-.0008,0))],.00030,cream_thread,swatch_collection,bone=None)
    for z in (-.046,.046):
        for i in range(120):
            x=-.3+i*.005
            tube(key+"_Edge_Stitch",[(x,-.001,z-.001),(x+.0025,-.001,z+.001)],.00055,cream_thread,swatch_collection,bone=None)
    swatches[key]=created[start:]


shell_tree = surface_tree(shell)
report = {"source_sha256":hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
          "source":str(SOURCE.relative_to(ROOT)),"thickness_m":.0024,
          "shared_mesh":finish_objects["Loomed"][0].data is finish_objects["Hermit"][0].data,
          "rest_fit":{},"notes":["Review delivery; no runtime integration or passive effects.",
                                  "Source outfits retain their original geometry.",
                                  "Eye openings have recessed black liners over the faceless doll."]}
for name,tree in trees.items():
    overlap=shell_tree.overlap(tree)
    distances=[tree.find_nearest(v.co)[3] for v in shell.data.vertices]
    report["rest_fit"][name]={"intersecting_triangle_pairs":len(overlap),"minimum_clearance_m":min(distances)}
report["shell_vertices"]=len(shell.data.vertices)
shell.data.calc_loop_triangles()
report["shell_triangles"]=len(shell.data.loop_triangles)

# Bake the glaze's base color once, keeping one UV layout and material for all
# linked finishes. Raised repair/paint geometry exports with its own material.
activate(shell)
shell.hide_render=False
scene.render.engine="CYCLES"
scene.cycles.samples=8
image=bpy.data.images.new("Shared porcelain glaze • 1024",width=1024,height=1024)
image.filepath_raw=str(OUT/"porcelain_basecolor.png")
image.file_format="PNG"
target=nodes.new("ShaderNodeTexImage")
target.image=image
nodes.active=target
scene.render.bake.use_pass_direct=False
scene.render.bake.use_pass_indirect=False
scene.render.bake.use_pass_color=True
bpy.ops.object.bake(type="DIFFUSE")
image.save()
links.new(target.outputs["Color"],nodes["Principled BSDF"].inputs["Base Color"])
image.pack()

# Bake only the painted pigment onto linked shell instances. This clips the
# brushwork at the real eye openings and avoids floating decals in the exports.
pigment_sources = {}


def project_pigments(image, pigments):
    """Rasterize editable pigment geometry in UV space without normal-ray skew.

    Ray cages around boolean eye cuts can pull neighboring pigment into streaks.
    The front UV map is orthographic, so exact triangle coverage is preferable.
    """
    size=2048
    base=np.empty(1024*1024*4,dtype=np.float32)
    image.pixels.foreach_get(base)
    rgba=np.repeat(np.repeat(base.reshape((1024,1024,4)),2,axis=0),2,axis=1)
    depth_buffer=np.full((size,size),np.inf,dtype=np.float32)
    for obj in pigments:
        obj.data.calc_loop_triangles()
        color=np.array(obj.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value,dtype=np.float32)
        for tri in obj.data.loop_triangles:
            coords=[obj.matrix_world@obj.data.vertices[i].co for i in tri.vertices]
            uv=np.array([((p.x+.115)/.230*size,(p.z-1.635)/.245*size) for p in coords])
            low=np.maximum(0,np.floor(uv.min(axis=0)).astype(int))
            high=np.minimum(size-1,np.ceil(uv.max(axis=0)).astype(int))
            if np.any(high<low):
                continue
            a,b,c=uv
            denom=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
            if abs(denom)<1e-8:
                continue
            yy,xx=np.mgrid[low[1]:high[1]+1,low[0]:high[0]+1]
            xx=xx+.5;yy=yy+.5
            w0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/denom
            w1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/denom
            w2=1-w0-w1
            depths=w0*coords[0].y+w1*coords[1].y+w2*coords[2].y
            region=depth_buffer[low[1]:high[1]+1,low[0]:high[0]+1]
            mask=(w0>=-1e-6)&(w1>=-1e-6)&(w2>=-1e-6)&(depths<region)
            region[mask]=depths[mask]
            rgba[low[1]:high[1]+1,low[0]:high[0]+1][mask]=color
    return rgba


for key,objects in finish_objects.items():
    destination=objects[0]
    pigments=[o for o in objects if "_Black_" in o.name or o.name in
              ("Hermit_Main_Wave","Hermit_Wave_Echo","Hermit_Lower_Wave","Loomed_Brow_Knot_Ring")]
    pigment_sources[key]=pigments
    mat=ivory.copy()
    mat.name=key+" • baked porcelain and eye paint"
    mat.node_tree.nodes["Principled BSDF"].inputs["Specular IOR Level"].default_value=.18
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.42
    destination.material_slots[0].link="OBJECT"
    destination.material_slots[0].material=mat
    finish_image=bpy.data.images.new(key+" finish • 2048",width=2048,height=2048)
    finish_image.filepath_raw=str(OUT/(key.lower()+"_basecolor.png"))
    finish_image.file_format="PNG"
    bake_target=mat.node_tree.nodes.new("ShaderNodeTexImage")
    bake_target.image=finish_image
    mat.node_tree.nodes.active=bake_target
    finish_image.pixels.foreach_set(project_pigments(image,pigments).ravel())
    finish_image.save()
    mat.node_tree.links.new(bake_target.outputs["Color"],mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    finish_image.pack()
    finish_objects[key]=[o for o in objects if o not in pigments]
    for source in pigments:
        source["purpose"]="Editable pigment source, baked into this finish; hidden in final renders and exports."
scene.render.bake.use_selected_to_active=False


def export(key, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [rig]+objects:
        obj.hide_set(False)
        obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key.lower()+"_mask.glb")),export_format="GLB",
                             use_selection=True,export_animations=False,export_skins=True,
                             export_def_bones=False,export_cameras=False,export_lights=False)


for key,objects in finish_objects.items():
    export(key,objects)

scene.cycles.samples=32
scene.cycles.use_denoising=True
scene.render.film_transparent=False
scene.world.node_tree.nodes["Background"].inputs[0].default_value=(.115,.135,.16,1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value=.55
scene.view_settings.view_transform="AgX"
scene.view_settings.exposure=-.55
camera=scene.camera
camera.data.type="ORTHO"
for light in [o for o in scene.objects if o.type=="LIGHT"]:
    light.data.energy=65
    light.location=(-.5,-.8,2.2)
    light.data.size=1.1
fill=bpy.data.objects.new("Mask soft fill",bpy.data.lights.new("Mask soft fill","AREA"))
scene.collection.objects.link(fill)
fill.location=(.6,-.5,1.9)
fill.data.energy=25
fill.data.size=.8
fill.rotation_euler=(Vector((0,-.1,1.75))-fill.location).to_track_quat("-Z","Y").to_euler()


def show(objects):
    for obj in references+created:
        obj.hide_render=obj not in objects
        obj.hide_set(obj not in objects)


def render(name,objects,target,scale,direction=(0,-1,.015),size=(960,1100)):
    show(objects)
    target=Vector(target)
    camera.location=target+Vector(direction).normalized()*3
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.ortho_scale=scale
    scene.render.resolution_x,scene.render.resolution_y=size
    scene.render.resolution_percentage=100
    scene.render.filepath=str(OUT/(name+".png"))
    bpy.ops.render.render(write_still=True)


if "--no-render" not in sys.argv:
    for key,objects in finish_objects.items():
        render(key.lower()+"_front",objects,(0,-.1,1.757),.255)
        render(key.lower()+"_three_quarter",objects,(0,-.1,1.757),.265,(.55,-1,.03))
        for gear in ("base","blue"):
            head=bpy.data.objects[gear+"_HeadChest"]
            render(key.lower()+"_"+gear+"_fit",objects+[head],(0,-.045,1.735),.48,(.14,-1,.005))
        gear="base" if key=="Loomed" else "blue"
        outfit=[o for o in references if o.name.startswith((gear+"_",gear.title()+"_")) or o.name=="Shared_Wooden_Hands" or o.name==("Grapple_Needle_Base" if gear=="base" else "Grapple_Needle_BlueHook")]
        render(key.lower()+"_outfit",objects+outfit+embroidery_objects[key],(0,0,.99),2.17,(.18,-1,.025),(1100,1100))
        render(key.lower()+"_embroidery_fit",[bpy.data.objects[gear+"_HeadChest"]]+embroidery_objects[key],
               (0,-.1,1.075 if gear=="base" else .865),.35,(.08,-1,0),(1000,900))
        # Strip capture uses neutral world lighting with no directional lamps.
        lights=[o for o in scene.objects if o.type=="LIGHT"]
        for obj in lights:obj.hide_render=True
        scene.world.node_tree.nodes["Background"].inputs[0].default_value=(1,1,1,1)
        scene.world.node_tree.nodes["Background"].inputs[1].default_value=.8
        render(key.lower()+"_embroidery_repeat",swatches[key],(0,0,0),.6,(0,-1,0),(1800,300))
        for obj in lights:obj.hide_render=False
        scene.world.node_tree.nodes["Background"].inputs[0].default_value=(.115,.135,.16,1)
        scene.world.node_tree.nodes["Background"].inputs[1].default_value=.55

show(finish_objects["Loomed"]+[bpy.data.objects["base_HeadChest"]]+embroidery_objects["Loomed"])
camera.location=(.06,-1.5,1.76)
camera.rotation_euler=(Vector((0,-.05,1.74))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.ortho_scale=.48
scene.render.resolution_x=960
scene.render.resolution_y=1100
for area in bpy.context.screen.areas:
    if area.type=="VIEW_3D":
        area.spaces.active.region_3d.view_perspective="CAMERA"
        area.spaces.active.clip_end=100
for image in bpy.data.images:
    if image.source=="FILE" and not image.packed_file:
        image.pack()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"Threadborne_Master_Mask.blend"),compress=True)
(OUT/"fit_report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print("MASK_FIT_REPORT",json.dumps(report),flush=True)
