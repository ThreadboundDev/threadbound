"""Bake native Blender weave/pore detail into real 4K PBR maps, preserving palette."""
from pathlib import Path
import bpy, json, math, os, tempfile, sys
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Assets/BlueBiome/Characters/SharedTexturesV2';OUT.mkdir(parents=True,exist_ok=True)
WORK=ROOT/'work/character-quality-v2';(WORK/'temp').mkdir(exist_ok=True)
tempfile.tempdir=str(WORK/'temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.read_factory_settings(use_empty=True)
P=ROOT/'Assets/BlueBiome/Prototype/Placeables/Buildings/Pavilion3D_V2'
V=ROOT/'Assets/BlueBiome/Villagers/Textures'
E=ROOT/'Assets/BlueBiome/Enemies/EaveRunner/Textures'
SPECS=[('IndigoWeave',V/'IndigoWorkwear_BaseColor.png','cloth'),('FlaxWeave',P/'blue_pavilion_cloth_light.png','cloth'),('WorkCanvas',V/'WorkCanvas_BaseColor.png','cloth'),('WovenCord',E/'WovenCord_BaseColor.png','cord'),('AgedCeramic',E/'AgedIvory_BaseColor.png','ceramic')]
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=4;scene.render.bake.margin=8
bpy.ops.mesh.primitive_plane_add(size=1);ob=bpy.context.object
def mathnode(nodes,links,op,a,b=None):
    n=nodes.new('ShaderNodeMath');n.operation=op
    for i,x in enumerate([a,b]):
        if x is None:continue
        if hasattr(x,'node'):links.new(x,n.inputs[i])
        else:n.inputs[i].default_value=x
    return n.outputs[0]
report={}
for name,path,kind in SPECS:
    mat=bpy.data.materials.new(name+'_4K_Authoring');mat.use_nodes=True;ob.data.materials.clear();ob.data.materials.append(mat)
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;nodes.clear()
    output=nodes.new('ShaderNodeOutputMaterial');emit=nodes.new('ShaderNodeEmission');links.new(emit.outputs[0],output.inputs['Surface'])
    uv=nodes.new('ShaderNodeTexCoord');separate=nodes.new('ShaderNodeSeparateXYZ');links.new(uv.outputs['UV'],separate.inputs[0])
    noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=850 if kind!='ceramic' else 240;noise.inputs['Detail'].default_value=2
    links.new(uv.outputs['UV'],noise.inputs['Vector'])
    x=separate.outputs['X'];y=separate.outputs['Y'];freq=160 if kind=='cloth' else 210
    sx=mathnode(nodes,links,'SINE',mathnode(nodes,links,'MULTIPLY',x,math.tau*freq))
    sy=mathnode(nodes,links,'SINE',mathnode(nodes,links,'MULTIPLY',y,math.tau*freq))
    checkx=mathnode(nodes,links,'FLOOR',mathnode(nodes,links,'MULTIPLY',x,freq))
    checky=mathnode(nodes,links,'FLOOR',mathnode(nodes,links,'MULTIPLY',y,freq))
    alternate=mathnode(nodes,links,'MODULO',mathnode(nodes,links,'ADD',checkx,checky),2)
    weave=nodes.new('ShaderNodeMixRGB');links.new(alternate,weave.inputs[0]);links.new(sx,weave.inputs[1]);links.new(sy,weave.inputs[2])
    ridge=mathnode(nodes,links,'MULTIPLY_ADD',noise.outputs['Fac'],.15)
    # MULTIPLY_ADD has an explicit third input; add the selected warp/weft relief.
    links.new(weave.outputs[0],ridge.node.inputs[2])
    height=noise.outputs['Fac'] if kind=='ceramic' else ridge
    strength=mathnode(nodes,links,'MULTIPLY_ADD',height,.045 if kind=='ceramic' else .07)
    strength.node.inputs[2].default_value=.96
    source=nodes.new('ShaderNodeTexImage');source.image=bpy.data.images.load(str(path));source.interpolation='Cubic';links.new(uv.outputs['UV'],source.inputs[0])
    color=nodes.new('ShaderNodeMixRGB');color.blend_type='MULTIPLY';color.inputs[0].default_value=1;links.new(source.outputs[0],color.inputs[1]);links.new(strength,color.inputs[2])
    rough=mathnode(nodes,links,'MULTIPLY_ADD',height,.04 if kind=='ceramic' else .09);rough.node.inputs[2].default_value=.68 if kind=='ceramic' else .77
    bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.32 if kind=='ceramic' else .4;bump.inputs['Distance'].default_value=.00012 if kind=='ceramic' else .0007;links.new(height,bump.inputs['Height'])
    shader=nodes.new('ShaderNodeBsdfPrincipled');links.new(bump.outputs[0],shader.inputs['Normal'])
    files=[]
    for channel in ['BaseColor','Roughness','Normal']:
        im=bpy.data.images.new(name+'_'+channel+'_4K',width=4096,height=4096,alpha=False)
        if channel!='BaseColor':im.colorspace_settings.name='Non-Color'
        target=nodes.new('ShaderNodeTexImage');target.image=im;nodes.active=target
        if channel=='Normal':
            links.new(shader.outputs[0],output.inputs['Surface']);bpy.ops.object.bake(type='NORMAL',normal_space='TANGENT')
        else:
            links.new(emit.outputs[0],output.inputs['Surface']);links.new(color.outputs[0] if channel=='BaseColor' else rough,emit.inputs[0]);bpy.ops.object.bake(type='EMIT')
        file=OUT/(name+'_'+channel+'_4K.png');im.filepath_raw=str(file);im.file_format='PNG';im.save();files.append(file.name)
        nodes.remove(target);bpy.data.images.remove(im)
        print('CHARACTER_4K_BAKED',file.name,flush=True)
    report[name]={'source':str(path.relative_to(ROOT)),'resolution':[4096,4096],'maps':files,'detail':'Native shader warp/weft, fine fibre relief' if kind!='ceramic' else 'Native shader fine ceramic surface relief'}
    source.image.pack()
(WORK/'material_bake_report.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ArtSource/BlueBiome/Characters/Character_Materials_v2.blend'),compress=True)
