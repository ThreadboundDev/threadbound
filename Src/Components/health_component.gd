class_name HealthComponent
extends Node

const DAMAGE_NUMBER_SCENE := preload("res://Src/UI/DamageNumbers/damage_number.tscn")

signal health_changed(current: int, maximum: int)
signal damaged(damage: DamageData)
signal died(damage: DamageData)

@export var max_health: int = 100:
	set(value):
		max_health = max(1, value)
		current_health = clamp(current_health, 0, max_health)

@export var invincible_after_hit: float = 0.12

var current_health: int
var is_dead := false
var _invincible_timer := 0.0

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta

func configure(maximum: int) -> void:
	max_health = max(1, maximum)
	current_health = max_health
	is_dead = false
	_invincible_timer = 0.0
	health_changed.emit(current_health, max_health)

func apply_damage(damage: DamageData) -> bool:
	if is_dead or _invincible_timer > 0.0:
		return false

	var amount: int = max(0, damage.amount)
	if amount <= 0:
		return false

	current_health = max(0, current_health - amount)
	_invincible_timer = invincible_after_hit
	_spawn_damage_number(amount, damage)
	damaged.emit(damage)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		is_dead = true
		died.emit(damage)

	return true

func _spawn_damage_number(amount: int, damage: DamageData) -> void:
	if not GameplaySettings.damage_numbers:
		return

	var scene_root := get_tree().current_scene
	if not scene_root:
		return

	var spawn_position := damage.hit_position
	if spawn_position == Vector2.ZERO and get_parent() is Node2D:
		spawn_position = (get_parent() as Node2D).global_position
	spawn_position.y -= 24.0

	var damage_number := DAMAGE_NUMBER_SCENE.instantiate() as DamageNumber
	scene_root.add_child(damage_number)
	damage_number.show_damage(amount, spawn_position)

func heal(amount: int) -> void:
	if is_dead:
		return

	current_health = min(max_health, current_health + max(0, amount))
	health_changed.emit(current_health, max_health)
