extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var speed_label: Label = $HUD/Panel/Margin/Readout


func _ready() -> void:
	player.debug_blue_water_power_unlocked = true


func _process(_delta: float) -> void:
	var location := "WATER" if player.is_in_prototype_water() else "AIR"
	speed_label.text = (
		"BLUE WATER PLAYGROUND\n"
		+ "Speed: %4d   State: %s\n" % [roundi(player.velocity.length()), location]
		+ "Move: WASD / stick   Dash: Shift / B   Jump: Space / A\n"
		+ "Bulbs break only above their displayed impact speed.\n"
		+ "Walls drain speed. Grapple is disabled underwater."
	)
