"""Small Blender add-on; never regenerates or saves a character .blend."""

bl_info = {
    'name': 'Threadbound Pose Tools',
    'author': 'Threadbound',
    'version': (1, 0, 0),
    'blender': (5, 0, 0),
    'location': '3D View > Sidebar > Threadbound',
    'description': 'Reset the sword arm to a swim-ready pose without changing the body',
    'category': 'Animation',
}

import bpy
import math
from mathutils import Matrix

ARM = ('upper_arm.R', 'forearm.R', 'hand.R')
CONTROLS = ('CTRL_SwordHand', 'CTRL_SwordElbow')
RESET_BONES = ARM + CONTROLS
ANCHOR = 'clavicle.R'

# Immutable ready-pose snapshot from water_combo_1, frame 1, in the preserved
# v2 source. Targets are relative to the shoulder parent, not world space, so
# resetting during a lean/flip leaves the entire body where the artist put it.
# No runtime action switching, frame changes, source-file reads, or key deletion.
READY_TARGETS = {
    'CTRL_SwordHand': (
        (.34270427, -.90157151, -.26405078, -.15280291),
        (-.02037983, -.28814012, .95737165, .22347802),
        (-.93922263, -.32271388, -.11712077, .11790170),
        (0, 0, 0, 1)),
    'CTRL_SwordElbow': (
        (.07983672, .78967637, .60830760, .07521357),
        (-.99670458, .07204302, .03728858, .64660382),
        (-.01437841, -.60927993, .79282552, -.12740064),
        (0, 0, 0, 1)),
}
READY_BASIS = {
    'upper_arm.R': (
        (.80716807, -.29793376, .50962287, 0),
        (.18656000, .94779503, .25861239, 0),
        (-.56006724, -.11366843, .82061225, 0),
        (0, 0, 0, 1)),
    'forearm.R': (
        (.05846814, -.99778670, -.03168324, 0),
        (.99828911, .05848824, .00029153, 0),
        (.00156222, -.03164605, .99949789, 0),
        (0, 0, 0, 1)),
    'hand.R': (
        (.76944488, -.50658625, -.38900539, 0),
        (.38978708, .85491347, -.34232870, 0),
        (.50598562, .11177392, .85526830, 0),
        (0, 0, 0, 1)),
}


def compatible_rig(context):
    rig = context.object
    return (rig is not None and rig.type == 'ARMATURE'
            and all(name in rig.pose.bones for name in (*RESET_BONES, ANCHOR)))


def pose_poll(context):
    return (compatible_rig(context) and context.mode == 'POSE'
            and not (context.screen and context.screen.is_animation_playing))


def assign_pose(bone, matrix, *, basis=False):
    previous = bone.rotation_quaternion.copy()
    if basis:
        bone.matrix_basis = matrix
    else:
        bone.matrix = matrix
    # q and -q describe the same orientation; preserve the artist's hemisphere.
    if bone.rotation_mode == 'QUATERNION' and bone.rotation_quaternion.dot(previous) < 0:
        bone.rotation_quaternion.negate()


def ready_control_matrices(rig):
    shoulder = rig.pose.bones[ANCHOR].matrix.copy()
    targets = {name: shoulder @ Matrix(value) for name, value in READY_TARGETS.items()}
    # The old authored ready target was too close to the shoulder. Give the
    # artist an open 110-degree elbow, neither folded tightly nor locked out.
    upper = rig.pose.bones['upper_arm.R']
    forearm = rig.pose.bones['forearm.R']
    reach = math.sqrt(upper.length**2 + forearm.length**2
                      - 2*upper.length*forearm.length*math.cos(math.radians(110)))
    wrist = targets['CTRL_SwordHand']
    direction = (wrist.translation-upper.head).normalized()
    wrist.translation = upper.head + direction*reach
    return targets


class THREADBOUND_OT_reset_sword_arm(bpy.types.Operator):
    bl_idname = 'pose.threadbound_reset_sword_arm'
    bl_label = 'Reset Sword Arm'
    bl_description = ('Return the sword arm, hand square and elbow diamond to swim-ready. '
                      'Keeps the body and existing keys; use Key Sword Arm Pose to keep it')
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return pose_poll(context)

    def execute(self, context):
        rig = context.object
        context.view_layer.update()
        for name in ARM:
            assign_pose(rig.pose.bones[name], Matrix(READY_BASIS[name]), basis=True)
        context.view_layer.update()
        targets = ready_control_matrices(rig)
        for name in CONTROLS:
            assign_pose(rig.pose.bones[name], targets[name])
            context.view_layer.update()
        self.report({'INFO'}, 'Sword arm reset (not keyed). Key Sword Arm Pose to keep it; Ctrl+Z to undo.')
        return {'FINISHED'}


class THREADBOUND_OT_key_sword_arm(bpy.types.Operator):
    bl_idname = 'pose.threadbound_key_sword_arm'
    bl_label = 'Key Sword Arm Pose'
    bl_description = 'Save only the sword arm and its two controls at the current frame'
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return pose_poll(context)

    def execute(self, context):
        for name in RESET_BONES:
            bone = context.object.pose.bones[name]
            rotation = ('rotation_quaternion' if bone.rotation_mode == 'QUATERNION'
                        else 'rotation_axis_angle' if bone.rotation_mode == 'AXIS_ANGLE'
                        else 'rotation_euler')
            for prop in ('location', rotation, 'scale'):
                bone.keyframe_insert(prop, frame=context.scene.frame_current, group=name)
        self.report({'INFO'}, 'Sword arm pose keyed at frame %d' % context.scene.frame_current)
        return {'FINISHED'}


class THREADBOUND_PT_pose_tools(bpy.types.Panel):
    bl_label = 'Sword Arm'
    bl_idname = 'THREADBOUND_PT_pose_tools'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Threadbound'

    def draw(self, context):
        layout = self.layout
        if not compatible_rig(context):
            layout.label(text='Select Threadborne_Rig.', icon='INFO')
            return
        if context.mode != 'POSE':
            layout.label(text='Switch to Pose Mode.', icon='INFO')
            return
        if context.screen and context.screen.is_animation_playing:
            layout.label(text='Pause playback to pose.', icon='INFO')
        column = layout.column(align=True)
        column.scale_y = 1.3
        column.operator(THREADBOUND_OT_reset_sword_arm.bl_idname, icon='LOOP_BACK')
        column.operator(THREADBOUND_OT_key_sword_arm.bl_idname, icon='KEY_HLT')
        layout.label(text='Reset does not change keys.')
        layout.label(text='Key the pose before changing frames.')
        left_hand = context.object.pose.bones.get('CTRL_LeftHand')
        grip = left_hand.constraints.get('Second hand follows sword grip') if left_hand else None
        if grip and not grip.mute and grip.influence > .01:
            layout.label(text='Two-hand grip: left hand follows.', icon='INFO')


CLASSES = (THREADBOUND_OT_reset_sword_arm, THREADBOUND_OT_key_sword_arm, THREADBOUND_PT_pose_tools)


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)


def unregister():
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)


if __name__ == '__main__':
    register()
