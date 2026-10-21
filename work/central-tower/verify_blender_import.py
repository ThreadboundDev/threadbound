import bpy,json,tempfile,os
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve()
ROOT=HERE.parents[3] if HERE.parent.name=='source' else HERE.parents[2]
OUT=HERE.parents[1] if HERE.parent.name=='source' else ROOT/'outputs/central-tower-model-v1'
temp=OUT/'source/import-temp';temp.mkdir(exist_ok=True)
tempfile.tempdir=str(temp);os.environ['TEMP']=str(temp);os.environ['TMP']=str(temp)
report={}
for filename in ['CentralTower_Exterior.glb','CentralTower_Cutaway.glb']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUT/filename))
    meshes=[ob for ob in bpy.context.scene.objects if ob.type=='MESH']
    coords=[ob.matrix_world@v.co for ob in meshes for v in ob.data.vertices]
    lo=[min(v[i] for v in coords) for i in range(3)];hi=[max(v[i] for v in coords) for i in range(3)]
    dims=[hi[i]-lo[i] for i in range(3)]
    assert abs(dims[0]-9.375)<.06 and abs(dims[2]-32.03125)<.06
    assert all(bool(ob.data.uv_layers) for ob in meshes)
    loaded={node.image for mat in bpy.data.materials if mat.use_nodes for node in mat.node_tree.nodes if node.type=='TEX_IMAGE' and node.image is not None}
    for im in loaded:
        size=list(im.size)
        pixel=im.pixels[0]  # Force Blender's lazy image loading before checking it.
        assert im.has_data and min(size)>=2048,(im.name,size,im.has_data)
    assert len(loaded)>=12
    hasfacade=any('02_Facade_Removable' in ob.name for ob in meshes)
    assert hasfacade==(filename=='CentralTower_Exterior.glb')
    report[filename]={'import_success':True,'meshes':len(meshes),'dimensions':dims,'loaded_image_count':len(loaded),'has_facade':hasfacade}
report['checks_passed']=True
(OUT/'blender_import_verification.json').write_text(json.dumps(report,indent=2))
print('IMPORT_VERIFICATION_COMPLETE',json.dumps(report),flush=True)
