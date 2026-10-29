"""Export selected CC0 KayKit weapons with their grip at the origin."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/third-person-study-2026-10-28'
BASE=WORK/'temp/polish/weapons';OUT=WORK/'project/assets/weapons';OUT.mkdir(exist_ok=True)
records=[]
for source,name,length,grip in [('staff_A','ranged_staff',1.15,.28),('spear_A','balance_spear',2.05,.24)]:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(next(BASE.rglob(source+'.gltf'))))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 allverts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 lo=Vector(tuple(min(v[i] for v in allverts) for i in range(3)));hi=Vector(tuple(max(v[i] for v in allverts) for i in range(3)))
 axis=max(range(3),key=lambda i:hi[i]-lo[i]);scale=length/(hi[axis]-lo[axis]);center=(lo+hi)/2;center[axis]=lo[axis]+grip*(hi[axis]-lo[axis])
 turn=Vector(tuple(1 if i==axis else 0 for i in range(3))).rotation_difference(Vector((0,0,1)))
 for o in meshes:
  verts=[o.matrix_world@v.co for v in o.data.vertices]
  o.parent=None;o.matrix_world=Matrix.Identity(4)
  for vertex,co in zip(o.data.vertices,verts):vertex.co=turn@((co-center)*scale)
 bpy.ops.object.select_all(action='DESELECT')
 for o in meshes:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
 records.append({'archive':'KayKit_FantasyWeaponsBits_1.0_FREE.zip','archive_sha256':hashlib.sha256((Path.home()/'Documents/Threadbound Asset Library/archives/KayKit_FantasyWeaponsBits_1.0_FREE.zip').read_bytes()).hexdigest(),'member':str(next(BASE.rglob(source+'.gltf')).relative_to(BASE)).replace('\\','/'),'target':'assets/weapons/'+name+'.glb','target_sha256':hashlib.sha256((OUT/(name+'.glb')).read_bytes()).hexdigest(),'license':'CC0 1.0; retained KayKit pack license','derivative':'Grip origin, uniform gameplay scale, same geometry/materials'})
(OUT/'provenance.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
print('TRIAL_WEAPONS_EXPORTED')
