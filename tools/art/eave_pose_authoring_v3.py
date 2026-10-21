"""Length-adaptive Eave poses on the measured player-proportion rig."""
import bpy,math
from mathutils import Vector,Matrix,Quaternion

def bake(rig,scene,HEAD,TAIL,REST):
    rig.animation_data.action=None
    for old in list(bpy.data.actions):
        if old.name in ["idle","run","wall_attach","wall_perch","wall_windup","wall_launch","jump_slash","land_recover","throw_windup","throw_release","hurt","death"]:bpy.data.actions.remove(old)
    actions={}
    def orient(name,start,end):
        q=(TAIL[name]-HEAD[name]).rotation_difference(end-start)
        rig.pose.bones[name].matrix=Matrix.Translation(start)@q.to_matrix().to_4x4()@REST[name].to_3x3().to_4x4()
        bpy.context.view_layer.update()
    def limb(upper,lower,endbone,target,pole,end_angle=0,hand_direction=None):
        start=rig.pose.bones[upper].head.copy();a=(TAIL[upper]-HEAD[upper]).length;b=(TAIL[lower]-HEAD[lower]).length
        delta=Vector(target)-start;distance=max(abs(a-b)+.0001,min(delta.length,a+b-.0001));axis=delta.normalized()
        along=(a*a-b*b+distance*distance)/(2*distance);bend=Vector(pole)-start;bend-=axis*bend.dot(axis)
        if bend.length<.0001:bend=Vector((0,-1,0))
        bend.normalize();elbow=start+axis*along+bend*math.sqrt(max(0,a*a-along*along));target=start+axis*distance
        orient(upper,start,elbow);orient(lower,elbow,target)
        rotation=Matrix.Rotation(end_angle,4,'X')
        basis=REST[endbone].to_3x3().to_4x4()
        if endbone.startswith('hand.'):
            direction=Vector(hand_direction) if hand_direction is not None else target-elbow
            align=(TAIL[endbone]-HEAD[endbone]).rotation_difference(direction)
            basis=align.to_matrix().to_4x4()@basis
        rig.pose.bones[endbone].matrix=Matrix.Translation(target)@rotation@basis;bpy.context.view_layer.update()
    def mix(a,b,t):return Vector(a).lerp(Vector(b),max(0,min(1,t)))
    def ease(t):return max(0,min(1,t))**2*(3-2*max(0,min(1,t)))

    CLIPS=[('idle',2.4,True),('run',.8,True),('wall_attach',.35,False),('wall_perch',1.6,True),('wall_windup',.45,False),('wall_launch',.30,False),('jump_slash',.65,False),('land_recover',.60,False),('throw_windup',.45,False),('throw_release',.35,False),('hurt',.40,False),('death',1.20,False)]

    def pose(clip,t):
        # An earlier action must not re-evaluate over the authored solve while
        # collecting the next action's matrices at the current scene frame.
        if rig.animation_data:rig.animation_data.action=None
        for pb in rig.pose.bones:pb.rotation_mode='QUATERNION';pb.matrix_basis=Matrix.Identity(4)
        phase=t*math.tau;s=ease(t)
        pelvis=Vector((0,0,0));lean=0;twist=0
        feet={side:HEAD['foot.'+side].copy() for side in ['L','R']}
        hands={'L':Vector((.225,-.10,.94)),'R':Vector((-.24,-.12,.95))}
        if clip=='idle':pelvis.z=.006*math.sin(phase);lean=.025;hands['L'].z+=.009*math.sin(phase)
        if clip=='run':
            pelvis.z=-.055+.017*math.cos(phase*2);lean=.16
            for side,sign in [('L',1),('R',-1)]:
                q=phase+(0 if sign==1 else math.pi);feet[side].y+=.19*math.cos(q);feet[side].z+=.12*max(0,math.sin(q))
                hands[side]=Vector((sign*.26,-.08+sign*.17*math.cos(phase),1.20+.03*math.sin(q)))
        if clip.startswith('wall_'):
            amount=s if clip=='wall_attach' else 1
            pelvis=mix((0,0,0),(0,.10,-.15),amount);lean=-.08*amount
            hands['L']=mix(hands['L'],(.23,.38,1.39),amount);hands['R']=mix(hands['R'],(-.29,-.04,1.52),amount)
            feet['L']=mix(feet['L'],(.15,.35,.31),amount);feet['R']=mix(feet['R'],(-.17,.35,.69),amount)
            if clip=='wall_perch':pelvis.z+=.005*math.sin(phase)
            if clip=='wall_windup':
                pelvis.z-=.07*s;hands['R']=mix(hands['R'],(-.22,.04,1.59),s)
            if clip=='wall_launch':
                pelvis=mix(pelvis,(0,-.02,.16),s);lean=.4*s
                hands['L']=mix(hands['L'],(.34,-.34,1.34),s)
                feet['L']=mix(feet['L'],(.18,.24,.50),s);feet['R']=mix(feet['R'],(-.22,.40,.68),s)
        if clip=='jump_slash':
            pelvis=Vector((.02*math.sin(math.pi*t),-.02,.15-.10*s));lean=.30;twist=-.35+.72*s
            hands['R']=mix((-.24,-.10,1.60),(.37,-.34,1.08),s)
            hands['L']=mix((.34,-.30,1.36),(.25,.10,1.24),s)
            feet['L']=mix((.16,.23,.49),(.22,.04,.25),s);feet['R']=mix((-.22,.40,.67),(-.19,.25,.49),s)
        if clip=='land_recover':
            amount=1-ease(t);pelvis.z=-.24*amount;lean=.40*amount
            feet['L'].x+=.08*amount;feet['L'].y-=.09*amount;feet['R'].y+=.10*amount
            hands['L']=mix(hands['L'],(.30,-.25,.52),amount);hands['R']=mix(hands['R'],(-.37,-.14,.83),amount)
        if clip in ['throw_windup','throw_release']:
            twist=.25;amount=s if clip=='throw_windup' else 1
            hands['L']=mix(hands['L'],(.25,.03,1.56),amount)
            if clip=='throw_release':hands['L']=mix((.25,.03,1.56),(.12,-.53,1.34),s);twist=.25-.40*s
        if clip=='hurt':
            recoil=math.sin(math.pi*t);pelvis.y=.055*recoil;lean=-.18*recoil;hands['L'].y+=.15*recoil
        if clip=='death':
            pelvis.z=-.50*s;pelvis.y=.15*s;lean=-.48*s
            hands['L']=mix(hands['L'],(.35,.13,.65),s);hands['R']=mix(hands['R'],(-.39,.04,.52),s)
            feet['L'].x+=.09*s;feet['R'].x-=.07*s
        pb=rig.pose.bones['pelvis'];pb.location=REST['pelvis'].to_quaternion().inverted()@pelvis
        for name,angle,axis in [('spine',lean*.45,'X'),('chest',lean*.55,'X'),('chest',twist,'Z')]:
            pb=rig.pose.bones[name];world=Quaternion((1,0,0) if axis=='X' else (0,0,1),angle)
            q=REST[name].to_quaternion();pb.rotation_quaternion=pb.rotation_quaternion@(q.inverted()@world@q)
        bpy.context.view_layer.update()
        blade_angle=0
        if clip in ['wall_attach','wall_perch']:blade_angle=-2.0*(s if clip=='wall_attach' else 1)
        if clip=='wall_windup':blade_angle=-2.0-.7*s
        if clip=='wall_launch':blade_angle=-2.7+.6*s
        if clip=='jump_slash':blade_angle=-2.1+1.95*s
        if clip=='land_recover':blade_angle=-.15*(1-s)
        for side,sign in [('L',1),('R',-1)]:
            limb('thigh.'+side,'shin.'+side,'foot.'+side,feet[side],(sign*.20,-1.3,.7),math.pi/2 if clip.startswith('wall_') else 0)
            limb('upper_arm.'+side,'forearm.'+side,'hand.'+side,hands[side],(sign*.80,-.40,1.10),blade_angle if side=='R' else 0,(0,0,1) if side=='L' and clip.startswith('wall_') else None)
            for digit in range(1,6):
                for segment in range(1,4):
                    pb=rig.pose.bones['finger%d-%d.%s'%(digit,segment,side)]
                    curl=.64 if side=='R' else (.25 if clip not in ['throw_windup','wall_perch','wall_attach','wall_windup'] else .40)
                    if side=='L' and clip in ['wall_perch','wall_attach','wall_windup']:curl=.10
                    pb.rotation_quaternion=Quaternion((1,0,0),curl if digit>1 else .18)
        for side,sign in [('L',1),('R',-1)]:
            for i in range(3):
                pb=rig.pose.bones['tail_%s_%d'%(side,i+1)]
                sway=.045*math.sin(phase-i*.6+sign*.2) if clip in ['idle','wall_perch','run'] else .12*math.sin(math.pi*t-i*.45)
                trail=(.22 if clip in ['wall_launch','jump_slash','run'] else 0)*(i+1)/3
                pb.rotation_quaternion=Quaternion((1,0,0),sway+trail)@Quaternion((0,0,1),sway*.4)
        if clip!='throw_windup' and not (clip=='throw_release' and t<=.35):
            rig.pose.bones['held_pin'].scale=Vector((.001,.001,.001))
        if clip=='death':
            for side in ['L','R']:
                for i in range(3):rig.pose.bones['tail_%s_%d'%(side,i+1)].scale=Vector((1,1,1+.30*s))
        bpy.context.view_layer.update()


    for clip,duration,loop in CLIPS:
        count=round(duration*30)+1;samples=[]
        for frame in range(1,count+1,2):
            t=(frame-1)/(count-1);pose(clip,t)
            matrices={pb.name:pb.matrix.copy() for pb in rig.pose.bones};local={}
            for b in rig.data.bones:
                local[b.name]=b.matrix_local.inverted()@b.parent.matrix_local@matrices[b.parent.name].inverted()@matrices[b.name] if b.parent else b.matrix_local.inverted()@matrices[b.name]
            samples.append((frame,local))
        if samples[-1][0]!=count:
            pose(clip,1);matrices={pb.name:pb.matrix.copy() for pb in rig.pose.bones}
            samples.append((count,{b.name:b.matrix_local.inverted()@b.parent.matrix_local@matrices[b.parent.name].inverted()@matrices[b.name] if b.parent else b.matrix_local.inverted()@matrices[b.name] for b in rig.data.bones}))
        action=bpy.data.actions.new(clip);action.use_fake_user=True;action['loop']=loop;action['duration']=duration;rig.animation_data.action=action
        for frame,local in samples:
            for pb in rig.pose.bones:
                pb.location,pb.rotation_quaternion,pb.scale=local[pb.name].decompose()
                for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame,group=pb.name)
        actions[clip]=action;print('EAVE_RUNNER_CLIP',clip,flush=True)
    rig.animation_data.action=actions['idle'];scene.frame_set(1);scene.frame_start=1;scene.frame_end=73
    return actions
