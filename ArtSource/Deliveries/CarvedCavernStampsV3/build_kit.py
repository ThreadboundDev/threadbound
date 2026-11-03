"""Measured, monotonic RGB histogram matching. No resampling or alpha changes."""
import hashlib
import importlib.util
import json
from pathlib import Path
import numpy as np
from PIL import Image

KIT=Path(__file__).resolve().parent
ROOT=KIT.parents[2]
REFERENCE=ROOT/'ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack/slate_village_library/stamps/C07_Inset_Cave_Face.png'
SOURCE=KIT.parent/'CarvedCavernStampsV2/generated'

def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value)
    return value

def distribution(values):
    bins,counts=np.unique(values,return_counts=True)
    return bins,np.cumsum(counts,dtype=np.float64)/counts.sum()

def match_channel(source,mask,reference,ref_mask):
    values,quantiles=distribution(source[mask])
    ref_values,ref_quantiles=distribution(reference[ref_mask])
    mapped=np.interp(quantiles,ref_quantiles,ref_values)
    lookup=np.rint(np.interp(np.arange(256),values,mapped)).clip(0,255).astype(np.uint8)
    assert np.all(np.diff(lookup.astype(int))>=0)
    return lookup,lookup[source]

def build():
    ref=np.asarray(Image.open(REFERENCE).convert('RGBA'))
    ref_mask=ref[:,:,3]>240
    (KIT/'generated').mkdir(exist_ok=True)
    records=[]
    for path in sorted(SOURCE.glob('*.png'),key=lambda p:('SML'.index(p.stem[0]),p.stem)):
        source=np.asarray(Image.open(path).convert('RGBA'))
        mask=source[:,:,3]>240
        output=source.copy()
        curves=[]
        for channel in range(3):
            lookup,corrected=match_channel(source[:,:,channel],mask,ref[:,:,channel],ref_mask)
            output[:,:,channel]=np.where(source[:,:,3]>0,corrected,source[:,:,channel])
            curves.append(lookup.tolist())
        target=KIT/'generated'/path.name
        Image.fromarray(output).save(target)
        saved=np.asarray(Image.open(target).convert('RGBA'))
        assert source.shape==saved.shape
        assert np.array_equal(source[:,:,3],saved[:,:,3])
        assert np.array_equal(source[source[:,:,3]==0],saved[source[:,:,3]==0])
        # Check the saved file against the independent per-channel lookup.
        for channel,curve in enumerate(curves):
            expected=np.array(curve,dtype=np.uint8)[source[:,:,channel]]
            assert np.array_equal(saved[:,:,channel][source[:,:,3]>0],expected[source[:,:,3]>0])
        quantiles=[0.1,0.25,0.5,0.75,0.9,0.99]
        ref_q=np.quantile(ref[:,:,:3][ref_mask],quantiles,axis=0)
        old_q=np.quantile(source[:,:,:3][mask],quantiles,axis=0)
        new_q=np.quantile(saved[:,:,:3][mask],quantiles,axis=0)
        old_error=float(np.mean(np.abs(old_q-ref_q)))
        new_error=float(np.mean(np.abs(new_q-ref_q)))
        assert new_error<old_error,path.name
        records.append({'id':path.stem,'source':str(path.relative_to(ROOT)),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'size':list(Image.open(target).size),'alpha_identical':True,'monotonic_channel_curves':True,'quantile_mae_before':old_error,'quantile_mae_after':new_error,'rgb_lookup_tables':curves})
        print(path.stem,round(old_error,2),'->',round(new_error,2),'RGB quantile error; alpha identical')
    report={'method':'Opaque-pixel empirical RGB CDF matching using monotonic 256-entry per-channel lookup tables, round-to-nearest 8-bit. Apply RGB only where alpha > 0. No redraw, resampling, blur, alpha edits or spatial operations.','reference':str(REFERENCE.relative_to(ROOT)),'reference_sha256':hashlib.sha256(REFERENCE.read_bytes()).hexdigest(),'limitations':'Matching channel distributions does not guarantee identical joint RGB palettes or visual acceptance; local joins can still need paint-over. Already painted pixels are not automatically updated.','assets':records}
    (KIT/'color_validation.json').write_text(json.dumps(report,indent=2)+'\n')
    (KIT/'generation_prompts.json').write_text(json.dumps({'tool':'User-authorized deterministic color correction; no new generation','assets':[{'id':r['id']} for r in records]},indent=2)+'\n')
    pack=module('cavern_pack',KIT.parent/'CarvedCavernStampsV1/build_kit.py');pack.KIT=KIT
    pack.build(prefix='Village_Cavern_v3_',display_prefix='Village Cavern v3 ',bundle_name='Threadbound_Carved_Cavern_v3',tag='Cavern - Carved Walkways v3')
    # Reuse the tested compatibility validator against the current revision.
    import io,zipfile,xml.etree.ElementTree as ET
    mirror=module('existing_mirror',ROOT/'ArtSource/RecoveredLocal/BlueBiome Painting Workspace/outputs/blue_village_stamp_pack/slate_village_library/krita_plugin/pykrita/village_stamp_controls/mirror.py')
    checks=0
    with zipfile.ZipFile(KIT/'Threadbound_Carved_Cavern_v3.bundle') as z:
        for name in z.namelist():
            if not name.endswith('.kpp'):continue
            xml=Image.open(io.BytesIO(z.read(name))).info['preset']
            assert mirror.supported(xml)
            for x,y in [(True,False),(False,True),(True,True),(False,False)]:
                changed=mirror.set_mirror(xml,x,y)
                assert mirror.state(changed)==(x,y)
                before=mirror.params(ET.fromstring(xml));after=mirror.params(ET.fromstring(changed))
                for key,value in before.items():
                    if key not in (mirror.H,mirror.V,'PressureMirror','MirrorUseCurve','MirrorValue'):assert after[key].text==value.text
                checks+=1
    assert checks==24
    (KIT/'flip_validation.json').write_text(json.dumps({'presets':6,'flip_cases':checks,'result':'all pass'},indent=2)+'\n')

if __name__=='__main__':build()
