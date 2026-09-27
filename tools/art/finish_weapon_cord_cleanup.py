import bpy,bmesh,math,json,numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
target=OUT/'Threadborne_Equipped_Animation_Test.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
s=bpy.context.scene;s.frame_set(1)
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
def remove_components(name,predicate):
    ob=bpy.data.objects[name];bm=bmesh.new();bm.from_mesh(ob.data);visited=set();removed=[]
    for start in bm.verts:
        if start in visited:continue
        stack=[start];visited.add(start);group=[]
        while stack:
            v=stack.pop();group.append(v)
            for e in v.link_edges:
                nxt=e.other_vert(v)
                if nxt not in visited:visited.add(nxt);stack.append(nxt)
        c=np.array([v.co[:] for v in group]);lo=c.min(0);hi=c.max(0)
        if predicate(lo,hi):removed.extend(group)
    count=len(removed);bmesh.ops.delete(bm,geom=removed,context='VERTS');bm.to_mesh(ob.data);bm.free();ob.data.update()
    print('REMOVED',name,count,flush=True);return count
counts={}
counts['sword']=remove_components('Threadborne_Sword',lambda lo,hi: lo[2]>.22 and hi[2]>.26 and hi[2]<.43 and hi[0]<-.01 and lo[1]>-.305)
counts['shield']=remove_components('Shield_Original_Front',lambda lo,hi: lo[0]>.035 and hi[0]<.09 and lo[1]>-.115 and hi[1]<-.04 and hi[2]<.035)
root=bpy.data.objects['Threadborne_Shield_ROOT']
if not root.get('elbow_end_tilt_v3'):
    # Local +Y is elbowward, +Z is shield-up. Pivot at wrist strap, not shield center.
    pivot=Vector((-.10,-.102,0))
    root.matrix_basis=root.matrix_basis@Matrix.Translation(pivot)@Matrix.Rotation(math.radians(-7),4,'X')@Matrix.Translation(-pivot)
    root['elbow_end_tilt_v3']='Elbow end tilted down 7 degrees around the wrist strap; loop geometry unchanged.'
bpy.context.view_layer.update();cam=s.camera
rig=bpy.data.objects['Threadborne_Rig'];bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='POSE')
bpy.ops.wm.save_as_mainfile(filepath=str(target))
(OUT/'cord_cleanup_report.json').write_text(json.dumps(counts,indent=2))
s.render.resolution_x=s.render.resolution_y=700;s.render.resolution_percentage=100;s.cycles.samples=12
for label,frame in [('idle',38),('run',88),('jump',112)]:
    s.frame_set(frame);center=root.matrix_world@Vector((-.10,0,0));direction=root.matrix_world.to_3x3()@Vector((-1,-.65,.35))
    cam.location=center+direction.normalized()*2;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.53
    s.render.filepath=str(OUT/(label+'_shield_fit.png'));bpy.ops.render.render(write_still=True)
s.frame_set(38)
ob=bpy.data.objects['Threadborne_Sword'];center=ob.matrix_world@Vector((0,-.315,.30));cam.location=center+ob.matrix_world.to_3x3()@Vector((-2,0,0));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.34
# Diagnostic-only cropped evaluated surface reveals the back of the hand without torso occlusion.
body=bpy.data.objects['Threadborne_Posing_Preview'];evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get());crop=bpy.data.meshes.new_from_object(evaluated)
bm=bmesh.new();bm.from_mesh(crop);bmesh.ops.delete(bm,geom=[v for v in bm.verts if (body.matrix_world@v.co-center).length>.115],context='VERTS');bm.to_mesh(crop);bm.free()
hand=bpy.data.objects.new('DIAGNOSTIC_Hand_Crop',crop);s.collection.objects.link(hand);hand.matrix_world=body.matrix_world
body.hide_render=True
bpy.data.objects['Threadborne_Character'].hide_render=True
s.render.filepath=str(OUT/'sword_back_hand_check.png');bpy.ops.render.render(write_still=True)
for o in s.objects:
    if o.type in {'MESH','CURVE'}:o.hide_render=o.name not in {'Threadborne_Sword','Shield_Original_Front'}
for name,co,axis,size in [('sword',Vector((0,-.315,.30)),Vector((-2,0,0)),.65),('shield',Vector((0,.14,-.03)),Vector((2,0,0)),.65)]:
    ob=bpy.data.objects['Threadborne_Sword' if name=='sword' else 'Shield_Original_Front'];center=ob.matrix_world@co;cam.location=center+ob.matrix_world.to_3x3()@axis;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=size
    s.render.filepath=str(OUT/(name+'_cord_cleanup.png'));bpy.ops.render.render(write_still=True)
print('CORD_CLEANUP_COMPLETE',flush=True)
