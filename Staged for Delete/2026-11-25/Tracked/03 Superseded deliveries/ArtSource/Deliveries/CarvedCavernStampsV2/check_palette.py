"""Compare opaque stone chroma at equal brightness; this does not edit pixels."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

KIT=Path(__file__).resolve().parent
ROOT=KIT.parents[2]
BINS=[(20,55),(55,85),(85,115),(115,145),(145,180),(180,230)]

def palette(path):
    pixels=np.asarray(Image.open(path).convert('RGBA'))
    brightness=np.mean(pixels[:,:,:3],axis=2)
    return np.array([np.median(pixels[(pixels[:,:,3]>240)&(brightness>=low)&(brightness<high),:3],axis=0) for low,high in BINS])

def main():
    reference=palette(ROOT/'ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack/slate_village_library/stamps/C07_Inset_Cave_Face.png')
    chroma=lambda values:values-values.mean(axis=1,keepdims=True)
    records=[]
    for path in sorted((KIT/'generated').glob('*.png')):
        old=palette(KIT.parent/'CarvedCavernStampsV1/generated'/path.name)
        new=palette(path)
        error=lambda values:float(np.mean(np.linalg.norm(chroma(values)-chroma(reference),axis=1)))
        records.append({'id':path.stem,'v1_mean_chroma_error':error(old),'v2_mean_chroma_error':error(new),'v2_band_medians':new.tolist()})
    report={'reference':'C07_Inset_Cave_Face','brightness_bands':BINS,'reference_band_medians':reference.tolist(),'metric':'Mean Euclidean RGB chroma distance between opaque-pixel medians in equal brightness bands; lower is closer. Diagnostic, not proof of an exact palette match.','assets':records}
    (KIT/'palette_validation.json').write_text(json.dumps(report,indent=2)+'\n')
    for r in records:print(r['id'],round(r['v1_mean_chroma_error'],2),'->',round(r['v2_mean_chroma_error'],2))

if __name__=='__main__':main()
