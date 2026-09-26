extends Node2D

## Place beneath a rectangular water volume; both banks derive from its bounds.
var prompt: Label
var candidate: CharacterBody2D
var direction := 1

func _ready() -> void:
	prompt = Label.new()
	prompt.text = "Dive"
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08))
	prompt.add_theme_constant_override("outline_size", 6)
	prompt.z_index = 40
	add_child(prompt)
	process_priority = -20

func _process(_delta: float) -> void:
	prompt.hide()
	candidate = null
	var water := get_parent() as Area2D
	var size: Vector2 = water.get("size")
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("can_start_bank_dive") or not player.can_start_bank_dive():
			continue
		var local: Vector2 = water.to_local(player.global_position)
		for side in [-1, 1]:
			var bank := Vector2(float(side) * size.x * 0.5, -size.y * 0.5)
			if absf(local.x - bank.x) > 105.0 or absf(local.y - bank.y) > 140.0:
				continue
			if int(player.last_direction) != -side:
				continue
			candidate = player
			direction = -side
			prompt.position = bank + Vector2(-45, -170)
			var binding := "Interact"
			for event in InputMap.action_get_events("interact"):
				if event is InputEventKey:
					binding = OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode)
					break
			prompt.text = "[%s] Dive" % binding
			prompt.show()
			if Input.is_action_just_pressed("interact"):
				player.start_bank_dive(direction)
			return
