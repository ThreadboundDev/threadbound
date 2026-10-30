"""Build analytical figures from the timestamped review frames in task scratch.

Usage: python work/belmont-study-2026-10-30/build_figures.py
Requires Pillow. Raw footage/frames stay in ignored tmp/belmont-study.
This script does not download media or modify game assets.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
FRAMES = OUT.parents[1] / 'tmp/belmont-study'
FONT_PATH = Path('C:/Windows/Fonts/arial.ttf')
FONT = ImageFont.truetype(str(FONT_PATH), 18)
SMALL = ImageFont.truetype(str(FONT_PATH), 15)
BACKGROUND, TEXT, ACCENT = '#151a24', '#f5f4ee', '#ffe29a'

def open_frame(path):
    return Image.open(FRAMES/path).convert('RGB')

def stamp(s):
    return f'{int(s)//3600:02}:{int(s)//60%60:02}:{s%60:05.2f}'

def board(name, panels, cols=2):
    w,h,lh=480,270,49
    rows=(len(panels)+cols-1)//cols
    result=Image.new('RGB',(w*cols,rows*(h+lh)),BACKGROUND)
    draw=ImageDraw.Draw(result)
    for i,(img,label,detail) in enumerate(panels):
        x,y=i%cols*w,i//cols*(h+lh)
        result.paste(img.resize((w,h)),(x,y))
        draw.text((x+10,y+h+5),label,font=FONT,fill=TEXT)
        draw.text((x+10,y+h+27),detail,font=SMALL,fill=TEXT)
    result.save(OUT/name,quality=92)

MEASUREMENTS=[
    {'frame':'paris_early.mp4__combat/00013.jpg','time':452,'label':'Paris / gameplay','box':[383,329,447,395],'uncertainty':4},
    {'frame':'paris_b/00004.jpg','time':915,'label':'The Fallen / gameplay','box':[294,379,330,450],'uncertainty':4},
    {'frame':'cemetery/00011.jpg','time':3389,'label':'Cemetery / gameplay','box':[458,369,507,444],'uncertainty':5},
    {'frame':'library/00048.jpg','time':11995,'label':'Library / gameplay','box':[375,266,420,334],'uncertainty':4},
    {'frame':'paris_a/00005.jpg','time':385,'label':'Paris / dialogue','box':[489,266,543,388],'uncertainty':4},
    {'frame':'library/00035.jpg','time':11930,'label':'Library / dialogue','box':[400,296,450,399],'uncertainty':4},
]
panels=[]
for m in MEASUREMENTS:
    im=open_frame(m['frame'])
    d=ImageDraw.Draw(im)
    d.rectangle(m['box'],outline=ACCENT,width=3)
    body=m['box'][3]-m['box'][1]
    m.update({'image_width':im.width,'image_height':im.height,'body_span_px':body,
              'body_percent_frame_height':round(100*body/im.height,2),
              'screen_width_in_visible_body_spans':round(im.width/body,2)})
    panels.append((im,m['label']+' | ~'+stamp(m['time']),
                   f"Body {body} +/- {m['uncertainty']} px / 540 px = {100*body/im.height:.1f}%"))
board('camera-scale.jpg',panels)

pan_measurements=json.loads((FRAMES/'pan_measurements.json').read_text())
panels=[]
for index,time in [(14,420.5),(15,421.0)]:
    im=open_frame(f'paris_early.mp4__pan/{index:05}.jpg')
    d=ImageDraw.Draw(im)
    for k,m in enumerate(pan_measurements):
        x,y,w,h=m['source_box']
        if index==15:x,y=x+m['dx'],y+m['dy']
        d.rectangle([x,y,x+w,y+h],outline=ACCENT,width=3)
        d.text((x+5,y-22),['G','D','F'][k],font=FONT,fill=ACCENT)
    panels.append((im,'Paris pan | ~'+stamp(time),'G: gameplay door; D: distant gate; F: foreground'))
board('parallax-motion.jpg',panels)

impacts=[]
for time in [8.53,8.57,8.60,8.67,8.73,8.83]:
    idx=round((time-7)*30)+1
    im=open_frame(f'official_impact/{idx:05}.jpg')
    impacts.append((im,'Official trailer | ~'+stamp(7+(idx-1)/30),
                    '30 fps analytical samples from a 60 fps stream'))
board('impact-sequence.jpg',impacts,cols=3)

traversal=[]
for idx in [9,11,13,15]:
    traversal.append((open_frame(f'official_swing/{idx:05}.jpg'),
                      'Official trailer | ~'+stamp(29+(idx-1)/6),
                      'Anchor acquisition -> tether -> swing -> release'))
board('whip-traversal.jpg',traversal)

styles=[
    ('paris_a/00028.jpg','Paris streets',500),
    ('cemetery/00015.jpg','Cemetery',3409),
    ('catacombs/00001.jpg','Catacombs',5580),
    ('library/00007.jpg','Library',11790),
    ('notredame_action/00020.jpg','Notre-Dame',17255),
    ('mirrors/00036.jpg','Hall of Mirrors',24775),
]
board('regional-composition.jpg',[(open_frame(p),label+' | ~'+stamp(t),
      'BeardBear walkthrough; reference imagery, not production art') for p,label,t in styles])

manifest={
 'study_date':'2026-10-30',
 'baseline_commit':'dac26f02',
 'walkthrough':{'url':'https://www.youtube.com/watch?v=q3NuImErog8','creator':'BeardBear',
  'title':"Castlevania: Belmont's Curse 100% Walkthrough - FULL GAME (No Commentary)",
  'duration_seconds':33734,'upload_date':'2026-10-17','format_id':'136','width':1280,'height':720,'fps':30,
  'broad_windows':[
    {'label':n,'start':s,'seconds':d,'review_sample_interval_seconds':5}
    for n,s,d in [('Paris opening',365,300),('Paris boss/reward',900,300),('Cemetery',3339,300),
                  ('Catacombs',5580,300),('Library',11760,300),('Main Hall / Notre-Dame story handoff',16800,300),
                  ('Hall of Mirrors approach and rooms',24600,300),('Notre-Dame action supplement',17160,180)]
  ],'broad_sample_frames':456,'window_minutes':38,
  'coverage_note':'Sequential five-second frame samples; includes dialogue and menus. Not 38 minutes of continuous real-time watching or 100% game coverage.',
  'sampling_time_uncertainty_seconds':2.5},
 'official':{'url':'https://www.youtube.com/watch?v=h82FdvzU5pI','creator':'KONAMI',
  'title':'Gameplay & Commentary Trailer (CERO)','upload_date':'2026-04-09','seconds':98,
  'broad_sample_interval_seconds':2,'broad_sample_frames':49,
  'detail_windows':[{'start':7,'seconds':2,'source_fps':60,'review_fps':30},
                    {'start':29,'seconds':4,'review_fps':6}]},
 'additional_review':[
  {'source':'walkthrough','start':450,'seconds':12,'review_fps':6},
  {'source':'walkthrough','start':414,'seconds':8,'review_fps':2},
  {'source':'walkthrough','start':5596,'seconds':12,'review_fps':1},
  {'source':'walkthrough','start':3435,'seconds':30,'review_fps':1},
  {'source':'walkthrough','start':365,'seconds':300,'review_fps':5,
   'purpose':'algorithmic dark-frame candidate scan, not all frames manually viewed'}
 ],
 'camera_manual_measurements':MEASUREMENTS,
 'parallax_pair':{'time_a':420.5,'time_b':421.0,'resolution':[960,540],
   'method':'normalized grayscale template correlation; integer dx/dy search; visually checked boxes',
   'features':pan_measurements,'distant_motion_ratio':73/120,'foreground_motion_ratio':149/120,
   'limitation':'Single short pan. Ratios are screen-motion estimates, not extracted engine settings. Frame-label timing uncertainty +/- 0.25 s.'},
 'early_dark_frame_scan':json.loads((FRAMES/'early_fade_scan.json').read_text()),
 'limits':['No hands-on play or input-to-action latency measurement','No sound-listening analysis',
           'No private game source, extracted game assets, or combat frame data',
           'Room transitions cannot establish asset streaming/loading internals',
           'Gameplay camera estimates use full video frame height, not an inferred internal viewport'],
 'rights':'Game imagery copyright KONAMI; walkthrough capture credited to BeardBear. Figures are attributed analysis references and are not Threadbound runtime assets.',
 'figure_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.glob('*.jpg'))}
}
(OUT/'measurements.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print('Built 5 figures and measurements.json')
