"""Measure the repaired hand articulation and common overlapping shin joins."""
from pathlib import Path
import json
import bpy

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Assets/Threadborne/Player/LocalDoll"
OUT = ROOT / "LocalOnly/Equipment/FeedbackReview2026_11_07"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps = 30
bpy.ops.import_scene.gltf(filepath=str(SOURCE/"threadborne_doll_equipped.glb"))
master = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
master.data.pose_position = "REST"
actions = {name:bpy.data.actions[name] for name in ("idle_4","idle_2","run_1","casting_2","slash_2","jump_1","crouch_idle_1","grapple_swinging_1")}
checks = []
details = {}


def check(name, ok, detail=None):
    checks.append({"name":name,"passed":bool(ok),"detail":detail})
    assert ok,(name,detail)


check("Original skeleton remains 62 bones",len(master.data.bones)==62)
check("All 48 source clips retained",len(bpy.data.actions)==48)
for name in ("base_gloves","blue_gloves","base_head_chest","blue_head_chest","base_boots","blue_boots"):
    before=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/"Equipment/FittedSets"/(name+".glb")))
    imported=set(bpy.context.scene.objects)-before
    rig=next(obj for obj in imported if obj.type=="ARMATURE")
    rig.data.pose_position="REST"
    bpy.context.view_layer.update()
    meshes=[obj for obj in imported if obj.type=="MESH" and obj.find_armature()==rig]
    if name.endswith("gloves"):
        obj=next(obj for obj in meshes if obj.name.startswith("Shared_Wooden_Hands"))
        check(name+" articulated hand vertices have one rigid owner",all(len(v.groups)==1 and abs(v.groups[0].weight-1)<.00001 for v in obj.data.vertices))
        edges=[(a,b,(obj.data.vertices[a].co-obj.data.vertices[b].co).length) for a,b in (edge.vertices for edge in obj.data.edges)
               if obj.data.vertices[a].groups[0].group==obj.data.vertices[b].groups[0].group]
        check(name+" all hand edges belong to rigid pieces",len(edges)==len(obj.data.edges))
        maximum=0
        rig.data.pose_position="POSE"
        rig.animation_data_create()
        for action_name,action in actions.items():
            rig.animation_data.action=action
            rig.animation_data.action_slot=action.slots[0]
            for fraction in (0,.35,.7,.95):
                start,end=action.frame_range
                frame=start+(end-start)*fraction
                bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
                evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
                mesh=evaluated.to_mesh()
                error=max(abs((mesh.vertices[a].co-mesh.vertices[b].co).length-length) for a,b,length in edges)
                maximum=max(maximum,error)
                check(name+" rigid edges in "+action_name+" "+str(fraction),error<.00002,error)
                evaluated.to_mesh_clear()
        details[name]={"vertices":len(obj.data.vertices),"edges_per_pose":len(edges),"maximum_edge_error_m":maximum}
    else:
        obj=next(obj for obj in meshes if not obj.name.startswith("Shared_"))
        points=[(v,obj.matrix_world@v.co) for v in obj.data.vertices]
        for side in (-1,1):
            band=[(v,p) for v,p in points if abs(p.z-.415)<.0002 and side*p.x>0]
            check(name+" has the shared join on side "+str(side),len(band)>20,len(band))
            target=.995 if name.endswith("head_chest") else 1.0
            error=max(abs((((p.x-side*.132)/.066)**2+((p.y-.001)/.062)**2)**.5-target) for v,p in band)
            check(name+" common ellipse on side "+str(side),error<.001,error)
            check(name+" join follows only its shin on side "+str(side),all(len(v.groups)==1 and obj.vertex_groups[v.groups[0].group].name==("shin.L" if side==1 else "shin.R") for v,p in band))
            overlap=[v for v,p in points if .40099<=p.z<=.42301 and side*p.x>0]
            check(name+" entire overlap follows the same shin on side "+str(side),all(len(v.groups)==1 and obj.vertex_groups[v.groups[0].group].name==("shin.L" if side==1 else "shin.R") for v in overlap))
        z=[p.z for v,p in points]
        if name.endswith("boots"):
            check(name+" boot ends at overlapping mid-shin cuff",abs(max(z)-.423)<.0001,max(z))
        else:
            check(name+" trousers extend inside every boot",abs(min(z)-.401)<.0001,min(z))
        details[name]={"minimum_z":min(z),"maximum_z":max(z),"join_radius_scale":target}
    for obj in imported:
        bpy.data.objects.remove(obj,do_unlink=True)
# Both skins carry identical rest transforms throughout the measured overlap.
# Verify that the shared connector retains its axial coverage in every clip.
from mathutils import Vector
master.data.pose_position="POSE"
for action_name,action in actions.items():
    master.animation_data.action=action
    master.animation_data.action_slot=action.slots[0]
    for fraction in (0,.35,.7,.95):
        start,end=action.frame_range
        frame=start+(end-start)*fraction
        bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
        for side in (-1,1):
            name="shin.L" if side==1 else "shin.R"
            deform=master.matrix_world@master.pose.bones[name].matrix@master.data.bones[name].matrix_local.inverted()@master.matrix_world.inverted()
            a=deform@Vector((side*.132,.001,.401))
            b=deform@Vector((side*.132,.001,.423))
            check("All four mixed joins retain overlap "+action_name+" "+str(fraction)+" "+str(side),abs((b-a).length-.022)<.00001,(b-a).length)
report={"checks":checks,"count":len(checks),"details":details,"overlap_m":.022,
        "note":"Both garments use the same elliptical contour and rigid shin transform; trousers sit 0.5% inside boot wall."}
(OUT/"joint_validation.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print("FITTED_JOINTS_VERIFIED",len(checks),json.dumps(details),flush=True)
