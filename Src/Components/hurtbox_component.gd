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

	var accepted := true
	if health_component:
		accepted = health_component.apply_damage(damage)

	if accepted:
		hit_received.emit(damage)

	return accepted
