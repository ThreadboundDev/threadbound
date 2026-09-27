import bpy,json,numpy as np
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[2]/'ArtSource/Player/Blender/imported_character/mixamo_test'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Threadborne_Equipped_Animation_Test.blend'))
s=bpy.context.scene;s.frame_set(1);cam=s.camera
for name in ['Threadborne_Sword','Shield_Original_Front']:
    ob=bpy.data.objects[name];me=ob.data;c=np.array([v.co[:] for v in me.vertices]);parent=np.arange(len(c))
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
    (OUT/(name+'_components.json')).write_text(json.dumps(data,indent=2))
    print(name,'bounds',c.min(0),c.max(0),flush=True)
for o in s.objects:
    if o.type in {'MESH','CURVE'}:o.hide_render=o.name!='Threadborne_Sword'
ob=bpy.data.objects['Threadborne_Sword'];s.render.resolution_x=700;s.render.resolution_y=1000;s.cycles.samples=12
for sign in [-1,1]:
    center=ob.matrix_world@Vector((0,-.315,.30));cam.location=center+(ob.matrix_world.to_3x3()@Vector((sign*2,0,0)));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.65
    s.render.filepath=str(OUT/('sword_handle_side_'+str(sign)+'.png'));bpy.ops.render.render(write_still=True)
