"""Reload source, compare actual tower shader graphs, and probe slip opening."""
import bpy, json, hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT=ROOT/'outputs/lakeside-buildings-v1'
keys=['walnut','plaster','blue_tiles','slate','rope','iron','recess']
def value(v):
    if isinstance(v,(str,int,float,bool)):return v
    try:return list(v)
    except:return str(v)
def signature():
    result={}
    for key in keys:
        m=bpy.data.materials[key];ns=[]
        for n in m.node_tree.nodes:
            entry={'name':n.name,'type':n.type,'inputs':{str(i)+s.name:value(s.default_value) for i,s in enumerate(n.inputs) if hasattr(s,'default_value')}}
            if n.type=='TEX_IMAGE' and n.image:
                assert n.image.packed_file,n.image.name
                entry['packed_image_sha256']=hashlib.sha256(n.image.packed_file.data).hexdigest()
            ns.append(entry)
        links=sorted((l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name) for l in m.node_tree.links)
        result[key]={'nodes':ns,'links':links}
    return result
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'outputs/central-tower-model-v3/CentralTower_Editable.blend'))
source=signature()
bpy.ops.wm.open_mainfile(filepath=str(OUT/'LakesideBuildings_Editable.blend'))
assert signature()==source,'Materials differ from the tower shader graphs or packed image bytes'
images={}
for im in bpy.data.images:
    if im.source=='FILE' and im.users:
        size=list(im.size);pixel=im.pixels[0]
        assert im.packed_file and im.has_data and size==[4096,4096],(im.name,size)
        images[im.name]=size
assert len(images)==12,images
sc=bpy.data.scenes['01 · Covered boat slip'];bpy.context.window.scene=sc
col=bpy.data.collections['CoveredBoatSlip_MODEL'];dg=bpy.context.evaluated_depsgraph_get()
blockers=[]
for ob in col.all_objects:
    if ob is None or ob.type!='MESH':continue
    tree=BVHTree.FromObject(ob,dg)
    for x in [-1.8,0,1.8]:
        for y in [-1.3,0,1.3]:
            hit=tree.ray_cast(Vector((x,y,-.15)),Vector((0,0,1)),1.4)
            if hit[0] is not None:blockers.append({'object':ob.name,'x':x,'y':y})
assert not blockers,blockers
report={'checks_passed':True,'exact_tower_shader_graphs_and_packed_texture_bytes':True,'packed_source_texture_sizes':images,'slip_lower_opening_probe_blockers':blockers,'source_scenes':[s.name for s in bpy.data.scenes],'source_material_count':len(bpy.data.materials)}
(OUT/'blend_verification.json').write_text(json.dumps(report,indent=2))
print('BLEND_VERIFIED',json.dumps(report),flush=True)
