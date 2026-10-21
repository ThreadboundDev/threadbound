"""Externalize task-owned GLB images and import only these assets in isolation."""
from pathlib import Path
import json,struct,hashlib,re,shutil,sys
ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/'Assets/BlueBiome/Villagers'
SANDBOX=ROOT/'work/lakeside-villagers/import_project'
mode=sys.argv[1]
if mode=='package':
    report={};seen={}
    factors=json.loads((ROOT/'ArtSource/BlueBiome/Villagers/material_export_factors.json').read_text())
    for file in (ASSETS/'Textures').glob('*.png'):seen[hashlib.sha256(file.read_bytes()).hexdigest()]=file.name
    for path in sorted((ASSETS/'Models').glob('*.glb')):
        raw=path.read_bytes();jlen,jtype=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+jlen]);blen,btype=struct.unpack_from('<II',raw,20+jlen);blob=raw[28+jlen:28+jlen+blen]
        images_to_remove=set();image_names=[];animation_changed=False
        material_changed=False
        for material in doc.get('materials',[]):
            name=material.get('name','')
            if name in factors and 'warm skin' not in name:
                pbr=material.setdefault('pbrMetallicRoughness',{})
                if pbr.get('baseColorFactor')!=factors[name]:
                    pbr['baseColorFactor']=factors[name];material_changed=True
        if path.stem=='Boatwright' and any(a.get('name','').endswith('.001') for a in doc.get('animations',[])):
            doc['animations']=[a for a in doc['animations'] if a.get('name','').endswith('.001')]
            for a in doc['animations']:a['name']=a['name'].removesuffix('.001')
            animation_changed=True
        for image in doc.get('images',[]):
            if 'bufferView' not in image:
                if 'uri' in image:image_names.append(Path(image['uri']).name)
                continue
            index=image['bufferView'];view=doc['bufferViews'][index];start=view.get('byteOffset',0);data=blob[start:start+view['byteLength']]
            digest=hashlib.sha256(data).hexdigest();ext='.png' if image.get('mimeType')=='image/png' else '.jpg'
            name=seen.get(digest)
            if not name:
                slug=re.sub('[^a-zA-Z0-9_-]+','_',image.get('name','Surface')).strip('_')[:70]
                name=slug+'_'+digest[:10]+ext
                (ASSETS/'Textures'/name).write_bytes(data);seen[digest]=name
            images_to_remove.add(index);image_names.append(name)
            image.pop('bufferView');image.pop('mimeType',None);image['uri']='../Textures/'+name
        if images_to_remove or animation_changed or material_changed:
            new_blob=bytearray();views=[];mapping={};before=[]
            for i,view in enumerate(doc['bufferViews']):
                if i in images_to_remove:continue
                before.append(hashlib.sha256(blob[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]).hexdigest())
                while len(new_blob)%4:new_blob.append(0)
                view=dict(view);old=view.get('byteOffset',0);mapping[i]=len(views);view['byteOffset']=len(new_blob)
                new_blob.extend(blob[old:old+view['byteLength']]);views.append(view)
            def remap(value):
                if isinstance(value,dict):
                    for k,v in list(value.items()):
                        if k=='bufferView':value[k]=mapping[v]
                        else:remap(v)
                elif isinstance(value,list):
                    for v in value:remap(v)
            doc['bufferViews']=views;remap(doc)
            doc['buffers'][0]['byteLength']=len(new_blob)
            after=[hashlib.sha256(new_blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]).hexdigest() for v in views]
            assert before==after,'Mesh/skin/animation buffer changed'
            encoded=json.dumps(doc,separators=(',',':')).encode()
            encoded+=b' '*((-len(encoded))%4);new_blob+=b'\0'*((-len(new_blob))%4)
            out=struct.pack('<III',0x46546c67,2,28+len(encoded)+len(new_blob))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(new_blob),0x004e4942)+new_blob
            path.write_bytes(out)
        report[path.name]={'bytes':path.stat().st_size,'materials':len(doc.get('materials',[])),'animations':[a.get('name') for a in doc.get('animations',[])],'external_images':image_names}
    (ASSETS/'asset_manifest.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report))
elif mode=='prepare':
    relative=Path('Assets/BlueBiome/Villagers')
    for file in ASSETS.rglob('*'):
        if file.is_file() and file.suffix not in ['.import','.uid']:
            out=SANDBOX/relative/file.relative_to(ASSETS);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,out)
    (SANDBOX/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Villager isolated import"\nconfig/features=PackedStringArray("4.7", "Forward Plus")\n[threading]\nworker_pool/max_threads=2\n')
    print('VILLAGER_IMPORT_PROJECT_READY')
elif mode=='install':
    folder=SANDBOX/'Assets/BlueBiome/Villagers'
    sidecars=list(folder.rglob('*.import'));copied=0
    cache=ROOT/'.godot/imported';cache.mkdir(exist_ok=True)
    for file in sidecars:
        target=ROOT/file.relative_to(SANDBOX);shutil.copy2(file,target)
        for filename in set(re.findall(r'res://\.godot/imported/([^"\n]+)',file.read_text())):
            source=SANDBOX/'.godot/imported'/filename
            if source.exists():shutil.copy2(source,cache/filename);copied+=1
            md5=source.with_suffix('.md5')
            if md5.exists():shutil.copy2(md5,cache/md5.name)
    print('VILLAGER_IMPORTS_INSTALLED',len(sidecars),'CACHES',copied)
