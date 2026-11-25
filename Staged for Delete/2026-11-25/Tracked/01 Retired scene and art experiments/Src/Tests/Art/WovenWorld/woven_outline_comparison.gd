extends RefCounted
## Test-level overrides only. Original outline materials remain untouched.

const LABELS := ["ORIGINAL", "THIN DARK", "THIN MATERIAL"]
const WIDTH_SCALE := 0.5
var visual: Node
var mode := 2
var originals: Dictionary = {}


func initialize(target: Node) -> void:
	visual = target
	var equipment: Node = visual.get("equipment_visuals")
	if equipment:
		equipment.item_changed.connect(_equipment_changed)
	refresh()


func _equipment_changed(_slot: StringName, _item: Resource) -> void:
	# The production listener installs new shells first; collect them afterward.
	refresh.call_deferred()


func set_mode(index: int) -> void:
	mode = posmod(index, LABELS.size())
	refresh()


func release() -> void:
	set_mode(0)
	if is_instance_valid(visual):
		var equipment: Node = visual.get("equipment_visuals")
		if equipment and equipment.item_changed.is_connected(_equipment_changed):
			equipment.item_changed.disconnect(_equipment_changed)
	originals.clear()
	visual = null


func refresh() -> void:
	if not is_instance_valid(visual):
		return
	for id in originals.keys():
		if not is_instance_valid(originals[id].shell.get_ref()):
			originals.erase(id)
	var viewport: SubViewport = visual.get("_viewport")
	for node in viewport.find_children("ObjectOutline", "MeshInstance3D", true, false):
		var shell := node as MeshInstance3D
		var material := shell.material_override as ShaderMaterial
		if not material or not shell.get_meta("outline_only", false):
			continue
		var id := shell.get_instance_id()
		if not originals.has(id):
			originals[id] = {"shell": weakref(shell), "material": material,
				"preview": material.duplicate(), "color": _material_ink(String(shell.get_parent().name))}
		var record: Dictionary = originals[id]
		if mode == 0:
			shell.material_override = record.material
		else:
			var preview := record.preview as ShaderMaterial
			preview.set_shader_parameter("outline_source_pixels", float(record.material.get_shader_parameter("outline_source_pixels")) * WIDTH_SCALE)
			var ink: Variant = record.material.get_shader_parameter("outline_color")
			if ink == null:
				ink = Color(0.015, 0.012, 0.012, 1)
			preview.set_shader_parameter("outline_color", record.color if mode == 2 else ink)
			shell.material_override = preview


func _material_ink(mesh_name: String) -> Color:
	var part := mesh_name.to_lower()
	if "sword" in part or "grapple" in part or "metal" in part:
		return Color("394650")
	if "doll" in part or "hand" in part or "wood" in part:
		return Color("4b3928")
	if "boot" in part or "glove" in part or "shield" in part or "leather" in part:
		return Color("483727")
	return Color("303c49")
