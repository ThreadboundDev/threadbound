import bpy,json
from pathlib import Path
root=Path('C:/Users/chase/Documents/threadbound')
source=root/'ArtSource/BlueBiome/Villagers/LakesideVillagers_v1.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
images=[]
for image in bpy.data.images:
    if image.source!='FILE':continue
    path=Path(bpy.path.abspath(image.filepath))
    before=bool(image.packed_file)
    if not before and path.exists():image.pack()
    images.append({'name':image.name,'packed':bool(image.packed_file),'bytes':len(image.packed_file.data) if image.packed_file else 0,'path':str(path),'size':list(image.size)})
assert all(i['packed'] for i in images),images
bpy.ops.wm.save_as_mainfile(filepath=str(source),compress=True)
report={'packed_images':images,'packed_image_bytes':sum(i['bytes'] for i in images),'source_bytes':source.stat().st_size,'scenes':[s.name for s in bpy.data.scenes]}
(root/'work/lakeside-villagers/source-verification.json').write_text(json.dumps(report,indent=2))
print('VILLAGER_SOURCE_VERIFIED',json.dumps({k:v for k,v in report.items() if k!='packed_images'}))
