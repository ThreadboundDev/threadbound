"""Render 2x gameplay resolution and package isolated Godot test atlases."""
import sys,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'ArtSource/Player/Blender/imported_character/mixamo_test'
DEST=ROOT/'Assets/Threadborne/Player/EquippedTest'
EXPORT=SOURCE/('godot_export_30fps' if '--30fps' in sys.argv or '--pack' in sys.argv else 'godot_export')
DEST.mkdir(parents=True,exist_ok=True)
if '--pack' in sys.argv:
    from PIL import Image,ImageEnhance,ImageFilter
    manifest=json.loads((EXPORT/'manifest.json').read_text())
    resources=[];animations=[];ext=[];n=0
    for label in ['idle','run','jump']:
        items=[x for x in manifest if x['clip']==label]
        atlas=Image.new('RGBA',(450*6,600*math.ceil(len(items)/6)))
        refs=[]
        for i,item in enumerate(items):
            with Image.open(EXPORT/item['file']) as source_image:
                im=source_image.convert('RGBA')
                # Pull the sprite out of the washed midrange while preserving its alpha.
                alpha=im.getchannel('A')
                rgb=Image.new('RGB',im.size);rgb.paste(im.convert('RGB'),mask=alpha)
                rgb=ImageEnhance.Brightness(rgb).enhance(.88)
                rgb=ImageEnhance.Contrast(rgb).enhance(1.08)
                rgb=ImageEnhance.Color(rgb).enhance(1.04)
                im=rgb.convert('RGBA');im.putalpha(alpha)
                # Four source pixels become two pixels after the test scene's 0.5 scale.
                expanded=alpha.filter(ImageFilter.MaxFilter(9))
                outline=Image.new('RGBA',im.size,(15,12,12,0));outline.putalpha(expanded)
                im=Image.alpha_composite(outline,im)
                atlas.paste(im,(i%6*450,i//6*600))
            n+=1;ident=f'Atlas_{n}';refs.append(ident)
            resources.append(f'[sub_resource type="AtlasTexture" id="{ident}"]\natlas = ExtResource("{label}")\nregion = Rect2({i%6*450}, {i//6*600}, 450, 600)\nfilter_clip = true\n')
        atlas.save(DEST/(label+'.png'))
        ext.append(f'[ext_resource type="Texture2D" path="res://Assets/Threadborne/Player/EquippedTest/{label}.png" id="{label}"]')
        def anim(name,ids,loop,speed):
            frames=', '.join('{"duration": 1.0, "texture": SubResource("'+ident+'")}' for ident in ids)
            animations.append('{"frames": ['+frames+'], "loop": '+str(loop).lower()+', "name": &"'+name+'", "speed": '+str(speed)+'}')
        anim(label,refs,label!='jump',30.0)
        if label=='jump':
            anim('ascent',refs[0:10],False,30.0)
            anim('apex',refs[10:15],True,30.0)
            anim('descent',refs[15:23],False,30.0)
            anim('land',refs[23:],False,30.0)
    output=ROOT/'Src/Tests/EquippedPlayer/equipped_frames.tres';output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text('[gd_resource type="SpriteFrames" load_steps='+str(n+4)+' format=3]\n\n'+'\n'.join(ext)+'\n\n'+'\n'.join(resources)+'\n[resource]\nanimations = ['+',\n'.join(animations)+']\n')
    print('GODOT_ATLASES_READY',len(manifest),flush=True)
else:
    import bpy
    from mathutils import Vector
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'Threadborne_Equipped_Animation_Test.blend'))
    scene=bpy.context.scene;rig=bpy.data.objects['Threadborne_Rig'];cam=scene.camera
    scene.render.resolution_x=900;scene.render.resolution_y=1200;scene.render.resolution_percentage=50;scene.cycles.samples=8
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
    # Approved look-dev treatment 3, reduced from the bright comparison pass.
    existing=next((o for o in scene.objects if o.type=='LIGHT'),None)
    if existing:
        existing.data.energy=500;existing.data.color=(.48,.64,1.0);existing.data.shadow_soft_size=2.0
    def area(name,location,energy,color,size):
        data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.color=color;data.shape='DISK';data.size=size
        ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=location
        ob.rotation_euler=(Vector((0,0,1.15))-ob.location).to_track_quat('-Z','Y').to_euler()
    area('Game_Warm_Key',(-3.8,-3.2,4.2),780,(1.0,.63,.38),3.2)
    area('Game_Cool_Fill',(-2.8,3.0,2.1),260,(.42,.62,1.0),4.0)
    area('Game_Mask_Kicker',(-2.2,-.2,2.7),150,(1.0,.87,.64),1.3)
    if scene.world:
        scene.world.use_nodes=True;bg=next((n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND'),None)
        if bg:bg.inputs['Color'].default_value=(.015,.022,.030,1);bg.inputs['Strength'].default_value=.09
    try:
        scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast'
    except Exception:pass
    scene.view_settings.exposure=.15
    for mat in bpy.data.materials:
        if not mat or not mat.use_nodes or not mat.name.startswith('Threadborne_Costume_Material'):continue
        p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if not p or not p.inputs['Base Color'].is_linked:continue
        link=p.inputs['Base Color'].links[0];source=link.from_socket
        lift=mat.node_tree.nodes.new('ShaderNodeMixRGB');lift.blend_type='SCREEN';lift.inputs[0].default_value=.09;lift.inputs[2].default_value=(.06,.048,.04,1)
        mat.node_tree.links.remove(link);mat.node_tree.links.new(source,lift.inputs[1]);mat.node_tree.links.new(lift.outputs[0],p.inputs['Base Color'])
    origin=cam.location.copy();frames=EXPORT;frames.mkdir(exist_ok=True)
    manifest=[];report=json.loads((SOURCE/'animation_test_report.json').read_text())
    rest_z=rig.data.bones['pelvis'].head_local.z
    for clip in ['Idle','Run','Jump']:
        start,end=report[clip]['timeline'];count=end-start+1
        for i in range(count):
            frame=start+i;scene.frame_set(frame)
            # Godot supplies the ballistic travel. Retain below-rest crouch but strip airborne lift.
            lift=max(0.0,rig.pose.bones['pelvis'].head.z-rest_z) if clip=='Jump' else 0.0
            cam.location=origin+Vector((0,0,lift))
            name=f'{clip.lower()}_{i:03d}.png';scene.render.filepath=str(frames/name);bpy.ops.render.render(write_still=True)
            manifest.append({'clip':clip.lower(),'file':name,'frame':frame,'removed_vertical_travel_m':lift,'clip_duration':(end-start+1)/30,'fps':30})
        print('GODOT_CLIP_READY',clip,count,flush=True)
    (frames/'manifest.json').write_text(json.dumps(manifest,indent=2))
