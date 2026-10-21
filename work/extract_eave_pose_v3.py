from pathlib import Path
s=Path('tools/art/build_eave_runner.py').read_text(encoding='utf-8')
a=s[s.index('def orient('):s.index('# Make the held weapon')]
a=a.replace("hands={'L':Vector((.28,-.23,1.14)),'R':Vector((-.30,-.18,1.10))}","hands={'L':Vector((.225,-.10,.94)),'R':Vector((-.24,-.12,.95))}")
b=s[s.index('for clip,duration,loop in CLIPS:'):s.index('events={')]
out='''"""Length-adaptive Eave poses on the measured player-proportion rig."""
import bpy,math
from mathutils import Vector,Matrix,Quaternion

def bake(rig,scene,HEAD,TAIL,REST):
    rig.animation_data.action=None
    for old in list(bpy.data.actions):
        if old.name in ["idle","run","wall_attach","wall_perch","wall_windup","wall_launch","jump_slash","land_recover","throw_windup","throw_release","hurt","death"]:bpy.data.actions.remove(old)
    actions={}
'''
out+='\n'.join('    '+line for line in (a+'\n'+b).splitlines())
out+='\n    return actions\n'
Path('tools/art/eave_pose_authoring_v3.py').write_text(out,encoding='utf-8')
