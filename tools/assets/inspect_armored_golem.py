"""Inspect the downloaded Fab golem without installing or publishing source assets.

Prepare ignored working copies for a local Blender review, record hashes/contents,
and read TGA dimensions without expanding the complete 2.6 GB texture library.
"""
import hashlib
import json
from pathlib import Path, PurePosixPath
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT/'work/armored-golem-review-2026-10-28'
DOWNLOADS = Path('C:/Users/chase/Downloads')
LICENSE = Path('C:/Users/chase/.codex/attachments/6c1f7881-e3f1-435b-86ce-f5ade19ffae4/Pasted text.txt')


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK/'.gdignore').write_bytes(b'')
    report = dict(listing='https://www.fab.com/listings/e40713f0-ebea-4f4d-ad9b-b577db4432d5',
                  supplied_license_sha256=hashlib.sha256(LICENSE.read_bytes()).hexdigest(),
                  archives=[], textures=[])
    for name in ('mesh.zip','animations.zip','textures.zip','armored_stone_golem_unity.unitypackage'):
        path = DOWNLOADS/name
        with path.open('rb') as stream:
            sha = hashlib.file_digest(stream,'sha256').hexdigest()
        pack = dict(filename=name,bytes=path.stat().st_size,sha256=sha)
        if name.endswith('.zip'):
            with zipfile.ZipFile(path) as archive:
                assert archive.testzip() is None, name
                files = [x for x in archive.infolist() if not x.is_dir()]
                pack.update(file_count=len(files),expanded_bytes=sum(x.file_size for x in files),crc='pass',
                            files=[dict(path=x.filename,bytes=x.file_size) for x in files])
                for member in files:
                    p = PurePosixPath(member.filename)
                    assert not p.is_absolute() and '..' not in p.parts and '\\' not in member.filename
                    selected = (name in ('mesh.zip','animations.zip') and p.suffix.lower()=='.fbx')
                    if name=='textures.zip':
                        with archive.open(member) as stream:
                            header=stream.read(18)
                        width,height,bits=struct.unpack_from('<HHB',header,12)
                        report['textures'].append(dict(path=member.filename,width=width,height=height,bits_per_pixel=bits))
                        selected = '_Albedo_Skin1.' in member.filename or '_Roughness.' in member.filename or member.filename.endswith('_Metallic.tga')
                    if selected:
                        dest=WORK/'temp/source'/member.filename
                        dest.parent.mkdir(parents=True,exist_ok=True)
                        dest.write_bytes(archive.read(member))
        else:
            pack['inspection']='Hash/size only; Unity package not executed or installed.'
        report['archives'].append(pack)
        print(name,pack['bytes'],'bytes',flush=True)
    (WORK/'source_inventory.json').write_bytes((json.dumps(report,indent=2)+'\n').encode())
    print('GOLEM_INVENTORY_COMPLETE')


if __name__=='__main__':
    main()
