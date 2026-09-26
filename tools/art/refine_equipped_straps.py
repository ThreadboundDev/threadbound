"""Scoped equipment cleanup on the saved animation test; source weapons unchanged."""
import bpy,bmesh,math,json
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
target=OUT/'Threadborne_Equipped_Animation_Test.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
s=bpy.context.scene;s.frame_set(1)
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
root=bpy.data.objects['Threadborne_Shield_ROOT'];sword=bpy.data.objects['Threadborne_Sword']
if not sword.get('pendants_removed_v2'):
    bm=bmesh.new();bm.from_mesh(sword.data)
    unwanted=[v for v in bm.verts if v.co.z<.145 and (v.co.y>-.265 or (v.co.y>-.273 and v.co.x<-.045))]
    removed=len(unwanted);bmesh.ops.delete(bm,geom=unwanted,context='VERTS');bm.to_mesh(sword.data);bm.free();sword.data.update()
    sword['pendants_removed_v2']=removed+int(sword.get('pendants_removed',0))
    print('SWORD_PENDANT_VERTICES_REMOVED',removed,flush=True)
if not root.get('arm_loop_fit_v2'):
    # Inward by 6 mm; retain clearance at the wider sleeve end of the forearm.
    root.matrix_basis=root.matrix_basis@Matrix.Translation((-.006/.85,0,0))
    for ob in list(root.children):
        if ob.name.startswith('Shield_Raised_Leather_Arm_Loop'):
            for v in ob.data.vertices:
                z=v.co.z+.030;t=max(0,min(1,(.105-z)/.21))
                depth=.130 if v.co.y>.14 else .116
                v.co.x=-.058-depth*math.sin(math.pi*t)**.65
            ob.data.update()
        elif ob.name.startswith('Shield_Leather_Edge_Stitch'):
            for sp in ob.data.splines:
                for p in sp.points:
                    z=p.co.z+.030;t=max(0,min(1,(.105-z)/.21))
                    depth=.130 if p.co.y>.14 else .116
                    p.co.x=-.061-depth*math.sin(math.pi*t)**.65
    root['arm_loop_fit_v2']='Shield inward 6mm; wrist/elbow loops deepened separately to clear the clothed forearm.'
bpy.context.view_layer.update()
cam=s.camera;original=cam.matrix_world.copy();scale=cam.data.ortho_scale
rig=bpy.data.objects['Threadborne_Rig'];bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='POSE')
bpy.ops.wm.save_as_mainfile(filepath=str(target))
s.cycles.samples=16;s.render.resolution_x=s.render.resolution_y=750;s.render.resolution_percentage=100
for label,frame in [('idle',38),('run',88),('jump',112)]:
    s.frame_set(frame)
    center=root.matrix_world@Vector((-.10,0,0));direction=root.matrix_world.to_3x3()@Vector((-1,-.65,.35))
    cam.location=center+direction.normalized()*2;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.53
    s.render.filepath=str(OUT/(label+'_shield_fit.png'));bpy.ops.render.render(write_still=True)
print('STRAP_REFINEMENT_COMPLETE',flush=True)
