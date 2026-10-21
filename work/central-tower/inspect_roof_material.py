import bpy,json
from pathlib import Path
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath='C:/Users/chase/Documents/threadbound/outputs/central-tower-model-v2/CentralTower_Editable.blend')
for name in ['Roof_Tier03_Front_Mitered','Roof_Tier03_Right_Side_With_Corners']:
    ob=bpy.data.objects[name];print('OBJECT',name,[(m.name if m else None) for m in ob.data.materials],flush=True)
    polygons=[p for p in ob.data.polygons if p.material_index==0]
    for p in polygons[:3]:
        uv=ob.data.uv_layers.active.data[p.loop_indices[0]].uv
        mat=ob.data.materials[0];tex=mat.node_tree.nodes.get('BaseColor_4K')
        im=tex.image;w,h=im.size
        xx=int((uv.x%1)*w);yy=int((uv.y%1)*h);index=(yy*w+xx)*4
        color=list(im.pixels[index:index+4])
        print('SAMPLE',p.center[:],p.normal[:],uv[:],color,tex.extension,im.name,repr(im.filepath),flush=True)
