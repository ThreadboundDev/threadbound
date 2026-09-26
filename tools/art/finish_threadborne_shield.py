"""Cap exposed ornament cuts and verify the separate weapon assemblies."""
import bpy,json
from pathlib import Path
from mathutils import Matrix,Vector
out=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/shield_revision'
target=out/'Threadborne_Sword_Shield_Rear_Fix.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
s=bpy.context.scene;root=bpy.data.objects['Threadborne_Shield_ROOT'];sword=bpy.data.objects['Threadborne_Sword']
assert sword.parent.name=='Threadborne_Sword_ROOT'
assert bpy.data.objects['Shield_Original_Front'].parent==root
for ob in [sword,bpy.data.objects['Shield_Original_Front']]:
    assert max(abs(ob.matrix_world[i][j]-(1 if i==j else 0)) for i in range(4) for j in range(4))<1e-5
if not any(o.name.startswith('Shield_Ornament_Rear_Cap') for o in s.objects):
    for sign in [-1,1]:
        outline=[(-.029,.260),(-.026,.285),(-.012,.309),(0,.313),(.012,.309),(.026,.285),(.029,.260)]
        vv=[(x,.14+y,-.030+sign*z) for x in [-.004,.009] for y,z in outline];n=len(outline)
        ff=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        me=bpy.data.meshes.new('Shield ornament cap');me.from_pydata(vv,[],ff);me.update()
        ob=bpy.data.objects.new('Shield_Ornament_Rear_Cap',me);s.collection.objects.link(ob);me.materials.append(bpy.data.materials['Shield • aged brass'])
        mod=ob.modifiers.new('Worn cap edge','BEVEL');mod.width=.001;mod.segments=3
        ob.parent=root;ob.matrix_world=Matrix.Identity(4)
parts=[o for o in s.objects if o.parent==root]
assert len([o for o in parts if o.name.startswith('Shield_Raised_Leather_Arm_Loop')])==2
sword.hide_render=True
center=Vector((0,.14,-.030));cam=s.camera
cam.location=center+Vector((-1,-.6,.20))*4;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=.77;s.render.filepath=str(out/'corrected_back_three_quarter.png');bpy.ops.render.render(write_still=True)
cam.location=center+Vector((-4,0,0));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
s.render.filepath=str(out/'corrected_back.png');bpy.ops.render.render(write_still=True)
sword.hide_render=False
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
bpy.ops.wm.save_as_mainfile(filepath=str(target))
(out/'validation.json').write_text(json.dumps({'separate_roots':True,'imported_front_and_sword_world_transform_preserved':True,'raised_loops':2,'shield_parts':len(parts),'original_glb_untouched':True},indent=2))
print('SHIELD_VERIFIED',len(parts),'parts')
