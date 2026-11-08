"""Validate closed articulated surfaces, UVs, rigid motion and hidden joins.

Blender background mode; -- --candidate validates local previews before install.
"""
from pathlib import Path
import json
import sys
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE = '--candidate' in sys.argv
SOURCE = (ROOT/'LocalOnly/Equipment/SurfaceCleanup2026_11_07/Candidate' if CANDIDATE
          else ROOT/'Assets/Threadborne/Player/LocalDoll')
FIT = SOURCE/'Equipment/FittedSets'
REPORT = SOURCE/'BaseBlue' if CANDIDATE else ROOT/'LocalOnly/Equipment/BaseBlue'
OUT = SOURCE if CANDIDATE else ROOT/'LocalOnly/Equipment/SurfaceCleanup2026_11_07'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(SOURCE/'threadborne_doll_equipped.glb'))
master = next(obj for obj in bpy.context.scene.objects if obj.type=='ARMATURE')
master.data.pose_position='REST'
actions = {name:bpy.data.actions[name] for name in
    ('idle_4','idle_2','run_1','casting_2','slash_2','jump_1','crouch_idle_1','grapple_swinging_1')}
checks=[]; details={}; seats={}
hand_report=json.loads((ROOT/'LocalOnly/Equipment/SurfaceCleanup2026_11_07/Candidate/hand_repair_report.json').read_text())
patch=hand_report['verified_wood_uv_patch']


def check(label,ok,value=None):
    checks.append({'name':label,'passed':bool(ok),'detail':value})
    assert ok,(label,value)


def rest_points(obj):
    return [(v,obj.matrix_world@v.co) for v in obj.data.vertices]


def owners(obj,vertex):
    return {obj.vertex_groups[g.group].name:g.weight for g in vertex.groups if g.weight>.00001}


def closed_components(obj):
    bm=bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    check(obj.name+' has no open or non-manifold hand edges',all(e.is_manifold for e in bm.edges))
    check(obj.name+' has no degenerate hand faces',all(f.calc_area()>1e-12 for f in bm.faces))
    unseen=set(bm.verts); components=[]; brown=0
    layer=bm.loops.layers.uv.active
    while unseen:
        first=unseen.pop(); group={first}; queue=[first]
        while queue:
            vertex=queue.pop()
            for edge in vertex.link_edges:
                other=edge.other_vert(vertex)
                if other in unseen:
                    unseen.remove(other); group.add(other); queue.append(other)
        components.append(group)
        faces={face for vertex in group for face in vertex.link_faces}
        if all(obj.data.materials[face.material_index].name.startswith('Doll_Dark_Wood_Hinges') for face in faces):
            brown+=1
            uv=[loop[layer].uv for face in faces for loop in face.loops]
            span=max(max(p[i] for p in uv)-min(p[i] for p in uv) for i in (0,1))
            check('Hinge uses a local wood patch, not whole-atlas UVs',span<=max(patch[2:])*.051+.000001,span)
    check(obj.name+' retains 66 individually closed pieces',len(components)==66,len(components))
    check(obj.name+' has all 34 brown hinge/seat components',brown==34,brown)
    check(obj.name+' maps every UV into the verified warm wood region',all(
        patch[0]-.000001<=uv.uv.x<=patch[0]+patch[2]+.000001 and
        patch[1]-.000001<=uv.uv.y<=patch[1]+patch[3]+.000001 for uv in obj.data.uv_layers.active.data))
    bm.free()


check('Original master skeleton has 62 bones',len(master.data.bones)==62)
check('All 48 authored clips retained',len(bpy.data.actions)==48)
for key in ('base','blue'):
    reference=json.loads((REPORT/(key+'_shin_source.json')).read_text())
    surface=BVHTree.FromPolygons(reference['vertices'],reference['triangles'],all_triangles=True)
    for slot in ('gloves','boots','head_chest'):
        before=set(bpy.context.scene.objects)
        bpy.ops.import_scene.gltf(filepath=str(FIT/(key+'_'+slot+'.glb')))
        imported=set(bpy.context.scene.objects)-before
        rig=next(obj for obj in imported if obj.type=='ARMATURE')
        rig.data.pose_position='REST'; bpy.context.view_layer.update()
        meshes=[obj for obj in imported if obj.type=='MESH' and obj.find_armature()==rig]
        check(key+' '+slot+' keeps the master rest bases',all(
            max(abs((rig.matrix_world@rig.data.bones[b.name].matrix_local)[i][j]
                    -(master.matrix_world@b.matrix_local)[i][j]) for i in range(4) for j in range(4))<.00001
            for b in master.data.bones))
        if slot=='gloves':
            obj=next(o for o in meshes if o.name.startswith('Shared_Wooden_Hands'))
            closed_components(obj)
            check(key+' hand vertices have one rigid owner',all(len(owners(obj,v))==1 and abs(sum(owners(obj,v).values())-1)<.00001 for v in obj.data.vertices))
            edges=[(a,b,(obj.data.vertices[a].co-obj.data.vertices[b].co).length) for a,b in (e.vertices for e in obj.data.edges)]
            check(key+' all edges stay inside rigid parts',all(owners(obj,obj.data.vertices[a])==owners(obj,obj.data.vertices[b]) for a,b,_ in edges))
            # Proximal cap vertices must remain enclosed by their parent hinge
            # through the authored animation, not only in the rest pose.
            cap_tests=[]
            for side in 'LR':
                wood={obj.data.loops[loop].vertex_index for face in obj.data.polygons
                      if obj.data.materials[face.material_index].name.startswith('Doll_Carved_Wood') for loop in face.loop_indices}
                palm=[v for v in obj.data.vertices if v.index in wood and 'hand.'+side in owners(obj,v)]
                start=min(abs(v.co.x) for v in palm)
                cap=[v.index for v in palm if abs(v.co.x)<start+.0001]
                cap_tests.append(('forearm.'+side,rig.data.bones['hand.'+side].head_local.copy(),.0265,cap))
                lining=next(o for o in meshes if o.name.startswith(key+'_WristCuffLining_'+side))
                ring=[p for _,p in rest_points(lining) if abs(abs(p.x)-.6948)<.00002 and
                      (p.y**2+(p.z-1.501)**2)**.5<.0243]
                error=max(abs((p.y**2+(p.z-1.501)**2)**.5-.0242) for p in ring)
                check(key+' concealed wrist socket '+side,len(ring)>16 and error<.00001,error)
                check(key+' wrist lining stays on forearm '+side,all(owners(lining,v)=={'forearm.'+side:1.0} for v in lining.data.vertices))
                for digit,radius in [('index',.010),('middle',.0105),('ring',.0095),('pinky',.0085),('thumb',.0115)]:
                    for segment in (1,2,3):
                        bone=f'{digit}.{segment:02d}.{side}'
                        anchor=rig.data.bones[bone].head_local
                        next_bone=rig.data.bones.get(f'{digit}.{segment+1:02d}.{side}')
                        end=next_bone.head_local if next_bone else anchor+(anchor-rig.data.bones[f'{digit}.02.{side}'].head_local)
                        direction=(end-anchor).normalized()
                        vertices=[v for v in obj.data.vertices if v.index in wood and bone in owners(obj,v)]
                        start=min((v.co-anchor).dot(direction) for v in vertices)
                        cap=[v.index for v in vertices if (v.co-anchor).dot(direction)<start+.0001]
                        parent='hand.'+side if segment==1 else f'{digit}.{segment-1:02d}.{side}'
                        cap_tests.append((parent,anchor.copy(),radius*1.08,cap))
            rig.data.pose_position='POSE'; rig.animation_data_create(); maximum=0; outside=0
            for action_name,action in actions.items():
                rig.animation_data.action=action; rig.animation_data.action_slot=action.slots[0]
                for fraction in (0,.35,.7,.95):
                    start,end=action.frame_range; frame=start+(end-start)*fraction
                    bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
                    evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get()); mesh=evaluated.to_mesh()
                    error=max(abs((mesh.vertices[a].co-mesh.vertices[b].co).length-length) for a,b,length in edges)
                    maximum=max(maximum,error)
                    check(key+' rigid articulation '+action_name+' '+str(fraction),error<.00002,error)
                    for parent,anchor,radius,cap in cap_tests:
                        center=rig.pose.bones[parent].matrix@rig.data.bones[parent].matrix_local.inverted()@anchor
                        outside=max(outside,max((mesh.vertices[index].co-center).length-radius for index in cap))
                    evaluated.to_mesh_clear()
            check(key+' wrist and proximal finger caps remain inside hinges',outside<.0005,outside)
            details[key+'_hands']={'rigid_edge_error_m':maximum,'maximum_cap_outside_hinge_m':outside,'closed_pieces':66}
        else:
            main=next(o for o in meshes if o.name.startswith(key+('_Boots' if slot=='boots' else '_HeadChest')))
            points=rest_points(main)
            sample=[p for _,p in points if .32<p.z<.50]
            error=max(surface.find_nearest(p)[3] for p in sample)
            surface_error=error
            check(key+' '+slot+' preserves the original visible shin contour',error<.00002,error)
            edge=max(p.z for _,p in points) if slot=='boots' else min(p.z for _,p in points)
            check(key+' '+slot+' retains mid-shin reach with natural garment overlap',
                  (.39<edge<.43) if slot=='boots' else (.35<edge<.435),edge)
            for side in 'LR':
                sign=1 if side=='L' else -1
                if slot=='boots':
                    obj=next(o for o in meshes if o.name.startswith(key+'_BootCuffLining_'+side))
                    ring=[p for _,p in rest_points(obj) if abs(p.z-.415)<.00002 and ((p.x-sign*.115)**2+(p.y-.020)**2)**.5<.025]
                    error=max(abs(((p.x-sign*.115)**2+(p.y-.020)**2)**.5-.0245) for p in ring)
                    check(key+' shared inner boot seat '+side,len(ring)>16 and error<.00001,error)
                    seats[key+side]=[.0245,min(p.z for _,p in rest_points(obj)),.415]
                else:
                    obj=next(o for o in meshes if o.name.startswith('Shared_Shin_Core_'+side))
                    core=rest_points(obj)
                    error=max(abs(((p.x-sign*.115)**2+(p.y-.020)**2)**.5-.0248) for _,p in core)
                    check(key+' closed hidden shin core '+side,error<.00001,error)
                    check(key+' core covers the whole lining '+side,min(p.z for _,p in core)<=.35501 and max(p.z for _,p in core)>.45)
                check(key+' connector follows only its shin '+side,all(owners(obj,v)=={'shin.'+side:1.0} for v in obj.data.vertices))
            details[key+'_'+slot]={'visible_surface_error_m':surface_error,'garment_edge_m':edge}
        for obj in imported: bpy.data.objects.remove(obj,do_unlink=True)
for side in 'LR':
    check('All mixed boot sets use identical internal seats '+side,seats['base'+side]==seats['blue'+side])
# Both cores and sleeves follow exactly the same shin transforms in all poses.
master.data.pose_position='POSE'
for action_name,action in actions.items():
    master.animation_data.action=action; master.animation_data.action_slot=action.slots[0]
    for fraction in (0,.35,.7,.95):
        start,end=action.frame_range; frame=start+(end-start)*fraction
        bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
        for side in 'LR':
            bone='shin.'+side; sign=1 if side=='L' else -1
            deform=master.matrix_world@master.pose.bones[bone].matrix@master.data.bones[bone].matrix_local.inverted()
            a=deform@Vector((sign*.115,.020,.355)); b=deform@Vector((sign*.115,.020,.415))
            check('Mixed internal overlap '+action_name+' '+str(fraction)+' '+side,abs((b-a).length-.060)<.00001)
result={'count':len(checks),'checks':checks,'details':details,'internal_overlap_m':.060}
(OUT/'joint_validation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('FITTED_SURFACES_VERIFIED',len(checks),json.dumps(details),flush=True)
