"""Package Godot audit captures. Requires Pillow; no game/source asset edits."""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
RAW = ROOT / 'tmp/scale-vfx-study'
VFX = RAW / 'vfx'
BG = '#17232b'
INK = '#f4f1e6'
GOLD = '#e8c58a'
FONT = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 21)
SMALL = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 16)

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def picture(path):
    return Image.open(path).convert('RGB')

def board(name, panels, cols=2, size=(600,338)):
    w,h = size
    image = Image.new('RGB',(w*cols,(h+65)*math.ceil(len(panels)/cols)),BG)
    draw = ImageDraw.Draw(image)
    for i,(pic,title,note) in enumerate(panels):
        x,y = i%cols*w,i//cols*(h+65)
        image.paste(pic.resize((w,h),Image.Resampling.LANCZOS),(x,y))
        draw.text((x+10,y+h+6),title,font=FONT,fill=INK)
        draw.text((x+10,y+h+34),note,font=SMALL,fill=INK)
    image.save(OUT/name,quality=94)

def camera_board():
    panels=[]
    for mode,title in [('demo','Demo: current zoom 1.00'),('blue','Blue: current zoom 0.90')]:
        report = read(RAW/f'{mode}_measurement.json')
        pic = picture(RAW/f'{mode}_idle_screen.png')
        r=report['poses']['Idle'].get('screen_body_rect')
        if r:
            x,y,w,h=r
            ImageDraw.Draw(pic).rectangle([x-3,y-3,x+w+3,y+h+3],outline=GOLD,width=3)
        pct=report['poses']['Idle']['screen_fraction']*100
        panels.append((pic,title,f'Current idle body: {pct:.2f}% of 1080px view height'))
    panels.append((picture(RAW/'blue_idle_zoom_083.png'),'Blue: proposed zoom 0.83 (runtime preview)',
                   'Same model/collision/world; idle body becomes 13.26%'))
    reference=picture(OUT/'reference-library-03h19m55s.jpg')
    ImageDraw.Draw(reference).rectangle([375,266,420,334],outline=GOLD,width=3)
    panels.append((reference,"Belmont: Library, ~03:19:55",'Body 68 +/- 4px / 540px = 12.59%; one sampled pose'))
    board('camera-comparison.jpg',panels)

def body_board():
    image=Image.new('RGB',(1200,510),BG)
    draw=ImageDraw.Draw(image)
    panels=[('Current idle','fixture_idle_body.png','Wide stance, bent knees; body only'),
            ('Current run sample','fixture_run_body.png','Same model, another silhouette'),
            ('Rig rest reference','fixture_rest_body.png','Straight legs; reference pose, not an idle')]
    for i,(title,file,note) in enumerate(panels):
        body=Image.open(RAW/file).convert('RGBA')
        body=body.crop(body.getbbox())
        # Match head-to-foot spans to isolate shape, not camera size.
        body=body.resize((round(body.width*300/body.height),300),Image.Resampling.LANCZOS)
        image.paste(body,(i*400+(400-body.width)//2,85),body)
        draw.line([(i*400+20,385),(i*400+380,385)],fill='#57707a',width=2)
        draw.text((i*400+16,20),title,font=FONT,fill=INK)
        draw.text((i*400+16,420),note,font=SMALL,fill=INK)
    draw.text((16,477),'Equal displayed height here: this board compares pose and shape, not gameplay scale.',font=SMALL,fill=GOLD)
    image.save(OUT/'posture-comparison.jpg',quality=95)

def context_board():
    house=picture(RAW/'blue_house_screen.png')
    d=ImageDraw.Draw(house)
    d.rectangle([869,572,1048,826],outline=GOLD,width=3)
    # Outer framed door assembly, not the clear opening/entry overlay.
    d.line([(1080,572),(1080,826)],fill=GOLD,width=4)
    trial=picture(RAW/'trial_spawn_screen.png')
    report=read(RAW/'trial_measurement.json')
    x,y,w,h=report['projected_body_rect']
    ImageDraw.Draw(trial).rectangle([x,y,x+w,y+h],outline=GOLD,width=3)
    board('environment-scale.jpg',[
        (house,'Blue fisher house: about 4.84 idle body-heights','Outer door frame ~254 +/- 8px / player 155px: ~1.64x'),
        (trial,'Preserved 3D trial: close perspective framing','Body ~27.8% of 900px; workshop 4.45 / body rest 1.80 units')],
        cols=1,size=(960,540))

def crop_action(image,left=False):
    return image.crop((300,270,1020,810) if left else (480,270,1200,810))

def vfx_boards():
    data=read(VFX/'candidate_right.json')
    indices=[18,33,69]
    panels=[]
    for i in indices:
        step=data['frames'][i]['step']+1
        for mode in ['baseline','candidate']:
            pic=crop_action(picture(VFX/f'{mode}_right_frame_{i:03}.png'))
            panels.append((pic,f'Strike {step}: '+('current thin strokes' if mode=='baseline' else 'original filled sweep study'),
                           'Identical production clip/timing; enlarged review crop'))
    board('vfx-comparison.jpg',panels,cols=2,size=(600,450))
    # Matched camera crop and 60fps source frames. GIF uses 20fps for size.
    frames=[]
    total=min(len(read(VFX/'baseline_right.json')['frames']),len(data['frames']))
    for i in range(0,total,3):
        image=Image.new('RGB',(960,412),BG)
        draw=ImageDraw.Draw(image)
        for n,mode in enumerate(['baseline','candidate']):
            panel=crop_action(picture(VFX/f'{mode}_right_frame_{i:03}.png')).resize((480,360),Image.Resampling.LANCZOS)
            image.paste(panel,(n*480,40))
            draw.text((n*480+10,8),'CURRENT' if mode=='baseline' else 'FILLED SWEEP STUDY',font=FONT,fill=INK)
        frames.append(image)
    frames[0].save(OUT/'combo-comparison.gif',save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=2)
    mirror=[]
    left=read(VFX/'candidate_left.json')
    for i in [18,33,69]:
        mirror.append((crop_action(picture(VFX/f'candidate_left_frame_{i:03}.png'),left=True),
                       f'Left facing: strike {left["frames"][i]["step"]+1}','World-space trail; same parameters as right facing'))
    board('vfx-left-facing.jpg',mirror,cols=3,size=(400,300))
    game=picture(VFX/'candidate_right_game_scale_frame_018.png')
    board('vfx-gameplay-scale.jpg',[(game,'Candidate at proposed gameplay zoom 0.83',
          'Full 1920 x 1080 composition; same effect as the close-ups')],cols=1,size=(960,540))
    # The existing damage sector can be much wider than the current blade.
    pic=picture(VFX/'candidate_right_frame_018.png')
    d=ImageDraw.Draw(pic,'RGBA')
    points=[tuple(p) for p in data['frames'][18]['damage_polygon_screen']]
    d.polygon(points,fill=(232,197,138,32))
    d.line(points+[points[0]],fill=(232,197,138,255),width=3)
    board('existing-hitbox-overlay.jpg',[(crop_action(pic),'Gold: existing damage sector (debug overlay)',
          'Candidate stays blade-led; full reach reconciliation remains a live-combat task')],cols=1,size=(960,720))

def package_data():
    measurements={mode:read(RAW/f'{mode}_measurement.json') for mode in ['fixture','blue','demo','trial']}
    measurements['reference_frame']={'file':'reference-library-03h19m55s.jpg','source_url':'https://www.youtube.com/watch?v=q3NuImErog8&t=11995s','creator':'BeardBear','sample_timestamp_seconds':11995,'sampling_uncertainty_seconds':2.5,'width':960,'height':540,'purpose':'Attributed gameplay-analysis reference only; not a Threadbound asset or licensed production art.'}
    measurements['camera_proposal']={'zoom':0.83,'idle_height_world':172.5,'screen_height':172.5*0.83,'screen_fraction':172.5*0.83/1080,'visible_world_width':1920/0.83,'visible_world_height':1080/0.83,'blue_width_increase_percent':100*(0.9/0.83-1),'demo_width_increase_percent':100*(1/0.83-1)}
    measurements['house']={'bounds_source':'work/painted-2d-comparison-2026-10-22/source_manifest.json: fisher_house','height_world':835.320983886719,'idle_body_heights':835.320983886719/172.5,'outer_door_frame_manual_screen_box':[869,572,1048,826],'outer_door_frame_height_uncertainty_px':8,'procedural_entry_overlay_height_world':218,'note':'The outer framed door assembly includes lintel/threshold; it is not the clear opening. The entry overlay is a separate presentation measurement. Neither measures collision clearance.'}
    (OUT/'measurements.json').write_text(json.dumps(measurements,indent=2)+'\n',encoding='utf-8')
    a=read(VFX/'baseline_right.json')['frames']
    b=read(VFX/'candidate_right.json')['frames']
    left=read(VFX/'candidate_left.json')['frames']
    matched=len(a)==len(b) and all(x['step']==y['step'] and abs(x['source_seconds']-y['source_seconds'])<1e-6 and x['blade']==y['blade'] for x,y in zip(a,b))
    damage_matched=len(a)==len(b) and all(x['damage_polygon_screen']==y['damage_polygon_screen'] and x['damage_active']==y['damage_active'] for x,y in zip(a,b))
    prototype=read(VFX/'candidate_right.json')
    gif=Image.open(OUT/'combo-comparison.gif')
    duration=0
    for i in range(gif.n_frames):
        gif.seek(i)
        duration+=gif.info.get('duration',0)
    data={'frame_count_each':len(b),'matched_baseline_candidate_animation_and_blade':matched,'matched_damage_polygon_and_activation':damage_matched,'combo_steps':sorted({v['step'] for v in b if v['step']>=0}),'left_combo_steps':sorted({v['step'] for v in left if v['step']>=0}),'actual_left_facings':sorted({v['facing'] for v in left}),'actual_right_facings':sorted({v['facing'] for v in b}),'source_delta_seconds':sorted({v['delta'] for v in b}),'candidate_trail_seconds':prototype['trail_seconds'],'candidate_reach_extension':prototype['reach_extension'],'contact_lifetime_seconds':0.13,'gif_frames':gif.n_frames,'gif_duration_ms':duration,'contact_note':'Illustrative timer events; not actual hits. No enemy/reaction, sound or hit-stop evaluation.','raw_frames':'Ignored tmp/scale-vfx-study/vfx; 60fps source, packaged GIF 20fps.'}
    (OUT/'validation.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    assert matched, 'Comparison changed animation or blade points'
    assert damage_matched, 'Comparison changed damage geometry or activation'
    assert data['actual_left_facings']==[-1] and data['actual_right_facings']==[1]
    assert data['combo_steps']==[0,1,2] and data['left_combo_steps']==[0,1,2]

if __name__=='__main__':
    camera_board()
    body_board()
    context_board()
    vfx_boards()
    package_data()
    print('Packaged scale and VFX review; matched animation/blade audit passed.')
