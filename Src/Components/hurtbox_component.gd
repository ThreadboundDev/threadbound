class_name HurtboxComponent
extends Area2D

signal hit_received(damage: DamageData)

@export var health_component_path: NodePath
@export var hurtbox_owner_path: NodePath

@onready var health_component: HealthComponent = get_node_or_null(health_component_path) as HealthComponent
@onready var hurtbox_owner: Node = get_node_or_null(hurtbox_owner_path)

func _ready() -> void:
	monitoring = false
	monitorable = true

func receive_hit(damage: DamageData) -> bool:
	if damage.source and hurtbox_owner and damage.source == hurtbox_owner:
		return false
	if damage and not damage.allow_friendly_fire and _is_same_damage_faction(damage.source, hurtbox_owner):
		return false
	if _should_ignore_health_damage(damage):
		_receive_ignored_health_hit(damage)
		hit_received.emit(damage)
		return true

	var accepted := true
	if health_component:
		accepted = health_component.apply_damage(damage)

	if accepted:
		hit_received.emit(damage)

	return accepted

func _is_same_damage_faction(source: Node, receiver: Node) -> bool:
	if not source or not receiver:
		return false

	return source.is_in_group("enemies") and receiver.is_in_group("enemies")

func _should_ignore_health_damage(damage: DamageData) -> bool:
	if not hurtbox_owner or not hurtbox_owner.has_method("should_ignore_health_damage"):
		return false

	return hurtbox_owner.should_ignore_health_damage(damage)

func _receive_ignored_health_hit(damage: DamageData) -> void:
	if hurtbox_owner and hurtbox_owner.has_method("receive_ignored_health_hit"):
		hurtbox_owner.receive_ignored_health_hit(damage)
