"""Build closed carved hand parts on the existing, unchanged animation pivots.

Blender --background --factory-startup --python-exit-code 1 --python this_file
-- --candidate keeps exports under LocalOnly until they pass close-up review.
The immutable pre-repair master supplies the rig, clips and wood texture.
"""
from pathlib import Path
import json
import math
import sys
import bpy
import bmesh
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT/'LocalOnly/Equipment/FeedbackReview2026_11_07'
SOURCE = REVIEW/'BeforeAssets/threadborne_doll_equipped.glb'
CANDIDATE = '--candidate' in sys.argv
DEST = ROOT/'LocalOnly/Equipment/SurfaceCleanup2026_11_07/Candidate'
DEST.mkdir(parents=True,exist_ok=True)
OUTPUT = (DEST/'threadborne_doll_equipped.glb' if CANDIDATE else
          ROOT/'Assets/Threadborne/Player/LocalDoll/threadborne_doll_equipped.glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
rig = next(obj for obj in bpy.context.scene.objects if obj.type=='ARMATURE')
body = bpy.data.objects['Threadborne_Doll']
rig.data.pose_position = 'REST'
for track in rig.animation_data.nla_tracks:
    track.mute = True
bpy.context.view_layer.update()
rest = {bone.name:bone.matrix_local.copy() for bone in rig.data.bones}
original_actions = {action.name:tuple(action.frame_range) for action in bpy.data.actions}
wood = body.data.materials[0].copy()
wood.name = 'Doll_Carved_Wood'
hinge = wood.copy()
hinge.name = 'Doll_Dark_Wood_Hinges'
bsdf = next(node for node in hinge.node_tree.nodes if node.type=='BSDF_PRINCIPLED')
socket = bsdf.inputs['Base Color']
source_socket = socket.links[0].from_socket
hinge.node_tree.links.remove(socket.links[0])
tint = hinge.node_tree.nodes.new('ShaderNodeMix')
tint.data_type = 'RGBA'
tint.blend_type = 'MULTIPLY'
tint.inputs[0].default_value = 1
tint.inputs[7].default_value = (.32,.20,.11,1)
hinge.node_tree.links.new(source_socket,tint.inputs[6])
hinge.node_tree.links.new(tint.outputs[2],socket)
bsdf.inputs['Roughness'].default_value = .65

# The reference is texture lookup only. It never supplies triangle partitions.
body.data.calc_loop_triangles()
reference_vertices = [v.co.copy() for v in body.data.vertices]
reference_triangles = [tri for tri in body.data.loop_triangles
    if all(abs(reference_vertices[i].x)>.67 and reference_vertices[i].z>1.35 for i in tri.vertices)]
tree = BVHTree.FromPolygons(reference_vertices,[tri.vertices[:] for tri in reference_triangles],all_triangles=True)
reference_uv = body.data.uv_layers.active.data
image=next(node.image for node in wood.node_tree.nodes if node.type=='TEX_IMAGE')
width,height=image.size
pixels=np.empty(width*height*4,dtype=np.float32); image.pixels.foreach_get(pixels)
pixels=pixels.reshape(height,width,4)
candidates=[]
for x in (.755,.775,.795,.810):
    for y in (.005,.025,.045):
        point,_,index,_=tree.find_nearest(Vector((x,y,1.54)))
        tri=reference_triangles[index]
        value=barycentric_transform(point,*[reference_vertices[i] for i in tri.vertices],
            *[Vector((*reference_uv[i].uv,0)) for i in tri.loops])
        candidates.append((int(value.x*width),int(value.y*height)))
verified_patch=None
for size in (48,32,16,8):
    for x,y in candidates:
        x=max(0,min(width-size,x-size//2)); y=max(0,min(height-size,y-size//2))
        sample=pixels[y:y+size,x:x+size,:3]
        warm=(sample[:,:,0]>sample[:,:,1]+.01)&(sample[:,:,1]>sample[:,:,2]+.005)&(sample[:,:,1]>.22)
        if warm.mean()>.99:
            verified_patch=(x/width,y/height,size/width,size/height)
            break
    if verified_patch: break
assert verified_patch,'No continuous warm wood patch found in the reference hand'
del pixels
parts = []
stats = []


def texture(obj,offset,stable_wood=False):
    """Map a continuous verified wood patch, excluding painted joint seams."""
    original=[v.uv.copy() for v in obj.data.uv_layers.active.data] if obj.data.uv_layers.active else None
    for layer in list(obj.data.uv_layers): obj.data.uv_layers.remove(layer)
    uv=obj.data.uv_layers.new(name=body.data.uv_layers.active.name).data
    low=Vector([min(v.co[i] for v in obj.data.vertices) for i in range(3)])
    high=Vector([max(v.co[i] for v in obj.data.vertices) for i in range(3)])
    px,py,du,dv=verified_patch
    for face in obj.data.polygons:
        axes=sorted(range(3),key=lambda axis:abs(face.normal[axis]))[:2]
        for index in face.loop_indices:
            point=obj.data.vertices[obj.data.loops[index].vertex_index].co
            value=original[index] if original else Vector(tuple(
                (point[axis]-low[axis])/max(.001,high[axis]-low[axis]) for axis in axes))
            scale=.05 if stable_wood else 1.0
            uv[index].uv=(px+du*(.5+(value.x-.5)*scale),py+dv*(.5+(value.y-.5)*scale))


def finish(obj,bone,material,offset):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    obj.data.materials.clear()
    obj.data.materials.append(material)
    texture(obj,offset,material==hinge)
    for face in obj.data.polygons:
        face.use_smooth = True
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    mod = obj.modifiers.new('Rigid carved articulation','ARMATURE')
    mod.object = rig
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(edge.is_manifold for edge in bm.edges),obj.name
    assert all(face.calc_area()>1e-12 for face in bm.faces),obj.name
    bm.free()
    parts.append(obj)
    stats.append({'part':obj.name,'bone':bone,'vertices':len(obj.data.vertices),
                  'closed':True,'texture_lookup_offset':list(offset)})
    obj.select_set(False)


def cylinder(name,a,b,radius,bone,material,offset,rounding=.003):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=radius,depth=(b-a).length,
                                      end_fill_type='NGON',location=(a+b)*.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    bevel = obj.modifiers.new('Carved round edges','BEVEL')
    bevel.width = rounding
    bevel.segments = 3
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    finish(obj,bone,material,offset)


def ball(name,center,radius,bone,offset):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=radius,location=center)
    obj = bpy.context.object
    obj.name = name
    finish(obj,bone,hinge,offset)


bpy.ops.object.select_all(action='DESELECT')
for side,sign in [('L',1),('R',-1)]:
    wrist = rig.data.bones['hand.'+side].head_local.copy()
    # A closed carved palm, with a shallow thumb notch and a sloped knuckle row.
    outline = [(.719,-.014),(.750,-.023),(.762,.003),(.785,.003),(.817,-.027),
               (.828,-.017),(.829,.027),(.819,.058),(.799,.079),(.756,.068),(.719,.020)]
    vertices = []
    for layer in (-1,1):
        for x,y in outline:
            center_z = wrist.z-.095*(x-.728)
            vertices.append((sign*x,y,center_z+layer*.014))
    count = len(outline)
    faces = [tuple(reversed(range(count))),tuple(range(count,2*count))]
    faces += [(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
    mesh = bpy.data.meshes.new('Closed palm')
    mesh.from_pydata(vertices,[],faces)
    obj = bpy.data.objects.new('Carved_Palm.'+side,mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bevel = obj.modifiers.new('Soft carved palm edges','BEVEL')
    bevel.width = .0035
    bevel.segments = 3
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    # Recalculate mirrored face orientation before material/rig binding.
    bm = bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data); bm.free()
    finish(obj,'hand.'+side,wood,Vector((0,0,.024)))
    ball('Carved_Wrist.'+side,wrist,.0265,'forearm.'+side,Vector((0,0,.019)))
    cylinder('Carved_WristSeat.'+side,wrist+Vector((-sign*.043,0,0)),
             wrist+Vector((sign*.008,0,0)),.0245,'forearm.'+side,hinge,Vector((sign*.025,0,.020)),.002)
    for digit,radius in [('index',.010),('middle',.0105),('ring',.0095),('pinky',.0085),('thumb',.0115)]:
        for segment in (1,2,3):
            bone = f'{digit}.{segment:02d}.{side}'
            anchor = rig.data.bones[bone].head_local.copy()
            successor = rig.data.bones.get(f'{digit}.{segment+1:02d}.{side}')
            end = successor.head_local.copy() if successor else anchor+(anchor-rig.data.bones[f'{digit}.02.{side}'].head_local)
            direction = (end-anchor).normalized()
            offset = Vector((0,0,.022 if segment==1 else (.014 if segment==2 else .005)))
            cylinder('Carved_'+bone,anchor+direction*.003,end-direction*.003,radius,
                     bone,wood,offset,min(.004,radius*.4))
            parent = 'hand.'+side if segment==1 else f'{digit}.{segment-1:02d}.{side}'
            ball('Carved_Hinge_'+bone,anchor,radius*1.08,parent,offset)

# Remove the old hand past a clean plane. Its remaining forearm end is hidden
# by the bracer; Shared_Wooden_Hands exports only the new, closed materials.
bm = bmesh.new(); bm.from_mesh(body.data)
for sign in (-1,1):
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,
                          plane_co=(sign*.668,0,0),plane_no=(1,0,0))
bmesh.ops.delete(bm,geom=[face for face in bm.faces if abs(face.calc_center_median().x)>.668
    and face.calc_center_median().z>1.35],context='FACES')
bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
bm.to_mesh(body.data); bm.free()
bpy.ops.object.select_all(action='DESELECT')
for obj in [body]+parts: obj.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
body.name = 'Threadborne_Doll'
assert len(rig.data.bones)==62
assert all(max(abs(rig.data.bones[name].matrix_local[i][j]-matrix[i][j])
    for i in range(4) for j in range(4))<1e-6 for name,matrix in rest.items())
assert {a.name:tuple(a.frame_range) for a in bpy.data.actions}==original_actions
for image in bpy.data.images:
    if image.source=='FILE' and not image.packed_file: image.pack()
bpy.context.preferences.filepaths.save_version = 0
blend = DEST/'Shared_Hands_Repair.blend' if CANDIDATE else REVIEW/'Shared_Hands_Repair.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(blend),compress=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.context.scene.objects:
    if obj.type!='MESH' or not obj.hide_render: obj.select_set(True)
bpy.context.view_layer.objects.active = rig
rig.data.pose_position = 'POSE'
bpy.ops.export_scene.gltf(filepath=str(OUTPUT),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,
    export_skins=True,export_def_bones=False,export_cameras=False,export_lights=False)
(DEST/'hand_repair_report.json').write_text(json.dumps({'parts':stats,'bones':62,'verified_wood_uv_patch':verified_patch,
    'actions':original_actions,'source':str(SOURCE)},indent=2),encoding='utf-8')
print('CLOSED_HANDS_REPAIRED',len(parts),'closed rigid pieces;',len(original_actions),'clips',flush=True)
