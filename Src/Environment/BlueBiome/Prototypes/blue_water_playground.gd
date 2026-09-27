extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var speed_label: Label = get_node_or_null("HUD/Panel/Margin/Readout") as Label


func _ready() -> void:
	player.debug_blue_water_power_unlocked = true


func _process(_delta: float) -> void:
	if speed_label == null:
		return
	var location := "WATER" if player.is_in_prototype_water() else "AIR"
	speed_label.text = (
		"BLUE WATER + COMBAT PLAYGROUND\n"
		+ "Speed: %4d   State: %s\n" % [roundi(player.velocity.length()), location]
		+ "Move: WASD   Jump: Space   Roll: Shift   Crouch: S\n"
		+ "Attack: LMB   Grapple: RMB   Special: Q   Block: F\n"
		+ "Combat targets are right of spawn; the deep swim basin follows them."
	)
