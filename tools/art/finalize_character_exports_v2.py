"""Prune interpolated skin weights, save sources, and export only active actors."""
from pathlib import Path
import bpy,json,os,tempfile,sys
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/character-quality-v2';tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
report=json.loads((WORK/'final_export_report.json').read_text()) if (WORK/'final_export_report.json').exists() else {}
for family,source,actors in [
 ('Villagers','LakesideVillagers_v2.blend',['NetMender','Boatwright']),
 ('Enemies/EaveRunner','EaveRunner_Woven_v2.blend',['EaveRunner']),
 ('Enemies/LoomHeron','LoomHeron_Woven_v2.blend',['LoomHeron'])]:
    if '--villagers-only' in sys.argv and family!='Villagers':continue
    src=ROOT/'ArtSource/BlueBiome'/family/source;bpy.ops.wm.open_mainfile(filepath=str(src));bpy.context.preferences.filepaths.save_version=0
    for kind in actors:
        rig=next(o for o in bpy.data.objects if o.type=='ARMATURE' and kind in o.name)
        scene=rig.users_scene[0];bpy.context.window.scene=scene
        meshes=[o for o in scene.objects if o.type=='MESH' and o.parent==rig]
        pruned=0
        for ob in meshes:
            if not ob.data.uv_layers:
                uv=ob.data.uv_layers.new(name='UVMap')
                for loop in ob.data.loops:
                    p=ob.data.vertices[loop.vertex_index].co;uv.data[loop.index].uv=(p.x*2,p.z*2)
            for v in ob.data.vertices:
                allgroups=[(g.group,g.weight) for g in v.groups]
                groups=sorted([(i,w) for i,w in allgroups if w>1e-6],key=lambda x:-x[1]);keep=groups[:4];total=sum(w for g,w in keep)
                if len(allgroups)<=4 and abs(total-1)<1e-5:continue
                pruned+=1
                for g,w in allgroups:ob.vertex_groups[g].remove([v.index])
                for g,w in keep:ob.vertex_groups[g].add([v.index],w/total,'REPLACE')
        if kind in ['NetMender','Boatwright']:
            name='WorkIdle.001' if kind=='Boatwright' else 'WorkIdle'
            rig.animation_data.action=bpy.data.actions[name]
        else:rig.animation_data.action=bpy.data.actions['idle']
        scene.frame_set(1);bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
        for ob in meshes:ob.select_set(True)
        bpy.context.view_layer.objects.active=rig
        out=ROOT/'Assets/BlueBiome'/family/'Models'/(kind+'_v2.glb')
        bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,export_force_sampling=True,export_skins=True,export_cameras=False,export_lights=False)
        report[kind]={'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes),'vertices':sum(len(o.data.vertices) for o in meshes),'bones':len(rig.data.bones),'normalized_vertices':pruned}
        print('CHARACTER_V2_FINAL_EXPORTED',kind,report[kind],flush=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(src),compress=True)
(WORK/'final_export_report.json').write_text(json.dumps(report,indent=2))
