"""Prepare Outfit A's Blender-only motion review from the existing master actions."""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

scene = bpy.context.scene
layer = scene.view_layers["A - Original pieces"]
rig = bpy.data.objects["Threadborne_Rig"]
cloth = bpy.data.objects["A - Original pieces, unified outfit"]
lining = bpy.data.objects["A - Fitted underclothes"]
assert cloth.get("source_rear_fit_v2") and not cloth.get("hem_motion_review")
assert not rig.animation_data.nla_tracks

def smooth(value):
    value = min(1., max(0., value))
    return value*value*(3.-2.*value)

# Shorten the skin-tight sleeves by 12 mm and the shorts by 15 mm.
bm = bmesh.new()
bm.from_mesh(lining.data)
for point, normal in [((.305,0,0),(1,0,0)), ((-.305,0,0),(-1,0,0)), ((0,0,.743),(0,0,-1))]:
    bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
                           plane_co=point, plane_no=normal, clear_outer=True, dist=.000001)
bm.to_mesh(lining.data)
bm.free()
lining.data.update()

sections={i:p.material_index for p in cloth.data.polygons for i in p.vertices}
for v in cloth.data.vertices:
    x,y,z=v.co
    if sections.get(v.index) not in (0,3) or z>1.18 or abs(x)>.17:
        continue
    w=smooth((.17-abs(x))/.065)*smooth((1.18-z)/.06)
    thigh=smooth((1.16-z)/.21)
    # Anchor the upper inseam to the pelvis. Ease each side into its own
    # thigh over the width of the panel, using the final fitted coordinates.
    thigh*=1-.65*smooth((.12-abs(x))/.12)*smooth((z-.78)/.11)
    left=smooth((x+.11)/.22)
    desired={"pelvis":1-thigh,"thigh.L":left*thigh,"thigh.R":(1-left)*thigh}
    old={cloth.vertex_groups[g.group].name:g.weight for g in v.groups
         if cloth.vertex_groups[g.group].name in {"pelvis","spine","chest","thigh.L","thigh.R"}}
    for name in old.keys()|desired.keys():
        weight=old.get(name,0)*(1-w)+desired.get(name,0)*w
        if weight>1.e-7:
            cloth.vertex_groups[name].add([v.index],weight,"REPLACE")
        elif name in old:
            cloth.vertex_groups[name].remove([v.index])
cloth.data.update()

# Blend across the armhole from chest to upper arm on both sides.
for v in cloth.data.vertices:
    x,y,z=v.co
    if sections.get(v.index)!=0 or z<1.30 or abs(x)<.085:
        continue
    arm=smooth((abs(x)-.122)/.136)*smooth((z-1.31)/.08)
    side="L" if x>0 else "R"
    w=smooth((z-1.30)/.053)*smooth((abs(x)-.085)/.046)
    desired={"chest":1-arm,"upper_arm."+side:arm}
    old={cloth.vertex_groups[g.group].name:g.weight for g in v.groups
         if rig.data.bones.get(cloth.vertex_groups[g.group].name)}
    for name in old.keys()|desired.keys():
        weight=old.get(name,0)*(1-w)+desired.get(name,0)*w
        if weight>1.e-7:
            cloth.vertex_groups[name].add([v.index],weight,"REPLACE")
        elif name in old:
            cloth.vertex_groups[name].remove([v.index])

# Six soft masks end below each seam. Their strength is zero at the anchor
# and rises gradually toward the loose edge. The belt and cowl stay pinned.
sections = {i:p.material_index for p in cloth.data.polygons for i in p.vertices}
zones = []
for label, bone, limit, response in [("Sleeve","upper_arm",.006,.045),
                                     ("Shorts","thigh",.007,.052),
                                     ("Tunic","thigh",.011,.075)]:
    for side in ("L","R"):
        group = cloth.vertex_groups.new(name=label+" edge."+side)
        for v in cloth.data.vertices:
            x,y,z = v.co
            if (x>0) != (side=="L"):
                continue
            part = sections.get(v.index)
            w = 0.
            if label=="Sleeve" and part==0 and z>1.34:
                w = smooth((abs(x)-.265)/.125)
            if label=="Shorts" and part==3:
                w = smooth((.855-z)/.156)
            if label=="Tunic" and part==0:
                w = smooth((1.043-z)/.174) * smooth(abs(x)/.045)
            if w:
                group.add([v.index],w,"REPLACE")
        channels = []
        for axis in ("Y","Z") if label=="Sleeve" else ("X","Y"):
            name = "hem_"+label+"_"+side+"_"+axis
            rig[name] = 0.
            mod = cloth.modifiers.new(group.name+" "+axis,"DISPLACE")
            mod.vertex_group = group.name
            mod.direction = axis
            mod.mid_level = 0.
            mod.strength = 0.
            cloth.modifiers.move(len(cloth.modifiers)-1, 0)
            driver = mod.driver_add("strength").driver
            driver.type = "AVERAGE"
            variable = driver.variables.new()
            variable.targets[0].id = rig
            variable.targets[0].data_path = '["'+name+'"]'
            channels.append((name,"XYZ".index(axis)))
        zones.append((bone+"."+side, .72 if label=="Tunic" else .95, limit, response, channels))

# Sample only the armature while baking. No cloth or character mesh needs
# reevaluation during this step.
review = [a for a in bpy.data.actions if a.name.startswith(("Review |","Stowed |","Stow review |"))]
review += [bpy.data.actions[n] for n in ("Review - seated wrists and steady shield thumb","Review - idle_2 Chase shoulder seat")]
sample = bpy.data.scenes.new("Temporary cloth motion sampler")
proxy = rig.copy()
sample.collection.objects.link(proxy)
proxy.animation_data_clear()
proxy.animation_data_create()
bpy.context.window.scene = sample
for action in review:
    for b in proxy.pose.bones:
        b.matrix_basis = Matrix.Identity(4)
    proxy.animation_data.action = action
    slot = next(s for s in action.slots if s.identifier=="OBThreadborne_Rig")
    proxy.animation_data.action_slot = slot
    start,end = map(round,action.frame_range)
    frames = list(range(start,end+1))
    traces = [[] for zone in zones]
    for frame in frames:
        sample.frame_set(frame)
        for trace,(name,t,limit,response,channels) in zip(traces,zones):
            b = proxy.pose.bones[name]
            trace.append((b.head.lerp(b.tail,t), (b.matrix @ b.bone.matrix_local.inverted()).to_3x3().inverted_safe()))
    bag = action.layers[0].strips[0].channelbag(slot)
    for trace,(_,_,limit,response,channels) in zip(traces,zones):
        cyclic = any(tag in action.name for tag in ("run_","walk_","idle","swimming","swinging"))
        lag = Vector()
        previous = trace[0][0]
        values = []
        # Prime cyclic clips from their own preceding frames, so repeated
        # strides settle identically every time. A stationary hold decays.
        indices = list(range(max(0,len(frames)-10),len(frames)-1)) if cyclic else []
        for i in indices + list(range(len(frames))):
            p, inverse = trace[i]
            lag = .65*lag + .35*((p-previous)*-response*5)
            previous = p
            offset = inverse @ lag
            if offset.length>limit:
                offset.normalize()
                offset *= limit
            values.append(offset)
        values = values[-len(frames):]
        if cyclic:
            values[-1] = values[0]
        for prop,axis in channels:
            curve = bag.fcurves.new('["'+prop+'"]')
            curve.keyframe_points.add(len(frames))
            for key,frame,v in zip(curve.keyframe_points,frames,values):
                key.co = (frame,v[axis])
                key.interpolation = "LINEAR"
            curve.update()

bpy.context.window.scene = scene
bpy.context.window.view_layer = layer
bpy.data.objects.remove(proxy,do_unlink=True)
bpy.data.scenes.remove(sample)
rig.animation_data.action = None
track = rig.animation_data.nla_tracks.new()
track.name = "Outfit A | animation review"
order = ["Review | run_1","Review | walk_1","Review | crouch_idle_1","Review | jump_into_wall_hang_1",
         "Review | grapple_swinging_1","Review | slash_2","Review - seated wrists and steady shield thumb"]
ordered = [bpy.data.actions[n] for n in order] + [a for a in review if a.name not in order]
cursor = 1
for action in ordered:
    strip = track.strips.new(action.name,cursor,action)
    strip.action_slot = next(s for s in action.slots if s.identifier=="OBThreadborne_Rig")
    if action.name in order[:2]:
        strip.repeat = 4
    strip.extrapolation = "NOTHING"
    scene.timeline_markers.new(action.name, frame=cursor)
    cursor = math.ceil(strip.frame_end)
scene.frame_start = 1
scene.frame_end = cursor-1
scene.use_preview_range = False
scene.render.fps = 30
# Keep the working T-pose accessible as its original action.
bpy.data.actions["Fit | T-pose, seated wrists"].use_fake_user = True
scene.frame_set(6)
layer.layer_collection.children["Outfit B"].exclude = True
bpy.data.objects["Base_Bracer.R"].hide_render = True
cloth["hem_motion_review"] = True
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            space=area.spaces.active
            if space.local_view is None:
                space.region_3d.view_perspective="ORTHO"
                space.region_3d.view_rotation=Vector((.48,-1,.10)).to_track_quat("Z","Y")
                space.region_3d.view_location=(0,0,1.02)
                space.region_3d.view_distance=3.1
                space.overlay.show_overlays=False
print("REVIEW READY",len(ordered),"actions",cursor-1,"frames",len(zones),"cloth regions",flush=True)
if "--save" in sys.argv:
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath,compress=True)
