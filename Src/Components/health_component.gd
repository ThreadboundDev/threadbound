class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(damage: DamageData)
signal died(damage: DamageData)

@export var max_health: int = 3:
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
	damaged.emit(damage)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		is_dead = true
		died.emit(damage)

	return true

func heal(amount: int) -> void:
	if is_dead:
		return

	current_health = min(max_health, current_health + max(0, amount))
	health_changed.emit(current_health, max_health)
