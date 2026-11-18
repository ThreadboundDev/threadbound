"""Refit Outfit B around the doll's arm and hip pivots, using exportable linear weights."""
import sys
import bpy
from mathutils import Vector

scene = bpy.context.scene
rig = bpy.data.objects["Threadborne_Rig"]
outfit = bpy.data.objects["B - Older outfit, hollowed"]
mesh = outfit.data
fit_action = rig.animation_data.action
assert fit_action.name == "Fit | T-pose, seated wrists"
notes = bpy.data.texts["Base armor fitting"]
assert "Outfit B motion weights" not in notes.as_string()

def smooth(x):
    x = min(1., max(0., x))
    return x*x*(3.-2.*x)

groups = {g.name:g for g in outfit.vertex_groups}

def write_weights(vertex, new):
    for g in tuple(vertex.groups):
        outfit.vertex_groups[g.group].remove((vertex.index,))
    total = sum(w for w in new.values() if w>.0001)
    for name, weight in new.items():
        if weight>.0001:
            groups[name].add((vertex.index,), weight/total, 'REPLACE')

for v in mesh.vertices:
    x,y,z = v.co
    side = 'L' if x>0 else 'R'
    a = abs(x)
    if z>1.376 and a>.152:
        # The cap follows the upper arm directly. Blend the fabric into the
        # chest along the armhole and leave the sleeve independent of the elbow.
        socket = .164 + .022*(1-smooth((z-1.41)/.095))
        arm = smooth((a-socket)/.107) * smooth((z-1.374)/.069 + smooth((a-.209)/.052))
        write_weights(v, {'chest': 1-arm, 'upper_arm.'+side: arm})
        # A small allowance behind the armhole gives the upper arm room to swing.
        room = smooth((a-.159)/.051) * smooth((.361-a)/.088) * smooth((z-1.379)/.074)
        normal = Vector((0,y-.020,z-1.502))
        if normal.length>.002:
            v.co += normal.normalized()*(room*(.014+.010*smooth((y-.043)/.091)))
    elif z<1.227:
        # The long tunic panels need to follow the raised leg near the hip.
        # The belt stays with the pelvis and the short crotch seam blends both legs.
        fall = 1.129 + .046*smooth((a-.045)/.125)
        leg = smooth((fall-z)/.194)
        left = smooth((x+.059)/.118)
        across = smooth((.081-a)/.081) * smooth((z-.729)/.135)
        if x>0:
            left = 1-(1-left)*across
        else:
            left *= across
        spine = .24*smooth((z-1.175)/.105)
        write_weights(v, {'pelvis': (1-leg)*(1-spine), 'spine': (1-leg)*spine,
                          'thigh.L': leg*left, 'thigh.R': leg*(1-left)})
        if z>.813:
            ease=smooth((z-.813)/.100) * smooth((1.186-z)/.106)
            normal=Vector((x-.078*(1 if x>0 else -1),y+.004,0))
            if normal.length>.006:
                v.co += normal.normalized()*(ease*(.013+.015*smooth((y+.055)/.100)))
mesh.update()
notes.write("\nOutfit B motion weights use a continuous upper arm blend at each armhole and thigh-driven tunic panels below a pelvis-bound sash. Local ease added near the armhole and seat.\n")
if "--save" in sys.argv:
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath,compress=True)
