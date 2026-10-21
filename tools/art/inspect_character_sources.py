from pathlib import Path
import bpy, json
ROOT=Path(__file__).resolve().parents[2]
data={}
for f in ['ArtSource/BlueBiome/Villagers/LakesideVillagers_v1.blend','ArtSource/BlueBiome/Enemies/EaveRunner/EaveRunner_Woven_v1.blend','ArtSource/BlueBiome/Enemies/LoomHeron/LoomHeron_Woven_v1.blend']:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/f));rows=[]
    for o in bpy.data.objects:
        if o.type!='MESH' or not o.parent or o.parent.type!='ARMATURE':continue
        mats=[]
        for i,m in enumerate(o.data.materials):
            ps=[p for p in o.data.polygons if p.material_index==i]
            mats.append({'name':m.name,'polys':len(ps),'tris':sum(len(p.vertices)-2 for p in ps),'quads':sum(len(p.vertices)==4 for p in ps)})
        rows.append({'object':o.name,'scene':[s.name for s in o.users_scene],'materials':mats})
    data[f]=rows
(ROOT/'work/character-quality-v2/source_inventory.json').write_text(json.dumps(data,indent=2))
print(json.dumps(data))
