"""Narrow elbow/wrist weight transitions in the manual workspace only.
Run via Blender's bridge after taking a separate backup. Poses/keys are untouched.
"""
import bpy, json
from pathlib import Path

rig=bpy.data.objects['Threadborne_Rig']
assert Path(bpy.data.filepath).name=='Threadborne_Aerial_Attacks_Workspace.blend'
assert Path(bpy.data.filepath).with_name('Threadborne_Aerial_Attacks_Before_Arm_Fix.blend').exists()
report={}
for name in ['Threadborne_Posing_Preview','Threadborne_Character']:
    obj=bpy.data.objects[name]
    groups={g.name:g for g in obj.vertex_groups}
    changed=0
    for side in ['R','L']:
        joint=rig.data.bones['forearm.'+side]
        axis=joint.tail_local-joint.head_local
        names=['upper_arm.'+side,'forearm.'+side,'hand.'+side]
        ids=[groups[n].index for n in names]
        to_rig=rig.matrix_world.inverted() @ obj.matrix_world
        for vertex in obj.data.vertices:
            weights={g.group:g.weight for g in vertex.groups}
            values=[weights.get(i,0.0) for i in ids]
            total=sum(values)
            if total<.65:continue
            point=to_rig @ vertex.co
            t=(point-joint.head_local).dot(axis)/axis.length_squared
            if t<-.5 or t>1.25:continue
            # Smoothly leave shoulder and finger transitions untouched.
            influence=min(1.0,max(0.0,(t+.5)/.25),max(0.0,(1.25-t)/.15))
            influence=influence*influence*(3-2*influence)
            exponent=1.0+1.5*influence
            sharpened=[(w/total)**exponent for w in values]
            denominator=sum(sharpened)
            result=[total*w/denominator for w in sharpened]
            assert abs(sum(result)-total)<1e-6
            if max(abs(a-b) for a,b in zip(result,values))<1e-6:continue
            for group,weight in zip(names,result):
                groups[group].add([vertex.index],weight,'REPLACE')
            changed+=1
    report[name]=changed
    obj.data.update()
rig['arm_weight_refinement']='Narrowed elbow/wrist transitions; preserved total arm influence, shoulder/finger weights, IK and animation keys.'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath,compress=True)
print('ARM_WEIGHTS_REFINED',json.dumps(report))
