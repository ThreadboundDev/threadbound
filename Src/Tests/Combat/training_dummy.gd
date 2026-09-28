class_name TrainingDummy
extends StaticBody2D

@export_range(0.01, 0.3, 0.01) var wiggle_duration := 0.12
@export_range(1.0, 20.0, 0.5) var wiggle_degrees := 7.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hit_flash: HitFlashComponent = $HitFlashComponent
@onready var visuals: Node2D = $Visuals

var _wiggle_tween: Tween


func _ready() -> void:
	health_component.damaged.connect(_on_damaged)


func _on_damaged(damage: DamageData) -> void:
	# Restore immediately so every authored strike can be tested indefinitely.
	health_component.current_health = health_component.max_health
	hit_flash.flash(Color(1.0, 0.92, 0.48, 1.0), 0.09)
	_wiggle()
	CombatFeedback.hit_pause(self, damage.hit_pause)


func _wiggle() -> void:
	if _wiggle_tween and _wiggle_tween.is_valid():
		_wiggle_tween.kill()
	visuals.rotation = 0.0
	var angle := deg_to_rad(wiggle_degrees)
	_wiggle_tween = create_tween()
	_wiggle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_wiggle_tween.tween_property(visuals, "rotation", -angle, wiggle_duration * 0.25)
	_wiggle_tween.tween_property(visuals, "rotation", angle, wiggle_duration * 0.35)
	_wiggle_tween.tween_property(visuals, "rotation", 0.0, wiggle_duration * 0.40)
