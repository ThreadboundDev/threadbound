"""Fit the old cuff/belt loops to the real garment and clean the neck opening."""
from pathlib import Path
import bpy,bmesh,math,json
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'ArtSource/BlueBiome/Villagers/LakesideVillagers_v2.blend'
bpy.ops.wm.open_mainfile(filepath=str(SRC));bpy.context.preferences.filepaths.save_version=0
reports={}
for kind in ['NetMender','Boatwright']:
    actor=bpy.data.objects[kind+'_TexturedCharacter'];rig=actor.parent;mesh=actor.data;bpy.context.window.scene=actor.users_scene[0]
    clothids={i for i,m in enumerate(mesh.materials) if any(s in m.name for s in ['worn indigo','charcoal trouser'])}
    cloth=BVHTree.FromPolygons([v.co for v in mesh.vertices],[tuple(p.vertices) for p in mesh.polygons if p.material_index in clothids])
    bm=bmesh.new();bm.from_mesh(mesh);bm.verts.ensure_lookup_table();bm.normal_update();changed=0
    # Each original cuff ring is a disconnected mesh island with one arm bone.
    seen=set()
    for face in bm.faces:
        mat=mesh.materials[face.material_index].name
        if 'flax linen' not in mat:continue
        seed=face.verts[0]
        if seed.index in seen:continue
        stack=[seed];island=[];seen.add(seed.index)
        while stack:
            v=stack.pop();island.append(v)
            for edge in v.link_edges:
                other=edge.other_vert(v)
                if other.index not in seen:seen.add(other.index);stack.append(other)
        center=sum((v.co for v in island),Vector())/len(island)
        if abs(center.x)<.22 or center.z<1.05 or center.z>1.5:continue
        side='L' if center.x>0 else 'R';bone=rig.data.bones['upperarm02.'+side];axis=(bone.tail_local-bone.head_local).normalized()
        # Fit the middle of the tube to the sleeve, preserving its rounded
        # cross-section instead of leaving a rigid oversized hoop in midair.
        for v in island:
            delta=v.co-center;along=axis*delta.dot(axis);radial=delta-along
            if radial.length<1e-6:continue
            direction=radial.normalized();origin=center+along-axis*.018
            hit,normal,_,_=cloth.ray_cast(origin,direction,.22)
            if hit is None:hit,normal,_,_=cloth.find_nearest(v.co)
            if hit is not None:
                residual=radial.length-.068
                v.co=hit+direction*(.006+residual);changed+=1
    # Refit the three long waist windings. Short knot loops and hanging ties
    # remain deliberately loose and retain their original animation weights.
    for v in bm.verts:
        if not (.965<v.co.z<1.012):continue
        if not any('hemp cord' in mesh.materials[f.material_index].name for f in v.link_faces):continue
        angle=math.atan2((v.co.y-.01)/.175,v.co.x/.22);nominal=Vector((.22*math.cos(angle),.01+.175*math.sin(angle),v.co.z))
        if (v.co-nominal).length>.014:continue
        direction=Vector((nominal.x,nominal.y,0)).normalized();origin=Vector((0,0,v.co.z));last=None
        for step in range(10):
            hit,normal,_,_=cloth.ray_cast(origin,direction,.42)
            if hit is None:break
            last=hit;origin=hit+direction*.0003
        if last is not None:v.co=last+direction*.004+(v.co-nominal);changed+=1
    # Remove the stray thin throat bridge left by the old helper-mesh crop.
    remove=[]
    for face in bm.faces:
        if 'worn indigo' not in mesh.materials[face.material_index].name:continue
        c=face.calc_center_median()
        if 1.36<c.z<1.515 and c.y<-.045 and abs(c.x)<max(.018,.09*(c.z-1.36)/.155):remove.append(face)
    bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(mesh);bm.free();mesh.update()
    reports[kind]={'fitted_binding_vertices':changed,'removed_throat_bridge_faces':len(remove),'triangles':sum(len(p.vertices)-2 for p in mesh.polygons)}
    print('VILLAGER_BINDINGS_FITTED',kind,reports[kind],flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC),compress=True)
(ROOT/'work/character-quality-v2/binding_fit_report.json').write_text(json.dumps(reports,indent=2))
