extends Area2D

@export_group("Encounter References")
@export var boss_path: NodePath
@export var entrance_door_path: NodePath
@export var camera_path: NodePath
@export var room_grade_path: NodePath
@export var demo_ending_exit_path: NodePath

@export_group("Demo Completion")
@export_range(0.0, 10.0, 0.05) var ending_exit_reveal_delay := 0.15

@export_group("Boss Death Cinematic")
@export var death_camera_zoom := Vector2(0.94, 0.94)
@export var death_camera_focus_offset := Vector2(0.0, -145.0)
@export_range(0.05, 2.0, 0.05) var death_camera_focus_duration := 0.65
@export_range(0.05, 2.0, 0.05) var death_camera_return_duration := 0.85

@export_group("Combat Camera")
@export var boss_camera_zoom := Vector2(0.72, 0.72)
@export_range(0.1, 2.0, 0.05) var boss_zoom_duration := 0.75

@export_group("Boss Introduction")
@export var cinematic_enabled := true
@export var cinematic_camera_zoom := Vector2(1.08, 1.08)
@export var cinematic_boss_focus_offset := Vector2(0.0, -150.0)
@export_range(0.0, 1.0, 0.05) var cinematic_start_hold := 0.15
@export_range(0.05, 2.0, 0.05) var cinematic_pan_duration := 0.90
@export_range(0.05, 1.0, 0.05) var cinematic_hud_reveal_duration := 0.40
@export_range(0.0, 2.0, 0.05) var cinematic_boss_hold := 0.65
@export_range(0.05, 2.0, 0.05) var cinematic_return_duration := 0.80
@export_range(0.05, 3.0, 0.05) var cinematic_grade_duration := 1.20

var _locked := false
var _intro_running := false
var _camera_original_zoom := Vector2.ONE
var _zoom_tween: Tween
var _cinematic_tween: Tween
var _cinematic_player: Node
var _camera_follow: RemoteTransform2D
var _camera_follow_was_updating := true
var _player_was_processing := true
var _player_was_physics_processing := true

@onready var boss: Node = get_node_or_null(boss_path)
@onready var entrance_door: Node = get_node_or_null(entrance_door_path)
@onready var boss_camera := get_node_or_null(camera_path) as Camera2D
@onready var room_grade: Node = get_node_or_null(room_grade_path)
@onready var demo_ending_exit: Node = get_node_or_null(demo_ending_exit_path)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if boss_camera:
		_camera_original_zoom = boss_camera.zoom
	if boss and boss.get("health_component"):
		var health_component := boss.get("health_component") as HealthComponent
		if health_component and not health_component.died.is_connected(_on_boss_died):
			health_component.died.connect(_on_boss_died)

func _exit_tree() -> void:
	_restore_player_control()
	_restore_camera_follow()

func _on_body_entered(body: Node2D) -> void:
	if _locked or not body.is_in_group("player"):
		return

	_locked = true
	if boss_camera:
		_camera_original_zoom = boss_camera.zoom
	if cinematic_enabled:
		_run_boss_intro.call_deferred(body)
		return

	_lock_entrance_door()
	_start_room_grade()
	_complete_boss_intro(body)
	_tween_camera_zoom(boss_camera_zoom)

func _run_boss_intro(player: Node2D) -> void:
	if _intro_running or not is_instance_valid(player):
		return

	_intro_running = true
	_lock_player_control(player)
	_disable_camera_follow(player)
	_prepare_boss_intro()
	_lock_entrance_door()

	if cinematic_start_hold > 0.0:
		await get_tree().create_timer(cinematic_start_hold).timeout
	if not is_inside_tree():
		return

	_start_room_grade()
	var boss_node := boss as Node2D
	if boss_camera and is_instance_valid(boss_node):
		await _tween_cinematic_camera(
			boss_node.global_position + cinematic_boss_focus_offset,
			cinematic_camera_zoom,
			cinematic_pan_duration
		)

	_reveal_boss_hud()
	if cinematic_boss_hold > 0.0:
		await get_tree().create_timer(
			cinematic_hud_reveal_duration + cinematic_boss_hold
		).timeout
	if not is_inside_tree():
		return

	if boss_camera and is_instance_valid(player):
		await _tween_cinematic_camera(
			player.global_position,
			boss_camera_zoom,
			cinematic_return_duration
		)

	_restore_camera_follow()
	_complete_boss_intro(player)
	_restore_player_control()
	_intro_running = false

func _prepare_boss_intro() -> void:
	if boss and boss.has_method("begin_encounter_intro"):
		boss.call("begin_encounter_intro")

func _reveal_boss_hud() -> void:
	if boss and boss.has_method("reveal_encounter_intro_hud"):
		boss.call(
			"reveal_encounter_intro_hud",
			cinematic_hud_reveal_duration
		)

func _complete_boss_intro(player: Node2D) -> void:
	if boss and boss.has_method("complete_encounter_intro"):
		boss.call("complete_encounter_intro", player)

func _lock_entrance_door() -> void:
	if entrance_door and entrance_door.has_method("lock_closed_for_boss"):
		entrance_door.call("lock_closed_for_boss")

func _start_room_grade() -> void:
	if room_grade and room_grade.has_method("start_boss_intro_grade"):
		room_grade.call(
			"start_boss_intro_grade",
			cinematic_grade_duration
		)

func _lock_player_control(player: Node) -> void:
	_cinematic_player = player
	_player_was_processing = player.is_processing()
	_player_was_physics_processing = player.is_physics_processing()
	player.set_process(false)
	player.set_physics_process(false)
	if "velocity" in player:
		player.set("velocity", Vector2.ZERO)

func _restore_player_control() -> void:
	if not is_instance_valid(_cinematic_player):
		_cinematic_player = null
		return
	_cinematic_player.set_process(_player_was_processing)
	_cinematic_player.set_physics_process(_player_was_physics_processing)
	_cinematic_player = null

func _disable_camera_follow(player: Node) -> void:
	_camera_follow = player.get_node_or_null("RemoteTransform2D") as RemoteTransform2D
	if not _camera_follow:
		return
	_camera_follow_was_updating = _camera_follow.update_position
	_camera_follow.update_position = false

func _restore_camera_follow() -> void:
	if not is_instance_valid(_camera_follow):
		_camera_follow = null
		return
	_camera_follow.update_position = _camera_follow_was_updating
	_camera_follow = null

func _tween_cinematic_camera(
	target_position: Vector2,
	target_zoom: Vector2,
	duration: float
) -> void:
	if not boss_camera:
		return
	if _cinematic_tween and _cinematic_tween.is_valid():
		_cinematic_tween.kill()

	_cinematic_tween = create_tween()
	_cinematic_tween.set_parallel(true)
	_cinematic_tween.set_trans(Tween.TRANS_CUBIC)
	_cinematic_tween.set_ease(Tween.EASE_IN_OUT)
	_cinematic_tween.tween_property(
		boss_camera,
		"global_position",
		target_position,
		duration
	)
	_cinematic_tween.tween_property(
		boss_camera,
		"zoom",
		target_zoom,
		duration
	)
	await _cinematic_tween.finished

func _on_boss_died(_damage: DamageData) -> void:
	_run_boss_death_cinematic.call_deferred()

func _run_boss_death_cinematic() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		_lock_player_control(player)
		_disable_camera_follow(player)

	var presentation_duration := 0.0
	if boss and boss.has_method("get_death_presentation_duration"):
		presentation_duration = float(boss.call("get_death_presentation_duration"))

	if boss_camera:
		var zoom_tween := create_tween()
		zoom_tween.set_trans(Tween.TRANS_CUBIC)
		zoom_tween.set_ease(Tween.EASE_IN_OUT)
		zoom_tween.tween_property(
			boss_camera,
			"zoom",
			death_camera_zoom,
			death_camera_focus_duration
		)

	var elapsed := 0.0
	while elapsed < presentation_duration and is_inside_tree():
		await get_tree().process_frame
		var delta := get_process_delta_time()
		elapsed += delta
		if boss_camera and boss is Node2D and is_instance_valid(boss):
			boss_camera.global_position = (
				(boss as Node2D).global_position + death_camera_focus_offset
			)
	if not is_inside_tree():
		return

	if boss_camera and is_instance_valid(player):
		await _tween_cinematic_camera(
			player.global_position,
			_camera_original_zoom,
			death_camera_return_duration
		)
	_restore_camera_follow()
	_restore_player_control()
	DemoProgress.unlock_lore(&"proto_weaver")
	if entrance_door and entrance_door.has_method("open_silently"):
		entrance_door.open_silently()
	_reveal_demo_ending_exit()

func _reveal_demo_ending_exit() -> void:
	if ending_exit_reveal_delay > 0.0:
		await get_tree().create_timer(ending_exit_reveal_delay).timeout
	if is_inside_tree() and demo_ending_exit and demo_ending_exit.has_method("reveal"):
		demo_ending_exit.call("reveal")

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

func is_intro_running() -> bool:
	return _intro_running
