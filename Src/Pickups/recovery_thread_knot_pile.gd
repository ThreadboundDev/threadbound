extends ThreadKnotPickup
class_name RecoveryThreadKnotPile

func _ready() -> void:
	super._ready()
	add_to_group("recovery_thread_knot_piles")
	if sprite:
		_base_scale = sprite.scale * 1.65
		sprite.scale = _base_scale

func _collect(player: Node) -> void:
	if _is_collected:
		return
	if not player or not player.has_method("recover_dropped_thread_knots"):
		return
	var recovered_amount := int(player.call("recover_dropped_thread_knots"))
	if recovered_amount <= 0:
		queue_free()
		return

	# DemoProgress has already restored the wallet atomically. Let the base
	# pickup handle its familiar audio and collection fade without adding twice.
	value = 0
	super._collect(player)
