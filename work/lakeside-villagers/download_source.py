from pathlib import Path
import urllib.request,json
folder=Path(__file__).resolve().parent/'source';folder.mkdir(parents=True,exist_ok=True)
base='https://raw.githubusercontent.com/makehumancommunity/makehuman/master/'
request=urllib.request.Request('https://api.github.com/repos/makehumancommunity/makehuman/git/trees/master?recursive=1',headers={'User-Agent':'Threadbound-asset-preparation'})
tree=json.load(urllib.request.urlopen(request,timeout=40));(folder/'tree.json').write_text(json.dumps(tree))
paths=[e['path'] for e in tree.get('tree',[])]
license_paths=[p for p in paths if 'LICENSE' in p and p.count('/')==0]
for rel in ['makehuman/data/3dobjs/base.obj']+license_paths:
    data=urllib.request.urlopen(base+rel,timeout=40).read();(folder/Path(rel).name).write_bytes(data);print('DOWNLOADED',rel,len(data))
for path in paths:
    if (path.endswith('.target') and any(s in path for s in ['female-young','male-young','male-old','asian','head-age','smile','eyelid'])) or ('data/eyes/' in path and path.endswith(('.obj','.mhmat','.png','.mhclo'))) or path in license_paths:
        print(path)
