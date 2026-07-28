extends Area2D

@export var boss_path: NodePath
@export var entrance_door_path: NodePath
@export var camera_path: NodePath
@export var boss_camera_zoom := Vector2(0.72, 0.72)
@export_range(0.1, 2.0, 0.05) var boss_zoom_duration := 0.75

var _locked := false
var _camera_original_zoom := Vector2.ONE
var _zoom_tween: Tween

@onready var boss: Node = get_node_or_null(boss_path)
@onready var entrance_door: Node = get_node_or_null(entrance_door_path)
@onready var boss_camera := get_node_or_null(camera_path) as Camera2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if boss_camera:
		_camera_original_zoom = boss_camera.zoom
	if boss and boss.get("health_component"):
		var health_component := boss.get("health_component") as HealthComponent
		if health_component and not health_component.died.is_connected(_on_boss_died):
			health_component.died.connect(_on_boss_died)

func _on_body_entered(body: Node2D) -> void:
	if _locked or not body.is_in_group("player"):
		return

	_locked = true
	if boss_camera:
		_camera_original_zoom = boss_camera.zoom
	if entrance_door and entrance_door.has_method("lock_closed_for_boss"):
		entrance_door.lock_closed_for_boss()
	_tween_camera_zoom(boss_camera_zoom)

func _on_boss_died(_damage: DamageData) -> void:
	if entrance_door and entrance_door.has_method("open_silently"):
		entrance_door.open_silently()
	_tween_camera_zoom(_camera_original_zoom)

func _tween_camera_zoom(target_zoom: Vector2) -> void:
	if not boss_camera:
		return
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()

	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(
		boss_camera,
		"zoom",
		target_zoom,
		boss_zoom_duration
	)
