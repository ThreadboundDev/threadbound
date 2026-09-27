import bpy,json,numpy as np
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
bpy.ops.wm.open_mainfile(filepath=str(out/'Threadborne_Equipped_Animation_Test.blend'))
s=bpy.context.scene;s.frame_set(1)
ob=bpy.data.objects['Threadborne_Sword'];me=ob.data
c=np.array([v.co[:] for v in me.vertices]);print('SWORD_BOUNDS',c.min(0),c.max(0),flush=True)
# Connected components identify generated floating pendants without touching the blade.
parent=np.arange(len(c))
def find(a):
    while parent[a]!=a:parent[a]=parent[parent[a]];a=parent[a]
    return a
for e in me.edges:
    a,b=e.vertices;ra,rb=find(a),find(b)
    if ra!=rb:parent[rb]=ra
groups={}
for i in range(len(c)):groups.setdefault(int(find(i)),[]).append(i)
data=[]
for ids in sorted(groups.values(),key=len,reverse=True):
    cc=c[ids];data.append({'count':len(ids),'min':cc.min(0).tolist(),'max':cc.max(0).tolist(),'root':ids[0]})
print('COMPONENTS',json.dumps(data[:45]),flush=True)
root=bpy.data.objects['Threadborne_Shield_ROOT'];rig=bpy.data.objects['Threadborne_Rig'];inv=root.matrix_world.inverted()
bone=rig.pose.bones['forearm.L']
print('ARM_IN_SHIELD',list(inv@(rig.matrix_world@bone.head)),list(inv@(rig.matrix_world@bone.tail)),flush=True)
preview=bpy.data.objects['Threadborne_Posing_Preview'];ev=preview.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
pts=np.array([tuple(inv@(preview.matrix_world@v.co)) for v in mesh.vertices])
for y in [-.102,.102]:
    sel=pts[(abs(pts[:,1]-y)<.025)&(abs(pts[:,2])<.09)&(pts[:,0]>-.22)&(pts[:,0]<.02)]
    print('ARM_SECTION',y,sel.min(0),sel.max(0),flush=True)
ev.to_mesh_clear()
for o in s.objects:
    if o.name.startswith('Shield_Raised'):
        print('LOOP',o.name,'world',list(o.matrix_world.translation),'local',list(o.location),'bounds',[list(o.matrix_local@Vector(x)) for x in o.bound_box],flush=True)
(out/'equipment_inspection.json').write_text(json.dumps(data,indent=2))
