"""Package/import only the new Eave Runner art, without opening the project editor."""
from pathlib import Path
import json,struct,hashlib,shutil,sys,re
ROOT=Path(__file__).resolve().parents[2]
ASSET=ROOT/'Assets/BlueBiome/Enemies/EaveRunner'
SOURCE=ROOT/'ArtSource/BlueBiome/Enemies/EaveRunner'
SANDBOX=ROOT/'work/eave-runner/import_project'
REL=ASSET.relative_to(ROOT)
mode=sys.argv[1]
if mode=='package':
    factors=json.loads((SOURCE/'material_export_factors.json').read_text());report={}
    known={hashlib.sha256(p.read_bytes()).hexdigest():p.name for p in (ASSET/'Textures').glob('*.png')}
    for path in (ASSET/'Models').glob('*.glb'):
        raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);blob=raw[28+length:]
        remove=set();names=[]
        for mat in doc.get('materials',[]):
            if mat.get('name') in factors:mat.setdefault('pbrMetallicRoughness',{})['baseColorFactor']=factors[mat['name']]
        for image in doc.get('images',[]):
            if 'bufferView' not in image:
                names.append(Path(image['uri']).name);continue
            index=image.pop('bufferView');v=doc['bufferViews'][index];start=v.get('byteOffset',0);data=blob[start:start+v['byteLength']]
            digest=hashlib.sha256(data).hexdigest();name=known.get(digest)
            if name is None:
                name=re.sub('[^A-Za-z0-9_-]','_',image.get('name','Surface'))[:60]+'_'+digest[:10]+'.png'
                (ASSET/'Textures'/name).write_bytes(data);known[digest]=name
            names.append(name);image['uri']='../Textures/'+name;image.pop('mimeType',None);remove.add(index)
        new=bytearray();views=[];mapping={};hashes=[]
        for index,v in enumerate(doc.get('bufferViews',[])):
            if index in remove:continue
            data=blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];hashes.append(hashlib.sha256(data).hexdigest())
            new+=b'\0'*((-len(new))%4);mapping[index]=len(views);v=dict(v);v['byteOffset']=len(new);new.extend(data);views.append(v)
        def remap(value):
            if isinstance(value,dict):
                for k,v in value.items():
                    if k=='bufferView':value[k]=mapping[v]
                    else:remap(v)
            elif isinstance(value,list):
                for v in value:remap(v)
        doc['bufferViews']=views;remap(doc);doc['buffers'][0]['byteLength']=len(new)
        assert hashes==[hashlib.sha256(new[v['byteOffset']:v['byteOffset']+v['byteLength']]).hexdigest() for v in views]
        encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4);new+=b'\0'*((-len(new))%4)
        path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(encoded)+len(new))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(new),0x004e4942)+new)
        report[path.name]={'bytes':path.stat().st_size,'textures':names,'animations':[a['name'] for a in doc.get('animations',[])],'materials':len(doc.get('materials',[]))}
    (ASSET/'asset_manifest.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
elif mode=='prepare':
    template=(ROOT/'Assets/BlueBiome/Villagers/Textures/IndigoWorkwear_BaseColor.png.import').read_text()
    for file in ASSET.rglob('*'):
        if not file.is_file() or file.suffix in ['.import','.uid']:continue
        out=SANDBOX/REL/file.relative_to(ASSET);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,out)
        if file.suffix=='.png' and not out.with_suffix('.png.import').exists():
            uri='res://'+out.relative_to(SANDBOX).as_posix();cache=file.name+'-'+hashlib.md5(uri.encode()).hexdigest()+'.bptc.ctex'
            text=re.sub(r'^uid=.*\n','',template,flags=re.M)
            text=re.sub(r'res://\.godot/imported/[^"\n]+','res://.godot/imported/'+cache,text)
            text=re.sub(r'^source_file=.*$', 'source_file="'+uri+'"',text,flags=re.M)
            if 'normal' in file.name.lower():text=text.replace('compress/normal_map=0','compress/normal_map=1')
            out.with_suffix('.png.import').write_text(text)
    (SANDBOX/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Eave Runner isolated import"\nconfig/features=PackedStringArray("4.7", "Forward Plus")\n[threading]\nworker_pool/max_threads=2\n')
    print('EAVE_RUNNER_IMPORT_PREPARED')
elif mode=='install':
    count=0
    for sidecar in (SANDBOX/REL).rglob('*.import'):
        target=ROOT/sidecar.relative_to(SANDBOX);shutil.copy2(sidecar,target)
        for filename in set(re.findall(r'res://\.godot/imported/([^"\n]+)',sidecar.read_text())):
            cache=SANDBOX/'.godot/imported'/filename
            if cache.exists():shutil.copy2(cache,ROOT/'.godot/imported'/filename);count+=1
            md5=cache.with_suffix('.md5')
            if md5.exists():shutil.copy2(md5,ROOT/'.godot/imported'/md5.name)
    print('EAVE_RUNNER_IMPORT_INSTALLED',count)
