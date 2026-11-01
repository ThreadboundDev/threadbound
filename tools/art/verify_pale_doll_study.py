"""Independently inspect the saved glTF payload, without opening a live editor."""
from pathlib import Path
import hashlib
import json
import math
import struct

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/pale-doll-study-2026-11-01'
SOURCE=ROOT/'Assets/Threadborne/Player/Equipped3DTest/threadborne_equipped_combat_swings.glb'
EXPORT=ROOT/'ArtSource/Player/Blender/PaleDollStudy/Threadborne_Pale_Doll_Study_v2.glb'


def glb(path):
    raw=path.read_bytes()
    magic,version,total=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and total==len(raw)
    offset=12
    document=None
    binary=b''
    while offset<len(raw):
        size,kind=struct.unpack_from('<II',raw,offset)
        offset+=8
        data=raw[offset:offset+size]
        offset+=size
        if kind==0x4e4f534a:
            document=json.loads(data)
        elif kind==0x004e4942:
            binary=data
    return document,binary


def values(doc,binary,index):
    accessor=doc['accessors'][index]
    view=doc['bufferViews'][accessor['bufferView']]
    fmt={5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'}[accessor['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[accessor['type']]
    size=struct.calcsize(fmt)*count
    stride=view.get('byteStride',size)
    start=view.get('byteOffset',0)+accessor.get('byteOffset',0)
    result=[struct.unpack_from('<'+fmt*count,binary,start+i*stride) for i in range(accessor['count'])]
    if accessor.get('normalized') and fmt!='f':
        maximum={5121:255,5123:65535}[accessor['componentType']]
        result=[tuple(v/maximum for v in row) for row in result]
    return result


def multiply(a,b):
    return [[sum(a[i][k]*b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def world_matrices(doc):
    parents={child:i for i,n in enumerate(doc['nodes']) for child in n.get('children',[])}
    cache={}
    def world(i):
        if i in cache:
            return cache[i]
        node=doc['nodes'][i]
        if 'matrix' in node:
            m=[[node['matrix'][4*j+i] for j in range(4)] for i in range(4)]
        else:
            x,y,z,w=node.get('rotation',[0,0,0,1])
            s=node.get('scale',[1,1,1])
            t=node.get('translation',[0,0,0])
            m=[[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w,t[0]],
               [2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w,t[1]],
               [2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y,t[2]],
               [0,0,0,1]]
            for row in range(3):
                for col in range(3):
                    m[row][col]*=s[col]
        cache[i]=multiply(world(parents[i]),m) if i in parents else m
        return cache[i]
    return {doc['nodes'][i]['name']:world(i) for i in doc['skins'][0]['joints']}


source,sbin=glb(SOURCE)
export,ebin=glb(EXPORT)
checks=[]
def check(name,passed,detail=None):
    checks.append({'name':name,'passed':bool(passed),'detail':detail})
    if not passed:
        raise AssertionError(name+': '+str(detail))

check('single exported skin',len(export.get('skins',[]))==1)
original_joints={source['nodes'][i]['name'] for i in source['skins'][0]['joints']}
new_joints={export['nodes'][i]['name'] for i in export['skins'][0]['joints']}
check('same 62 named joints',original_joints==new_joints and len(new_joints)==62)
original_rest=world_matrices(source)
new_rest=world_matrices(export)
max_rest_error=max(abs(original_rest[n][i][j]-new_rest[n][i][j]) for n in original_rest for i in range(4) for j in range(4))
check('exported joint world rest transforms agree',max_rest_error<1e-5,max_rest_error)
source_actions={a['name']:a for a in source.get('animations',[])}
export_actions={a['name']:a for a in export.get('animations',[])}
check('same 48 animation names',source_actions.keys()==export_actions.keys() and len(export_actions)==48)
def duration(doc,binary,animation):
    times=[v[0] for s in animation['samplers'] for v in values(doc,binary,s['input'])]
    return max(times)-min(times)
duration_differences={n:abs(duration(source,sbin,source_actions[n])-duration(export,ebin,export_actions[n])) for n in source_actions}
check('animation duration drift below one 24fps frame',max(duration_differences.values())<=1/24+1e-4,max(duration_differences.values()))
check('one joined body mesh',len(export.get('meshes',[]))==1)
check('only four body materials',len(export.get('materials',[]))==4)
check('no exported studio camera or lights',not export.get('cameras') and 'KHR_lights_punctual' not in export.get('extensions',{}))
vertices=0
for i,primitive in enumerate(export['meshes'][0]['primitives']):
    weights=values(export,ebin,primitive['attributes']['WEIGHTS_0'])
    points=values(export,ebin,primitive['attributes']['POSITION'])
    vertices+=len(points)
    check('primitive %d has finite positions'%i,all(math.isfinite(v) for row in points for v in row))
    check('primitive %d keeps rigid normalized weights'%i,all(sum(v>1e-6 for v in row)==1 and abs(sum(row)-1)<1e-6 for row in weights))
check('source costume geometry absent',vertices<100000,vertices)
report=json.loads((WORK/'body_test_report.json').read_text())
check('production source hash unchanged since build',hashlib.sha256(SOURCE.read_bytes()).hexdigest()==report['source_sha256'])
report={'checks':checks,'animation_duration_differences_seconds':duration_differences,'export_sha256':hashlib.sha256(EXPORT.read_bytes()).hexdigest(),'export_vertices':vertices}
(WORK/'export_verification.json').write_text(json.dumps(report,indent=2))
print('PALE_DOLL_EXPORT_VERIFIED',len(checks),'checks')
