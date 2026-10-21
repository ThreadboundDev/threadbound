"""Build rolled hems directly around the sleeve; transfer the garment weights."""
from pathlib import Path
import bpy,bmesh,math,json,statistics
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'ArtSource/BlueBiome/Villagers/LakesideVillagers_v2.blend'
bpy.ops.wm.open_mainfile(filepath=str(SRC));bpy.context.preferences.filepaths.save_version=0;report={}
for kind in ['NetMender','Boatwright']:
    actor=bpy.data.objects[kind+'_TexturedCharacter'];rig=actor.parent;bpy.context.window.scene=actor.users_scene[0];data=actor.data
    flax=next(m for m in data.materials if 'flax linen' in m.name)
    bm=bmesh.new();bm.from_mesh(data);deform=bm.verts.layers.deform.active
    cuffgroups={g.index for g in actor.vertex_groups if g.name.startswith('upperarm02.')}
    old=[f for f in bm.faces if 'flax linen' in data.materials[f.material_index].name and all(any(v[deform].get(g,0)>.98 for g in cuffgroups) for v in f.verts)]
    bmesh.ops.delete(bm,geom=old,context='FACES');bm.to_mesh(data);bm.free();data.update()
    polys=[tuple(p.vertices) for p in data.polygons if 'worn indigo' in data.materials[p.material_index].name]
    indices=set(i for p in polys for i in p);tree=KDTree(len(indices));verts=list(indices)
    for j,i in enumerate(verts):tree.insert(data.vertices[i].co,i)
    tree.balance();surface=BVHTree.FromPolygons([v.co for v in data.vertices],polys)
    points=[];faces=[];weights=[]
    for side in ['L','R']:
        elbow=rig.data.bones['lowerarm01.'+side].head_local;axis=(elbow-rig.data.bones['upperarm02.'+side].head_local).normalized();center=elbow-axis*.05
        u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u);radii=[]
        for k in range(64):
            a=k*math.tau/64;direction=u*math.cos(a)+v*math.sin(a);origin=center.copy();furthest=None
            for h in range(8):
                hit,normal,_,_=surface.ray_cast(origin,direction,.11)
                if hit is None or (hit-center).length>.11:break
                furthest=hit;origin=hit+direction*.0003
            radii.append((furthest-center).length if furthest is not None else None)
        valid=[r for r in radii if r is not None and .025<r<.10];fallback=statistics.median(valid) if valid else .055
        start=len(points)
        for k in range(65):
            a=(k%64)*math.tau/64;radial=u*math.cos(a)+v*math.sin(a);r=radii[k%64];r=r if r is not None and .025<r<.10 else fallback
            c=center+radial*(r+.0025)
            for j in range(8):
                q=c+radial*(.0035*math.cos(j*math.tau/8))+axis*(.0035*math.sin(j*math.tau/8));points.append(q)
                accumulated={}
                for co,index,dist in tree.find_n(q,3):
                    for g in data.vertices[index].groups:
                        name=actor.vertex_groups[g.group].name;accumulated[name]=accumulated.get(name,0)+g.weight/max(dist,.001)**2
                best=sorted(accumulated.items(),key=lambda x:-x[1])[:4];total=sum(w for n,w in best);weights.append({n:w/total for n,w in best})
        for k in range(64):
            for j in range(8):faces.append((start+k*8+j,start+k*8+(j+1)%8,start+(k+1)*8+(j+1)%8,start+(k+1)*8+j))
    mesh=bpy.data.meshes.new('Garment fitted rolled hems');mesh.from_pydata(points,[],faces);mesh.materials.append(flax);ob=bpy.data.objects.new(kind+'_FittedSleeveHems',mesh);bpy.context.collection.objects.link(ob);ob.parent=rig
    groups={}
    for i,wts in enumerate(weights):
        for n,w in wts.items():
            if n not in groups:groups[n]=ob.vertex_groups.new(name=n)
            groups[n].add([i],w,'REPLACE')
    uv=mesh.uv_layers.new(name='UVMap')
    for loop in mesh.loops:
        p=mesh.vertices[loop.vertex_index].co;uv.data[loop.index].uv=(p.x*3,p.z*3)
    for p in mesh.polygons:p.use_smooth=True
    mod=ob.modifiers.new('Match sleeve deformation','ARMATURE');mod.object=rig
    bpy.ops.object.select_all(action='DESELECT');actor.select_set(True);ob.select_set(True);bpy.context.view_layer.objects.active=actor;bpy.ops.object.join()
    report[kind]={'old_cuff_faces_removed':len(old),'new_cuff_triangles':len(faces)*2,'total_triangles':sum(len(p.vertices)-2 for p in actor.data.polygons)}
    print('VILLAGER_V2_ROLLED_HEMS',kind,report[kind],flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC),compress=True)
(ROOT/'work/character-quality-v2/cuff_rebuild_report.json').write_text(json.dumps(report,indent=2))
