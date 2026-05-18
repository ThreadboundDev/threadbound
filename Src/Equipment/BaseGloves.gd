class_name BaseGloves
extends Node2D

var player: CharacterBody2D = null

@onready var equipment: Node2D = $Equipment
@onready var animation_player: AnimationPlayer = $Equipment/AnimationPlayer
@onready var right_hand_anchor: Marker2D = $Equipment/RightHandAnchor
@onready var rope_hang_anchor: Node2D = $Equipment/RightHandAnchor/RopeHangAnchor
@onready var grapple_origin: Marker2D = $Equipment/RightHandAnchor/GrappleOrigin

func _ready() -> void:
	visible = true

func on_equipped() -> void:
	visible = true

	if rope_hang_anchor and rope_hang_anchor.has_method("reset_rope"):
		rope_hang_anchor.reset_rope()

func on_unequipped() -> void:
	queue_free()

func play_equipment_anim(anim_name: String) -> void:
	if not animation_player:
		return

	if not animation_player.has_animation(anim_name):
		print("Missing glove anim: ", anim_name)
		return

	animation_player.stop()
	animation_player.play(anim_name)
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)

func get_grapple_origin_global_position() -> Vector2:
	if grapple_origin:
		return grapple_origin.global_position

	if player:
		return player.global_position

	return global_position

func thread_mechanic(_delta: float) -> void:
	pass

func process_passive(_delta: float) -> void:
	pass

func on_ability_cooldown_complete() -> void:
	pass
