"""Install/enable sidebar tools, preserving existing preferences and .blend files.

Run in Blender background without --factory-startup so saved preferences remain.
"""
from pathlib import Path
from datetime import datetime
import shutil
import bpy

source = Path(__file__).with_name('threadbound_pose_tools.py')
preferences = Path(bpy.utils.user_resource('CONFIG')) / 'userpref.blend'
if preferences.exists():
    backup = preferences.with_name('userpref.before_threadbound_pose_tools_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.blend')
    shutil.copy2(preferences, backup)
    print('PREFERENCES_BACKUP', backup)
module = source.stem
if module in bpy.context.preferences.addons:
    bpy.ops.preferences.addon_disable(module=module)
assert bpy.ops.preferences.addon_install(filepath=str(source), overwrite=True) == {'FINISHED'}
assert bpy.ops.preferences.addon_enable(module=module) == {'FINISHED'}
assert module in bpy.context.preferences.addons
assert bpy.ops.wm.save_userpref() == {'FINISHED'}
print('THREADBOUND_POSE_TOOLS_INSTALLED', bpy.utils.user_resource('SCRIPTS'), module)
