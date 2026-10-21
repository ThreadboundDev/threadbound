"""Replace only roof collider point arrays; preserve the authored scene tree."""
from pathlib import Path
import math,re,json
ROOT=Path(__file__).resolve().parents[2]
SCENE=ROOT/'Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn'
text=SCENE.read_text()
profiles={'Fisher':(320,-46.72,5.68,5.08,4.85,1.38),'Workshop':(2688,-960.64,7.68,5.18,3.46,1.22),'Slip':(2816,477.44,7.94,4.94,6.13,1.2)}
def fixture(source):
    blocks=re.split(r'(?=\[node )',source)
    selected=[]
    for b in blocks:
        if re.search(r'\[node name="(?:Fisher|Workshop|Slip)Roof\d+"',b) or re.search(r'parent="Geometry/BuildingCollision/(?:Fisher|Workshop|Slip)Roof\d+"',b):
            b=b.split('[editable path=')[0]
            b=b.replace('parent="Geometry/BuildingCollision"','parent="."').replace('parent="Geometry/BuildingCollision/','parent="')
            selected.append(b.strip())
    return '[gd_scene format=3]\n\n[node name="RoofLandings" type="Node2D"]\n\n'+'\n\n'.join(selected)+'\n'
(ROOT/'work/lakeside-quality/roof_collision_before.tscn').write_text(fixture(text))
def repair(match):
    header,prefix,number=match.group(1,2,3)
    cx,anchor,w,d,eave,rise=profiles[prefix];i=int(number);A=w/2;r=(w-d)/2
    x0=-A+i*w/20;x1=-A+(i+1)*w/20
    def top(x):
        t=max(0,min(1,(abs(x)-r)/(A-r)))
        return anchor-128*(eave+rise*(1-t)**1.14+.095*t**8+.21*t**4+.10)
    midpoint=(x0+x1)/2
    body_y=top(midpoint)+6
    half_width=(x1-x0)*64
    left,right=top(x0)-body_y,top(x1)-body_y
    points=[-half_width,left,half_width,right,half_width,right+12,-half_width,left+12]
    return header+'polygon = PackedVector2Array('+', '.join(f'{v:.4f}' for v in points)+')'
pattern=r'(\[node name="Outline" type="CollisionPolygon2D" parent="Geometry/BuildingCollision/(Fisher|Workshop|Slip)Roof(\d+)"\]\n)polygon = PackedVector2Array\([^\n]+\)'
text,count=re.subn(pattern,repair,text)
assert count==60,count
SCENE.write_text(text)
(ROOT/'work/lakeside-quality/roof_collision_after.tscn').write_text(fixture(text))
print('ROOF_RAMP_COLLIDERS',count,'SCENE_TREE_PRESERVED')
