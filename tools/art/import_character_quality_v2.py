"""Externalize shared v2 maps; import only approved character assets headlessly."""
from pathlib import Path
import json,struct,hashlib,re,shutil,sys,os
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'work/character-quality-v2';SANDBOX=WORK/'import_project';SHARED=ROOT/'Assets/BlueBiome/Characters/SharedTexturesV2'
MODE=sys.argv[1]
FAMILIES=['Assets/BlueBiome/Villagers','Assets/BlueBiome/Enemies/EaveRunner','Assets/BlueBiome/Enemies/LoomHeron','Assets/BlueBiome/Characters/SharedTexturesV2']
MODELS=[ROOT/'Assets/BlueBiome/Villagers/Models/NetMender_v2.glb',ROOT/'Assets/BlueBiome/Villagers/Models/Boatwright_v2.glb',ROOT/'Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v2.glb',ROOT/'Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v2.glb']
if MODE=='package':
    known={}
    for folder in FAMILIES:
        for p in (ROOT/folder).rglob('*.png'):known[hashlib.sha256(p.read_bytes()).hexdigest()]=p
    factors={}
    for p in ['ArtSource/BlueBiome/Villagers/material_export_factors.json','ArtSource/BlueBiome/Enemies/EaveRunner/material_export_factors.json','ArtSource/BlueBiome/Enemies/LoomHeron/material_export_factors.json']:factors.update(json.loads((ROOT/p).read_text()))
    reports={}
    for path in MODELS:
        raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);blob=raw[28+length:];remove=set();images=[]
        for mat in doc.get('materials',[]):
            name=mat.get('name','');pbr=mat.setdefault('pbrMetallicRoughness',{})
            if name in factors and 'warm skin' not in name:pbr['baseColorFactor']=factors[name]
            if 'warm skin' in name:pbr['baseColorFactor']=[1,1,1,1]
            mat['doubleSided']=True
        if path.stem.startswith('NetMender'):
            doc['animations']=[a for a in doc['animations'] if a['name'] in ['WorkIdle','TalkIdle']]
        elif path.stem.startswith('Boatwright'):
            if any(a['name'].endswith('.001') for a in doc['animations']):
                doc['animations']=[a for a in doc['animations'] if a['name'].endswith('.001')]
                for a in doc['animations']:a['name']=a['name'].removesuffix('.001')
        for im in doc.get('images',[]):
            if 'bufferView' not in im:
                if 'uri' in im:images.append(str((path.parent/im['uri']).resolve().relative_to(ROOT)))
                continue
            i=im.pop('bufferView');v=doc['bufferViews'][i];data=blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];digest=hashlib.sha256(data).hexdigest();target=known.get(digest)
            if target is None:
                name=re.sub('[^A-Za-z0-9_-]','_',im.get('name','Surface'))[:70]+'_'+digest[:10]+'.png';target=SHARED/name;target.write_bytes(data);known[digest]=target
            im['uri']=os.path.relpath(target,path.parent).replace('\\','/');im.pop('mimeType',None);remove.add(i);images.append(str(target.relative_to(ROOT)))
        new=bytearray();views=[];mapping={};hashes=[]
        for index,v in enumerate(doc.get('bufferViews',[])):
            if index in remove:continue
            data=blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];hashes.append(hashlib.sha256(data).hexdigest());new+=b'\0'*((-len(new))%4);mapping[index]=len(views);v=dict(v);v['byteOffset']=len(new);new+=data;views.append(v)
        def remap(x):
            if isinstance(x,dict):
                for k,v in x.items():
                    if k=='bufferView':x[k]=mapping[v]
                    else:remap(v)
            elif isinstance(x,list):
                for v in x:remap(v)
        doc['bufferViews']=views;remap(doc);doc['buffers'][0]['byteLength']=len(new)
        assert hashes==[hashlib.sha256(new[v['byteOffset']:v['byteOffset']+v['byteLength']]).hexdigest() for v in views]
        encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4);new+=b'\0'*((-len(new))%4)
        path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(encoded)+len(new))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(new),0x004e4942)+new)
        reports[path.name]={'bytes':path.stat().st_size,'animations':[a['name'] for a in doc.get('animations',[])],'textures':images,'triangles':sum(doc['accessors'][p['indices']]['count']//3 for mesh in doc['meshes'] for p in mesh['primitives'])}
    (WORK/'runtime_manifest.json').write_text(json.dumps(reports,indent=2));print(json.dumps(reports))
elif MODE=='prepare':
    texture_template=(ROOT/'Assets/BlueBiome/Villagers/Textures/IndigoWorkwear_BaseColor.png.import').read_text()
    for folder in FAMILIES:
        for file in (ROOT/folder).rglob('*'):
            if not file.is_file() or file.suffix not in ['.png','.glb']:continue
            if file.suffix=='.glb' and file not in MODELS:continue
            out=SANDBOX/file.relative_to(ROOT);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,out)
            if file.suffix=='.png':
                old_sidecar=file.with_suffix('.png.import')
                if 'SharedTexturesV2' not in str(file) and old_sidecar.exists():
                    shutil.copy2(old_sidecar,out.with_suffix('.png.import'))
                    for cache_name in set(re.findall(r'res://\.godot/imported/([^"\n]+)',old_sidecar.read_text())):
                        cache=ROOT/'.godot/imported'/cache_name;dest=SANDBOX/'.godot/imported'/cache_name;dest.parent.mkdir(parents=True,exist_ok=True)
                        if cache.exists():shutil.copy2(cache,dest)
                        md5=cache.with_suffix('.md5')
                        if md5.exists():shutil.copy2(md5,dest.with_suffix('.md5'))
                    continue
                text=re.sub(r'^uid=.*\n','',texture_template,flags=re.M);uri='res://'+file.relative_to(ROOT).as_posix();cache=file.name+'-'+hashlib.md5(uri.encode()).hexdigest()+'.bptc.ctex'
                text=re.sub(r'res://\.godot/imported/[^"\n]+','res://.godot/imported/'+cache,text);text=re.sub(r'^source_file=.*$','source_file="'+uri+'"',text,flags=re.M)
                if 'normal' in file.name.lower():text=text.replace('compress/normal_map=0','compress/normal_map=1')
                out.with_suffix('.png.import').write_text(text)
            elif file in MODELS:
                old=file.with_name(file.name.replace('_v2','' if 'Villagers' in file.parts else '_v1')).with_suffix('.glb.import')
                text=old.read_text();text=re.sub(r'^uid=.*\n','',text,flags=re.M);uri='res://'+file.relative_to(ROOT).as_posix();cache=file.name+'-'+hashlib.md5(uri.encode()).hexdigest()+'.scn'
                text=re.sub(r'res://\.godot/imported/[^"\n]+','res://.godot/imported/'+cache,text);text=re.sub(r'^source_file=.*$','source_file="'+uri+'"',text,flags=re.M)
                text=text.replace('meshes/generate_lods=true','meshes/generate_lods=false').replace('meshes/force_disable_compression=false','meshes/force_disable_compression=true');out.with_suffix('.glb.import').write_text(text)
    (SANDBOX/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Character V2 isolated import"\nconfig/features=PackedStringArray("4.7", "Forward Plus")\n[threading]\nworker_pool/max_threads=2\n')
    print('CHARACTER_V2_IMPORT_PREPARED')
elif MODE=='install':
    count=0
    for folder in FAMILIES:
        for sidecar in (SANDBOX/folder).rglob('*.import'):
            target=ROOT/sidecar.relative_to(SANDBOX)
            # Only install new model imports and the new common material maps.
            if 'SharedTexturesV2' not in str(target) and '_v2.glb.import' not in target.name:continue
            shutil.copy2(sidecar,target)
            for f in set(re.findall(r'res://\.godot/imported/([^"\n]+)',sidecar.read_text())):
                cache=SANDBOX/'.godot/imported'/f
                if cache.exists():shutil.copy2(cache,ROOT/'.godot/imported'/f);count+=1
                md5=cache.with_suffix('.md5')
                if md5.exists():shutil.copy2(md5,ROOT/'.godot/imported'/md5.name)
    print('CHARACTER_V2_IMPORT_INSTALLED',count)
