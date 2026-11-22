extends "res://Src/Characters/Player/player_live_3d_visual.gd"
## Demo 2.0 fitting trial. Apply the two art variants to this character instance.

const TRIAL_FOLDER := "res://Assets/Threadborne/Player/LocalDoll/Equipment/OutfitATrial/"

func _ready() -> void:
	super()
	if not equipment_visuals:
		push_error("Outfit A trial needs the fitted player.")
		return
	for index: int in [0, 2]:
		var item := PlayerEquipmentVisuals.FITTED_LOADOUT.get_meta("item_%d" % index).duplicate() as EquipmentVisualDefinition
		if index == 0:
			item.model_paths = PackedStringArray([TRIAL_FOLDER + "base_grapple_glove.glb"])
			item.hidden_body_meshes = PackedStringArray()
		else:
			item.model_paths = PackedStringArray([TRIAL_FOLDER + "base_outfit_a.glb"])
		equipment_visuals.register_variant(StringName(item.slot), index, item)
		if not equipment_visuals.equip(item):
			push_error("Outfit A trial could not bind " + item.slot)
