@tool
class_name PlayerEquipmentVisuals
extends Node3D
## The presentation for the existing three equipment slots and separate weapon.
## Does not own abilities, unlocks, costs or attack timing.

const SLOTS: Array[StringName] = [&"gloves", &"boots", &"head_chest", &"weapon"]
const DEFAULT_LOADOUT := preload("res://Src/Equipment/Visuals/base_gear_loadout.tres")
const FITTED_LOADOUT := preload("res://Src/Equipment/Visuals/base_blue_gear_loadout.tres")
const MASK_TEST_DIR := "res://Assets/Threadborne/Player/LocalDoll/Equipment/FittedSets/"
const MASK_TEST_IDS := [&"loomed", &"hermit"]
const CLOTH_MOTION := preload("res://Src/Equipment/Visuals/equipment_cloth_motion.gd")

signal item_changed(slot: StringName, item: EquipmentVisualDefinition)

var skeleton: Skeleton3D
var equipped: Dictionary = {}
var _roots: Dictionary = {}
var _variants: Dictionary = {}
var _needle_meshes: Array[MeshInstance3D] = []
var _grapple_stowed := true
var cloth_motion: EquipmentClothMotion


static func default_assets_available() -> bool:
	if fitted_outfits_available():
		var weapon := DEFAULT_LOADOUT.get_meta("weapon") as EquipmentVisualDefinition
		return weapon.is_available()
	for slot in SLOTS:
		var item := DEFAULT_LOADOUT.get_meta(String(slot), null) as EquipmentVisualDefinition
		if not item or item.slot != String(slot) or not item.is_available():
			return false
	return true


static func fitted_outfits_available() -> bool:
	for index in 6:
		var item := FITTED_LOADOUT.get_meta("item_%d" % index) as EquipmentVisualDefinition
		if not item or not item.is_available():
			return false
	return true


func initialize(target: Skeleton3D) -> bool:
	skeleton = target
	if not skeleton or not default_assets_available():
		return false
	if fitted_outfits_available():
		for index in 6:
			register_variant(SLOTS[index % 3], index, FITTED_LOADOUT.get_meta("item_%d" % index) as EquipmentVisualDefinition)
	var manager := get_node_or_null("/root/EquipManager") if not Engine.is_editor_hint() else null
	for slot_type in SLOTS.size():
		var slot := SLOTS[slot_type]
		var item := DEFAULT_LOADOUT.get_meta(String(slot)) as EquipmentVisualDefinition
		if slot_type < 3:
			var index := int(manager.current_equip[slot_type]) if manager else slot_type
			item = _variants.get(Vector2i(slot_type, index), _variants.get(Vector2i(slot_type, slot_type), item))
		if not equip(item):
			return false
	if manager:
		manager.equip_changed.connect(_on_gameplay_equipment_changed)
	return true


func equip(item: EquipmentVisualDefinition) -> bool:
	if not skeleton or not item or (not SLOTS.has(StringName(item.slot)) and item.slot != "mask_preview") or not item.is_available():
		return false
	# Prepare the whole outfit first. A missing/invalid component leaves the old
	# item installed; cowl, tunic and pants never switch partially.
	var prepared := Node3D.new()
	prepared.name = String(item.item_id)
	add_child(prepared)
	prepared.hide()
	for path in item.model_paths:
		var scene := load(path) as PackedScene
		if not scene:
			prepared.free()
			return false
		var source := scene.instantiate() as Node3D
		if not source:
			prepared.free()
			return false
		prepared.add_child(source)
		var meshes := source.find_children("*", "MeshInstance3D", true, false)
		if meshes.is_empty():
			prepared.free()
			return false
		for node in meshes:
			var mesh := node as MeshInstance3D
			var donor := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
			if not mesh.skin or not donor:
				prepared.free()
				return false
			if not CLOTH_MOTION.register_bones(skeleton,donor):
				prepared.free()
				return false
			if donor.find_bone(CLOTH_MOTION.ROOT_BONE) >= 0 or donor.find_bone(CLOTH_MOTION.BASE_ROOT) >= 0:
				prepared.set_meta("cloth_bones",true)
			var skin := Skin.new()
			for index in mesh.skin.get_bind_count():
				var bone_name := mesh.skin.get_bind_name(index)
				if bone_name.is_empty():
					var bone_index := mesh.skin.get_bind_bone(index)
					if bone_index < 0 or bone_index >= donor.get_bone_count():
						prepared.free()
						return false
					bone_name = donor.get_bone_name(bone_index)
				var target_index := skeleton.find_bone(bone_name)
				var donor_index := donor.find_bone(bone_name)
				if target_index < 0 or donor_index < 0:
					prepared.free()
					return false
				if not donor.get_bone_global_rest(donor_index).is_equal_approx(skeleton.get_bone_global_rest(target_index)):
					prepared.free()
					return false
				skin.add_named_bind(bone_name, mesh.skin.get_bind_pose(index))
			mesh.reparent(prepared, true)
			mesh.skin = skin
			mesh.skeleton = mesh.get_path_to(skeleton)
		# All meshes now use the live skeleton; discard donor skeletons/players.
		source.free()
	var slot := StringName(item.slot)
	if _roots.has(slot):
		_retire(_roots[slot])
	_roots[slot] = prepared
	equipped[slot] = item
	_update_cloth_motion()
	if slot == &"gloves":
		_needle_meshes.clear()
		for node in prepared.find_children("Grapple_Needle_*", "MeshInstance3D", true, false):
			_needle_meshes.append(node as MeshInstance3D)
			(node as MeshInstance3D).visible = _grapple_stowed
	_update_body_coverage()
	prepared.show()
	item_changed.emit(slot, item)
	return true


static func mask_preview_available(id: StringName) -> bool:
	return OS.get_cmdline_user_args().has("--equipment-art-test") and MASK_TEST_IDS.has(id) \
		and ResourceLoader.exists(MASK_TEST_DIR + String(id) + "_mask.glb")


func toggle_mask_preview(id: StringName) -> bool:
	if not mask_preview_available(id):
		return false
	var current := equipped.get(&"mask_preview") as EquipmentVisualDefinition
	if current and current.item_id == id:
		clear_slot(&"mask_preview")
		return true
	var item := EquipmentVisualDefinition.new()
	item.item_id = id
	item.slot = "mask_preview"
	item.model_paths = PackedStringArray([MASK_TEST_DIR + String(id) + "_mask.glb"])
	return equip(item)


func clear_slot(slot: StringName) -> void:
	if not _roots.has(slot):
		return
	_retire(_roots[slot])
	_roots.erase(slot)
	equipped.erase(slot)
	_update_cloth_motion()
	if slot == &"gloves":
		_needle_meshes.clear()
	_update_body_coverage()
	item_changed.emit(slot, null)


func _update_cloth_motion() -> void:
	if not cloth_motion and (skeleton.find_bone(CLOTH_MOTION.ROOT_BONE) >= 0 or skeleton.find_bone(CLOTH_MOTION.BASE_ROOT) >= 0):
		cloth_motion = CLOTH_MOTION.new()
		cloth_motion.initialize(skeleton)
	if cloth_motion:
		var outfit := _roots.get(&"head_chest") as Node3D
		var item := equipped.get(&"head_chest") as EquipmentVisualDefinition
		var profile: StringName = &""
		if outfit != null and outfit.get_meta("cloth_bones",false) and item != null:
			if item.item_id == &"blue_fitted_head_chest":
				profile = &"blue"
			elif item.item_id == &"base_fitted_head_chest":
				profile = &"base"
		cloth_motion.configure(profile)


func _retire(old: Node3D) -> void:
	# Detach immediately for an atomic swap, then let the render server release
	# old mesh/material dependencies at the frame boundary.
	var materials: Array[Material] = []
	for node in old.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material:
				materials.append(material)
	old.hide()
	remove_child(old)
	old.queue_free()
	# Material RIDs can still be referenced by the preceding render submission.
	# Hold their resources through the next submission after freeing the nodes.
	var tree := get_tree()
	await tree.process_frame
	await tree.process_frame
	materials.clear()


func _update_body_coverage() -> void:
	var hidden: Dictionary = {}
	for item: EquipmentVisualDefinition in equipped.values():
		for mesh_name in item.hidden_body_meshes:
			hidden[mesh_name] = true
	for node in get_parent().find_children("Doll_Covered_*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = not hidden.has(String(node.name))
	for node in get_parent().find_children("Threadborne_Doll", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = not hidden.has("Threadborne_Doll")


func get_blade_points() -> PackedVector3Array:
	var item := equipped.get(&"weapon") as EquipmentVisualDefinition
	if not item:
		return PackedVector3Array()
	var bone := skeleton.find_bone(item.blade_bone)
	if bone < 0:
		return PackedVector3Array()
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	return PackedVector3Array([pose * item.blade_base, pose * item.blade_tip])


func get_grapple_origin() -> Vector3:
	var item := equipped.get(&"gloves") as EquipmentVisualDefinition
	if not item:
		return Vector3.INF
	var bone := skeleton.find_bone(item.grapple_bone)
	if bone < 0:
		return Vector3.INF
	return skeleton.global_transform * skeleton.get_bone_global_pose(bone) * item.grapple_origin


func set_grapple_stowed(stowed: bool) -> void:
	if _grapple_stowed == stowed:
		return
	_grapple_stowed = stowed
	for mesh in _needle_meshes:
		mesh.visible = stowed


func register_variant(slot: StringName, gameplay_index: int, item: EquipmentVisualDefinition) -> bool:
	if not item or item.slot != String(slot) or not SLOTS.has(slot):
		return false
	var slot_type := SLOTS.find(slot)
	if slot_type >= 3 or gameplay_index < 0 or gameplay_index % 3 != slot_type:
		return false
	_variants[Vector2i(slot_type, gameplay_index)] = item
	return true


func _on_gameplay_equipment_changed(slot_type: int, gameplay_index: int) -> void:
	# Existing indices are gloves, boots, head/chest. Weapon presentation is
	# independently equipped with equip(); it never changes those three entries.
	if slot_type < 0 or slot_type >= 3:
		return
	var slot := SLOTS[slot_type]
	var item := _variants.get(Vector2i(slot_type, gameplay_index)) as EquipmentVisualDefinition
	if not item:
		item = _variants.get(Vector2i(slot_type, slot_type), DEFAULT_LOADOUT.get_meta(String(slot))) as EquipmentVisualDefinition
	if equipped.get(slot) != item:
		equip(item)
