class_name EquipmentPattern
extends Resource

@export var id: StringName
@export var display_name := "Pattern"
@export_multiline var description := ""
@export var inventory_icon: Texture2D
@export var hud_overlay: Texture2D
@export var textile_texture: Texture2D
@export_range(0.1, 3.0, 0.01) var action_point_recharge_multiplier := 1.0
@export_range(0.1, 3.0, 0.01) var momentum_generation_multiplier := 1.0

func get_bonus_description() -> String:
	var bonuses: Array[String] = []
	if not is_equal_approx(action_point_recharge_multiplier, 1.0):
		bonuses.append("%+d%% AP recharge" % roundi((action_point_recharge_multiplier - 1.0) * 100.0))
	if not is_equal_approx(momentum_generation_multiplier, 1.0):
		bonuses.append("%+d%% momentum generation" % roundi((momentum_generation_multiplier - 1.0) * 100.0))
	return ", ".join(bonuses)
