class_name GrappleTargetComponent
extends Node

enum WeightClass {
	LIGHT,
	HEAVY,
	ANCHORED
}

@export var weight_class: WeightClass = WeightClass.LIGHT
@export var grapple_damage_enabled := true
@export var attachment_offset := Vector2.ZERO

@onready var grapple_owner: Node2D = get_parent() as Node2D

func get_attachment_position(fallback: Vector2) -> Vector2:
	if not grapple_owner:
		return fallback
	return grapple_owner.to_global(attachment_offset)

func get_hurtbox() -> HurtboxComponent:
	if not grapple_damage_enabled or not grapple_owner:
		return null
	return grapple_owner.get_node_or_null("Hurtbox") as HurtboxComponent

func is_pullable() -> bool:
	return weight_class == WeightClass.LIGHT

func pull_toward(destination: Vector2, speed: float, delta: float) -> float:
	if not grapple_owner:
		return INF

	var to_destination := destination - grapple_owner.global_position
	var distance := to_destination.length()
	if distance <= 0.001:
		return 0.0

	var body := grapple_owner as CharacterBody2D
	if body:
		var motion := to_destination.normalized() * minf(speed * delta, distance)
		body.move_and_collide(motion)
		body.velocity = Vector2.ZERO
	else:
		grapple_owner.global_position = grapple_owner.global_position.move_toward(destination, speed * delta)

	return grapple_owner.global_position.distance_to(destination)
