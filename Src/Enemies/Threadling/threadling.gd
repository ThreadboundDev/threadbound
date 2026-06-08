class_name Threadling
extends EnemyBase

func _ready() -> void:
	super._ready()
	add_to_group("threadlings")

func begin_attack() -> void:
	super.begin_attack()
	# Placeholder hook for future attack animation.
