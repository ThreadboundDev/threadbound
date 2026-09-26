"""Non-destructive material variant; run with background Blender."""
import json
import sys
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'ArtSource/BlueBiome/Blender/StillVillage'
HOUSE_STUDY = '--house-study' in sys.argv
VARIANT = 'MaterialV3' if HOUSE_STUDY else 'MaterialV2'
DEST = ROOT / 'Assets/BlueBiome/StillVillage' / VARIANT
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'StillVillage_Kit_v1.blend'))
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
manifest = json.loads((SOURCE / 'kit_manifest.json').read_text())

def surface(original, vertical=False):
    m = original.copy()
    m.name = original.name + (' | grain Z' if vertical else ' | material V2')
    nodes, links = m.node_tree.nodes, m.node_tree.links
    p = nodes.get('Principled BSDF')
    base = tuple(p.inputs['Base Color'].default_value)[:3]
    wood = original.name.startswith('Walnut')
    stone = original.name.startswith('Slate')
    if HOUSE_STUDY and stone:
        base = tuple(base[i] * (1.05, .66, .64)[i] for i in range(3))
    tex = nodes.new('ShaderNodeTexCoord')
    scale = nodes.new('ShaderNodeVectorMath'); scale.operation = 'MULTIPLY'
    scale.inputs[1].default_value = ((36, 9, 2) if vertical else (2, 9, 36)) if wood else (5, 5, 5)
    if HOUSE_STUDY:
        scale.inputs[1].default_value = ((14, 5, 1.5) if vertical else (1.5, 5, 14)) if wood else (2.8, 2.8, 2.8)
    links.new(tex.outputs['Generated'], scale.inputs[0])
    noise = nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 1
    noise.inputs['Detail'].default_value = 2
    noise.inputs['Roughness'].default_value = .65
    if HOUSE_STUDY:
        info = nodes.new('ShaderNodeObjectInfo')
        shift = nodes.new('ShaderNodeVectorMath'); shift.operation = 'ADD'
        links.new(scale.outputs['Vector'], shift.inputs[0])
        links.new(info.outputs['Random'], shift.inputs[1])
        links.new(shift.outputs['Vector'], noise.inputs['Vector'])
    else:
        links.new(scale.outputs['Vector'], noise.inputs['Vector'])
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1])
    stops = [(0.25, .40), (.40, .72), (.53, 1.10), (.66, 1.5), (.78, 1.8)] if wood else ([(0.25,.65),(.43,.85),(.57,1.10),(.72,1.32)] if stone else [(0.25,.92),(.75,1.06)])
    for i, (pos, value) in enumerate(stops):
        e = ramp.color_ramp.elements[0] if i == 0 else ramp.color_ramp.elements.new(pos)
        e.position = pos
        e.color = (*[min(.95, c * value) for c in base], 1)
    links.new(noise.outputs['Fac'], ramp.inputs[0])
    ao = nodes.new('ShaderNodeAmbientOcclusion')
    ao.inputs['Distance'].default_value = .23
    ao.samples = 8
    links.new(ramp.outputs['Color'], ao.inputs['Color'])
    links.new(ao.outputs['Color'], p.inputs['Base Color'])
    bump = nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = .24 if wood else (.10 if stone else .012)
    bump.inputs['Distance'].default_value = .035 if wood else .05
    links.new(noise.outputs['Fac'], bump.inputs['Height'])
    links.new(bump.outputs['Normal'], p.inputs['Normal'])
    p.inputs['Roughness'].default_value = .87
    return m

cache = {}
for entry in manifest:
    col = bpy.data.collections[entry['id']]
    for ob in col.objects:
        if ob.type not in {'MESH', 'CURVE'}:
            continue
        vertical = ob.dimensions.z > ob.dimensions.x * 1.5
        for slot in ob.material_slots:
            original = slot.material
            key = (original.name, vertical)
            if key not in cache:
                cache[key] = surface(original, vertical)
            slot.material = cache[key]

out = SOURCE / VARIANT
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out / ('StillVillage_' + VARIANT + '.blend' if HOUSE_STUDY else 'StillVillage_Material_v2.blend')))
for entry in manifest:
    for other in manifest:
        bpy.data.collections[other['id']].hide_render = other is not entry
    root = bpy.data.objects[entry['id'] + '_ROOT']
    saved = root.location.copy(); root.location = (0, 0, 0)
    w, h = entry['canvas']; ppu = entry['pixels_per_unit']
    left, top = -entry['origin_px'][0]/ppu, entry['origin_px'][1]/ppu
    center = Vector((left + w/ppu/2, 0, top - h/ppu/2))
    cam = scene.camera
    cam.location = (center.x, -10, center.z)
    cam.rotation_euler = (center-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale = max(w,h)/ppu
    scene.render.resolution_x = w; scene.render.resolution_y = h
    scene.render.resolution_percentage = 100
    target = DEST / entry['kind'] / (entry['id'] + '.png')
    target.parent.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(target)
    bpy.ops.render.render(write_still=True)
    root.location = saved
    entry['texture'] = target.relative_to(ROOT).as_posix()
    print('MATERIAL_V2_RENDER', entry['id'], flush=True)
(DEST / 'kit_manifest.json').write_text(json.dumps(manifest, indent=2))
print('MATERIAL_V2_COMPLETE', flush=True)
