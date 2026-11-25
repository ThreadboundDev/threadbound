"""Package the color-reference revision and verify existing flip-tool support."""
import importlib.util
import io
import json
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from PIL import Image

KIT = Path(__file__).resolve().parent
ROOT = KIT.parents[2]

def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value)
    return value

def build():
    pack=module('cavern_pack',KIT.parent/'CarvedCavernStampsV1/build_kit.py')
    pack.KIT=KIT
    pack.build(prefix='Village_Cavern_v2_',display_prefix='Village Cavern ',bundle_name='Threadbound_Carved_Cavern_v2',tag='Cavern - Carved Walkways v2')
    mirror=module('existing_mirror',ROOT/'ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack/slate_village_library/krita_plugin/pykrita/village_stamp_controls/mirror.py')
    checks=0
    with zipfile.ZipFile(KIT/'Threadbound_Carved_Cavern_v2.bundle') as z:
        for name in z.namelist():
            if not name.endswith('.kpp'):continue
            xml=Image.open(io.BytesIO(z.read(name))).info['preset']
            assert mirror.supported(xml),name
            original=ET.fromstring(xml)
            for horizontal,vertical in [(True,False),(False,True),(True,True),(False,False)]:
                changed=mirror.set_mirror(xml,horizontal,vertical)
                assert mirror.state(changed)==(horizontal,vertical)
                params=mirror.params(ET.fromstring(changed))
                for p in original.findall('param'):
                    if p.get('name') not in (mirror.H,mirror.V,'PressureMirror','MirrorUseCurve','MirrorValue'):
                        assert params[p.get('name')].text==p.text
                checks+=1
    (KIT/'flip_validation.json').write_text(json.dumps({'presets':6,'flip_cases':checks,'result':'all pass; existing plugin accepts all names; brush/color/size/angle/opacity parameters preserved'},indent=2)+'\n')
    print(f'Existing flip plugin: {checks} checks passed.')

if __name__=='__main__':build()
