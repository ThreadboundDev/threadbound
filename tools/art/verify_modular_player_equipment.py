"""Independently reopen saved gear exports and sample their real skinning."""
from pathlib import Path
import bpy
import hashlib
import json
import math
import struct
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'ArtSource/Player/Blender/PaleDollStudy/GameReadyDoll/ModularEquipment'
EXPORT=ROOT/'Assets/Threadborne/Player/LocalDoll'
checks=[]


def check(name, passed, detail=None):
    checks.append({'name':name,'passed':bool(passed),'detail':detail})
    if not passed:
        raise AssertionError((name,detail))


def document(path):
    raw=path.read_bytes();length,kind=struct.unpack_from('<II',raw,12)
    assert kind==0x4e4f534a
    return json.loads(raw[20:20+length])


def clips(doc):
    return {a['name']:max(doc['accessors'][s['input']]['max'][0] for s in a['samplers']) for a in doc.get('animations',[])}


build=json.loads((OUT/'build_report.json').read_text())
for name,digest in build['source_sha256'].items():
    check('source archive intact: '+name,hashlib.sha256((ROOT/'Assets/Threadborne/Equipment/Base Gear'/name).read_bytes()).hexdigest()==digest)
base=document(EXPORT/'threadborne_doll_modular.glb')
original=document(EXPORT/'threadborne_doll_equipped.glb')
check('body retains 48 clips',len(clips(base))==48 and clips(base).keys()==clips(original).keys())
check('body preserves clip durations',max(abs(clips(base)[k]-v) for k,v in clips(original).items())<.034)
check('body only with reversible covered regions',set(n['name'] for n in base['nodes'] if 'mesh' in n)=={'Threadborne_Doll','Doll_Covered_Gloves','Doll_Covered_Boots','Doll_Covered_HeadChest'})
original_body=next(n['mesh'] for n in original['nodes'] if n.get('name')=='Threadborne_Doll')
original_triangles=sum(original['accessors'][p['indices']]['count']//3 for p in original['meshes'][original_body]['primitives'])
split_triangles=sum(base['accessors'][p['indices']]['count']//3 for mesh in base['meshes'] for p in mesh['primitives'])
check('coverage partition preserves every original body triangle',split_triangles==original_triangles,{'original':original_triangles,'partition':split_triangles})
check('body retains all 62 joints',len(base['skins'][0]['joints'])==62)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(EXPORT/'threadborne_doll_modular.glb'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=bpy.data.objects['Threadborne_Doll']
for track in rig.animation_data.nla_tracks: track.mute=True
reference={b.name:b.matrix_local.copy() for b in rig.data.bones}
gear=[]
rigid_edges=[]
for name,piece in build['pieces'].items():
    path=EXPORT/'Equipment'/(name+'.glb')
    doc=document(path)
    check(name+' has no animation clock',not doc.get('animations'))
    check(name+' embeds textures',all('bufferView' in im for im in doc.get('images',[])))
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    added=set(bpy.data.objects)-before
    donor=next(o for o in added if o.type=='ARMATURE')
    check(name+' matches rest skeleton',all(b.name in reference and max(abs(b.matrix_local[r][c]-reference[b.name][r][c]) for r in range(4) for c in range(4))<1e-5 for b in donor.data.bones))
    # The importer also creates an unlinked Icosphere for bone display shapes.
    # It is not exported gear; inspect the actual scene's skinned meshes.
    meshes=[o for o in added if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
    check(name+' exported expected mesh count',len(meshes)==len(piece['meshes']),[o.name for o in meshes])
    for obj in meshes:
        if name == 'base_boots':
            points=[obj.matrix_world @ v.co for v in obj.data.vertices]
            height=max(p.z for p in points)
            ankle=reference['foot.'+obj.name[-1]].translation.z
            knee=reference['shin.'+obj.name[-1]].translation.z
            fraction=(height-ankle)/(knee-ankle)
            check(obj.name+' cuff ends at mid-shin',.46<fraction<.53,{'height':height,'fraction_ankle_to_knee':fraction})
            check(obj.name+' sole remains on the authored floor',abs(min(p.z for p in points))<.001)
        check(obj.name+' weights normalized',all(v.groups and len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in obj.data.vertices))
        check(obj.name+' targets existing bones',all(g.name in reference for g in obj.vertex_groups))
        # Rebind the independently imported piece to the one live rig exactly
        # as the runtime does. Keep original mesh and inverse-bind coordinates.
        world=obj.matrix_world.copy();obj.parent=rig;obj.matrix_world=world
        for modifier in obj.modifiers:
            if modifier.type=='ARMATURE': modifier.object=rig
        gear.append(obj)
        rigid={v.index:v.groups[0].group for v in obj.data.vertices if len(v.groups)==1}
        edges=[]
        for edge in obj.data.edges:
            a,b=edge.vertices
            if a in rigid and b in rigid and rigid[a]==rigid[b]:
                distance=(obj.data.vertices[a].co-obj.data.vertices[b].co).length
                if distance>.002: edges.append((a,b,distance))
        rigid_edges.append((obj,edges[::max(1,len(edges)//400)]))
    for obj in added-set(meshes): bpy.data.objects.remove(obj,do_unlink=True)

maximum_error=0.0
sample_count=0
for action_name in ['idle_4','run_1','block_idle_1','slash_2','jump_1','roll_1','swimming_1','casting_2']:
    action=next(a for a in bpy.data.actions if a.name==action_name or a.name.endswith('|'+action_name))
    rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
    for fraction in [.0,.25,.5,.75]:
        bpy.context.scene.frame_set(int(action.frame_range[0]+fraction*(action.frame_range[1]-action.frame_range[0])))
        deps=bpy.context.evaluated_depsgraph_get()
        for obj,edges in rigid_edges:
            evaluated=obj.evaluated_get(deps);mesh=evaluated.to_mesh()
            check(obj.name+' finite pose '+action_name+' '+str(fraction),all(all(math.isfinite(n) and abs(n)<5 for n in v.co) for v in mesh.vertices))
            for a,b,distance in edges:
                maximum_error=max(maximum_error,abs((mesh.vertices[a].co-mesh.vertices[b].co).length-distance))
            evaluated.to_mesh_clear()
        sample_count+=1
check('rigid bracers/weapon/cloth regions retain edge lengths',maximum_error<1e-5,maximum_error)
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Threadborne_Doll_Modular.blend'))
check('editable source retains all 48 actions after reopening',len(bpy.data.actions)==48)
check('editable source retains all clothing/weapon components',all(bpy.data.objects.get(name) is not None for piece in build['pieces'].values() for name in piece['meshes']))
report={'checks':len(checks),'failures':[c for c in checks if not c['passed']],
    'sampled_poses':sample_count,'maximum_rigid_edge_error':maximum_error,'results':checks}
(OUT/'export_verification.json').write_text(json.dumps(report,indent=2))
print('MODULAR_EXPORT_CHECKS',json.dumps({k:v for k,v in report.items() if k!='results'}),flush=True)
