"""Smoke-open the ORA in a separate, offscreen Krita profile and export it."""
import json
import os
import shutil
import subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[2]
kit=root/'ArtSource/BlueBiome/Placeables/BuildingStampsV1'
temp=root/'tmp/building-stamps-native'
temp.mkdir(parents=True,exist_ok=True)
profile=temp/'roaming/krita/bundles'
profile.mkdir(parents=True,exist_ok=True)
shutil.copy2(kit/'Threadbound_Modular_Buildings_v1.bundle',profile/'Threadbound_Modular_Buildings_v1.bundle')
env=os.environ.copy()
env.update(APPDATA=str(temp/'roaming'),LOCALAPPDATA=str(temp/'local'),QT_QPA_PLATFORM='minimal',QT_OPENGL='software')
args=['C:/Program Files/Krita (x64)/bin/krita.exe','--new-instance','--nosplash','--export','--export-filename',str(temp/'native-export.png'),str(kit/'Building_Assembly_Example.ora')]
try:
    r=subprocess.run(args,env=env,capture_output=True,timeout=50,creationflags=subprocess.CREATE_NO_WINDOW)
    (temp/'krita.log').write_bytes(r.stdout+r.stderr)
    result={'returncode':r.returncode,'native_export_exists':(temp/'native-export.png').exists(),'isolated_profile':True,'normal_profile_modified':False}
except subprocess.TimeoutExpired as e:
    (temp/'krita.log').write_bytes((e.stdout or b'')+(e.stderr or b''))
    result={'timed_out':True,'native_export_exists':(temp/'native-export.png').exists(),'isolated_profile':True,'normal_profile_modified':False}
(root/'work/building-stamps-2026-10-31/native-check.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
