"""Render actual asset meshes; no painted embellishment is added."""
import bpy, sys, os, tempfile
from pathlib import Path
from mathutils import Vector
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
OUT=ROOT/'outputs/lakeside-buildings-v1'
tempfile.tempdir=str(OUT/'source/build-temp');os.environ['TEMP']=tempfile.tempdir;os.environ['TMP']=tempfile.tempdir
bpy.ops.wm.open_mainfile(filepath=str(OUT/'LakesideBuildings_Editable.blend'))
draft='draft' in sys.argv
house_only='house_only' in sys.argv
def facade(key,show):
    col=bpy.data.collections.get(key+'__02_Facade_Removable')
    if col:
        for ob in col.all_objects:
            if ob is not None:ob.hide_render=not show
def render(scene,filename,loc=None,target=None,scale=None,w=1400,h=1100,full=True,key=None):
    sc=bpy.data.scenes[scene];bpy.context.window.scene=sc
    if key:facade(key,full)
    cam=sc.camera
    if loc:
        cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
    sc.render.resolution_x=w;sc.render.resolution_y=h;sc.render.resolution_percentage=100
    sc.cycles.samples=12 if draft else 32
    sc.render.filepath=str(OUT/'previews'/filename)
    bpy.ops.render.render(write_still=True)
    print('RENDER_READY',filename,flush=True)
    if key:facade(key,True)

if house_only:
    render('03 · Fisher house','fishers_house_exterior.png',(10,-19,10),(0,0,3.0),8.1,w=1400,h=1450,key='FishersHouse')
    render('03 · Fisher house','fishers_house_cutaway.png',(6,-20,9),(0,0,2.5),7.4,w=1400,h=1450,key='FishersHouse',full=False)
    render('03 · Fisher house','house_cutaway_front.png',(0,-24,2.5),(0,0,2.5),7.5,w=1400,h=1400,key='FishersHouse',full=False)
elif draft:
    render('00 · All three assets','draft_overview.png',w=1320,h=650)
    render('02 · Net workshop','draft_workshop.png',(10,-18,10),(0,0,2.30),9.0,w=1000,h=900,key='NetWorkshop')
else:
    render('00 · All three assets','overview.png',w=2400,h=1120)
    render('01 · Covered boat slip','boat_slip_exterior.png',(11,-20,12),(0,0,3.8),10.6,w=1450,h=1400)
    render('01 · Covered boat slip','boat_slip_front.png',(0,-24,3.8),(0,0,3.8),9.2,w=1450,h=1400)
    render('02 · Net workshop','net_workshop_exterior.png',(10,-18,10),(0,0,2.30),10.7,w=1500,h=1200,key='NetWorkshop')
    render('02 · Net workshop','net_workshop_cutaway.png',(7,-20,9),(0,0,1.9),10.1,w=1500,h=1200,key='NetWorkshop',full=False)
    render('03 · Fisher house','fishers_house_exterior.png',(10,-19,10),(0,0,3.0),8.1,w=1400,h=1450,key='FishersHouse')
    render('03 · Fisher house','fishers_house_cutaway.png',(6,-20,9),(0,0,2.5),7.4,w=1400,h=1450,key='FishersHouse',full=False)
    render('02 · Net workshop','workshop_cutaway_front.png',(0,-24,1.9),(0,0,1.9),8.3,w=1500,h=1100,key='NetWorkshop',full=False)
    render('03 · Fisher house','house_cutaway_front.png',(0,-24,2.5),(0,0,2.5),7.5,w=1400,h=1400,key='FishersHouse',full=False)
print('RENDERS_COMPLETE',flush=True)
