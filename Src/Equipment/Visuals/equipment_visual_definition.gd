@tool
class_name EquipmentVisualDefinition
extends Resource
## One swappable item. Several model files can form a single head/chest outfit.
## Models are fitted to the player's rest skeleton and use named skin bindings.

@export var item_id: StringName
@export_enum("gloves", "boots", "head_chest", "weapon") var slot := "head_chest"
@export var model_paths: PackedStringArray
@export var hidden_body_meshes: PackedStringArray
@export var blade_bone: StringName = &"hand.R"
@export var blade_base := Vector3.ZERO
@export var blade_tip := Vector3.ZERO
@export var grapple_bone: StringName = &"forearm.L"
@export var grapple_origin := Vector3.ZERO


func is_available() -> bool:
	if item_id.is_empty() or model_paths.is_empty():
		return false
	for path in model_paths:
		if not ResourceLoader.exists(path):
			return false
	return true
