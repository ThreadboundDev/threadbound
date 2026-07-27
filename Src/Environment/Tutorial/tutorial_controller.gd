extends Node

signal tutorial_completed

const TutorialPromptOverlayScene := preload("res://Src/UI/Tutorial/tutorial_prompt_overlay.gd")

const INPUT_PLACEHOLDER_ACTIONS := {
	"{move_left}": "move_left",
	"{move_right}": "move_right",
	"{move_up}": "move_up",
	"{move_down}": "move_down",
	"{jump}": "Jump",
	"{dash}": "Dash",
	"{grapple}": "Grapple",
	"{attack}": "Attack",
	"{special_attack}": "SpecialAttack",
	"{interact}": "interact",
	"{inventory}": "open_inventory",
	"{map}": "open_map",
	"{lore}": "open_lore",
	"{controls}": "open_controls",
	"{pause}": "ui_cancel",
}

const INPUT_PLACEHOLDER_FALLBACKS := {
	"{move_left}": "A",
	"{move_right}": "D",
	"{move_up}": "W",
	"{move_down}": "S",
	"{jump}": "SPACE",
	"{dash}": "SHIFT",
	"{grapple}": "RMB",
	"{attack}": "LMB",
	"{special_attack}": "Q",
	"{interact}": "E",
	"{inventory}": "I",
	"{map}": "M",
	"{lore}": "L",
	"{controls}": "C",
	"{pause}": "ESC",
}

enum TutorialStep {
	HUD_HP,
	HUD_ACTION_POINTS,
	HUD_MOMENTUM,
	MOVE,
	JUMP,
	AIR_JUMP,
	DASH,
	GRAPPLE,
	ATTACK,
	MENUS,
	COMBAT,
	THREAD_KNOTS,
	SAVE_POINT,
	COMPLETE,
	DONE,
}

@export var tutorial_enabled := true
@export var player_path: NodePath = ^"../Player"
@export var combat_hud_path: NodePath = ^"../HUD/CombatHUD"
@export var tutorial_save_point_path: NodePath
@export var tutorial_save_point_marker_path: NodePath
@export var tutorial_player_respawn_marker_path: NodePath
@export var enemy_parent_path: NodePath = ^"../WorldArt/Enemies"
@export var tutorial_enemy_scene: PackedScene
@export var tutorial_enemy_spawn_marker_path: NodePath
@export var tutorial_enemy_spawn_position := Vector2(-2800.0, -520.0)
@export var hide_save_point_until_combat_complete := true
@export var move_save_point_to_marker_on_reveal := false

@export_group("Prompt Layout")
@export var prompt_position := Vector2(86.0, 748.0)
@export var prompt_size := Vector2(660.0, 122.0)
@export var bottom_prompt_margin := 84.0
@export var hud_prompt_position := Vector2(560.0, 170.0)
@export var hud_prompt_size := Vector2(680.0, 104.0)
@export var hp_spotlight_rect := Rect2(220.0, 100.0, 442.0, 47.0)
@export var hp_pointer_start := Vector2(610.0, 220.0)
@export var hp_pointer_end := Vector2(430.0, 126.0)
@export var action_points_spotlight_rect := Rect2(12.0, 12.0, 132.0, 294.0)
@export var action_points_pointer_start := Vector2(560.0, 260.0)
@export var action_points_pointer_end := Vector2(76.0, 154.0)
@export var momentum_spotlight_rect := Rect2(220.0, 128.0, 430.0, 31.0)
@export var momentum_pointer_start := Vector2(610.0, 188.0)
@export var momentum_pointer_end := Vector2(430.0, 162.0)
@export var thread_knot_spotlight_rect := Rect2(1544.0, 946.0, 376.0, 122.0)
@export var thread_knot_pointer_start := Vector2(1040.0, 810.0)
@export var thread_knot_pointer_end := Vector2(1736.0, 1004.0)
@export var save_menu_prompt_position := Vector2(220.0, 822.0)
@export var save_menu_prompt_size := Vector2(620.0, 116.0)

@export_group("Step Text")
@export_multiline var hp_text := "This is your health. If it empties, your Threadborne falls. Click or press {interact} to continue."
@export_multiline var action_points_text := "These are Action Points. Weapon skills, air jumps, grapples, dashes, and other abilities spend them, then they recharge over time. Click or press {interact} to continue."
@export_multiline var momentum_text := "This is Momentum. Movement, jumps, dashes, grapples, and attacks fill it. When full, you enter Flow State. Click or press {interact} to continue."
@export_multiline var move_text := "Press {move_left} or {move_right} to move across the room."
@export_multiline var jump_text := "Press {jump} to jump {jump_goal} times. {jump_progress}/{jump_goal}"
@export_multiline var air_jump_text := "Press {jump} while airborne to air jump {air_jump_goal} times. {air_jump_progress}/{air_jump_goal}"
@export_multiline var dash_text := "Press {dash} to dash {dash_goal} times. {dash_progress}/{dash_goal}"
@export_multiline var grapple_text := "Press {grapple} to fire the grapple {grapple_goal} times. {grapple_progress}/{grapple_goal}"
@export_multiline var attack_text := "Press {attack} to attack with the shuttle {attack_goal} times. {attack_progress}/{attack_goal}"
@export_multiline var menu_text := "Press {inventory}, {map}, {controls}, or {pause} to open your menus."
@export_multiline var combat_text := "Press {attack} to defeat the Threadling. Movement and attacks both build momentum."
@export_multiline var thread_knot_text := "These are Thread Knots. They are used to purchase items and level up. Click or press {interact} to continue."
@export_multiline var save_point_text := "Press {interact} near the Blossom to rest, recover, save, and reset the world."
@export_multiline var save_point_weave_text := "Choose WEAVE to spend a Thread Knot and strengthen your Threadborne."
@export_multiline var save_point_reflect_text := "Now choose REFLECT to rest, recover, save, and reset the world."
@export_multiline var complete_text := "The first weave opens. Continue into the chamber below."

@export_group("Step Requirements")
@export var momentum_intro_seconds := 4.0
@export var menu_intro_seconds := 5.0
@export var move_intro_min_seconds := 1.0
@export var move_required_distance := 260.0
@export_range(1, 5, 1) var required_jumps := 3
@export_range(1, 5, 1) var required_air_jumps := 2
@export_range(1, 5, 1) var required_dashes := 2
@export_range(1, 5, 1) var required_grapples := 2
@export_range(1, 5, 1) var required_attacks := 3
@export var jump_count_cooldown := 0.18
@export var jump_leave_floor_buffer := 0.25
@export var dash_count_cooldown := 0.45
@export var grapple_count_cooldown := 1.25
@export var attack_count_cooldown := 0.35

@export_group("Optional Unlock Targets")
@export var reveal_on_complete_paths: Array[NodePath] = []
@export var disable_until_complete_paths: Array[NodePath] = []

@export_group("Tutorial Room Floor")
@export var tutorial_pre_floor_paths: Array[NodePath] = []
@export var tutorial_floor_opens_after_save_point := true

var _player: Node2D
var _combat_hud: Node
var _save_point: Node
var _prompt: TutorialPromptOverlay
var _step: TutorialStep = TutorialStep.HUD_HP
var _step_timer := 0.0
var _step_start_position := Vector2.ZERO
var _last_player_position := Vector2.ZERO
var _move_distance_accumulated := 0.0
var _jump_count := 0
var _air_jump_count := 0
var _dash_count := 0
var _grapple_count := 0
var _attack_count := 0
var _tutorial_enemy: Node
var _save_point_revealed := false
var _combat_completion_handled := false
var _current_prompt_text := ""
var _current_prompt_pointer := false
var _current_prompt_position := Vector2.ZERO
var _current_prompt_size := Vector2.ZERO
var _current_world_pointer_target: Node2D
var _current_input_family := &"keyboard_mouse"
var _click_advance_requested := false
var _jump_count_ready_at := 0.0
var _jump_press_buffer_until := 0.0
var _air_jump_count_ready_at := 0.0
var _dash_count_ready_at := 0.0
var _grapple_count_ready_at := 0.0
var _attack_count_ready_at := 0.0
var _tutorial_floor_opened := false
var _jump_was_on_floor := false
var _air_jump_was_available := false
var _thread_knot_prompt_seen := false
var _tutorial_weave_spent := false
var _tutorial_rest_completed := false

func _ready() -> void:
	if not tutorial_enabled:
		return

	add_to_group("tutorial_controllers")
	_player = get_node_or_null(player_path) as Node2D
	_combat_hud = get_node_or_null(combat_hud_path)
	_save_point = get_node_or_null(tutorial_save_point_path)
	if not _player:
		push_warning("TutorialController: player_path is not assigned.")
		return
	if _player.has_signal("stat_upgraded"):
		var stat_upgraded_callback := Callable(self, "_on_player_stat_upgraded")
		if not _player.is_connected("stat_upgraded", stat_upgraded_callback):
			_player.connect("stat_upgraded", stat_upgraded_callback)

	var has_scene_checkpoint := _has_checkpoint_in_current_scene()
	if has_scene_checkpoint and not DemoProgress.has_tutorial_completion_record():
		# Saves created before tutorial completion was persisted came from players
		# who had already reached the tutorial Blossom.
		DemoProgress.mark_tutorial_completed()
	if DemoProgress.is_tutorial_completed():
		_restore_completed_tutorial_state()
		return

	_prompt = TutorialPromptOverlayScene.new()
	get_tree().current_scene.call_deferred("add_child", _prompt)
	_connect_input_binding_updates()
	if has_scene_checkpoint:
		call_deferred("_resume_tutorial_at_save_point")
	else:
		call_deferred("_begin_tutorial")

func _has_checkpoint_in_current_scene() -> bool:
	var current_scene := get_tree().current_scene
	return (
		DemoProgress.has_checkpoint()
		and current_scene
		and current_scene.scene_file_path == DemoProgress.get_checkpoint_scene_path()
	)

func _resume_tutorial_at_save_point() -> void:
	_set_tutorial_floor_open(false)
	for path in disable_until_complete_paths:
		_set_node_enabled(get_node_or_null(path), false)
	for path in reveal_on_complete_paths:
		_set_revealed(get_node_or_null(path), false, true)
	_set_step(TutorialStep.SAVE_POINT)

func _restore_completed_tutorial_state() -> void:
	if move_save_point_to_marker_on_reveal:
		_move_save_point_to_tutorial_marker()
	_set_revealed(_save_point, true, true)
	if tutorial_floor_opens_after_save_point:
		_open_tutorial_floor()
	_unlock_completion_targets()
	_step = TutorialStep.DONE
	tutorial_enabled = false

func _input(event: InputEvent) -> void:
	if not tutorial_enabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_click_advance_requested = true

	var input_family := InputGlyphFormatter.detect_input_family(event)
	if input_family == &"" or input_family == _current_input_family:
		return
	_current_input_family = input_family
	_refresh_current_prompt()

func _process(delta: float) -> void:
	if not tutorial_enabled or not _player or _step == TutorialStep.DONE:
		return

	_step_timer += delta
	_update_move_progress()
	_count_inputs()
	_update_world_pointer()

	match _step:
		TutorialStep.HUD_HP, TutorialStep.HUD_ACTION_POINTS, TutorialStep.HUD_MOMENTUM:
			if _hud_advance_pressed():
				_advance_step()
		TutorialStep.MOVE:
			if _step_timer >= move_intro_min_seconds and _move_distance_accumulated >= move_required_distance:
				_advance_step()
		TutorialStep.JUMP:
			if _jump_count >= required_jumps:
				_advance_step()
		TutorialStep.AIR_JUMP:
			if _air_jump_count >= required_air_jumps:
				_advance_step()
		TutorialStep.DASH:
			if _dash_count >= required_dashes:
				_advance_step()
		TutorialStep.GRAPPLE:
			if _grapple_count >= required_grapples:
				_advance_step()
		TutorialStep.ATTACK:
			if _attack_count >= required_attacks:
				_advance_step()
		TutorialStep.MENUS:
			if _step_timer >= menu_intro_seconds or _menu_input_pressed():
				_advance_step()
		TutorialStep.COMBAT:
			pass
		TutorialStep.THREAD_KNOTS:
			if _hud_advance_pressed():
				_advance_step()
		TutorialStep.SAVE_POINT:
			pass
		TutorialStep.COMPLETE:
			if _step_timer >= 3.0 or Input.is_action_just_pressed("interact"):
				_advance_step()
	_click_advance_requested = false

func _begin_tutorial() -> void:
	if hide_save_point_until_combat_complete:
		_set_revealed(_save_point, false, true)
	_set_tutorial_floor_open(false)
	for path in disable_until_complete_paths:
		_set_node_enabled(get_node_or_null(path), false)
	for path in reveal_on_complete_paths:
		_set_revealed(get_node_or_null(path), false, true)

	_set_step(TutorialStep.HUD_HP)

func _set_step(step: TutorialStep) -> void:
	_step = step
	_step_timer = 0.0
	_step_start_position = _player.global_position if _player else Vector2.ZERO
	_last_player_position = _step_start_position
	_move_distance_accumulated = 0.0
	_jump_count = 0
	_air_jump_count = 0
	_dash_count = 0
	_grapple_count = 0
	_attack_count = 0
	if step == TutorialStep.COMBAT:
		_combat_completion_handled = false
	_jump_count_ready_at = 0.0
	_jump_press_buffer_until = 0.0
	_air_jump_count_ready_at = 0.0
	_dash_count_ready_at = 0.0
	_grapple_count_ready_at = 0.0
	_attack_count_ready_at = 0.0

	if _prompt:
		_prompt.set_prompt_layout(_bottom_center_position(prompt_size), prompt_size)
		_prompt.set_spotlight(false)

	_jump_was_on_floor = _player.is_on_floor() if _player and _player.has_method("is_on_floor") else false

	match _step:
		TutorialStep.HUD_HP:
			_show_hud_prompt(hp_text, hp_spotlight_rect, hp_pointer_start, hp_pointer_end)
		TutorialStep.HUD_ACTION_POINTS:
			_show_hud_prompt(action_points_text, action_points_spotlight_rect, action_points_pointer_start, action_points_pointer_end)
		TutorialStep.HUD_MOMENTUM:
			_show_hud_prompt(momentum_text, momentum_spotlight_rect, momentum_pointer_start, momentum_pointer_end)
		TutorialStep.MOVE:
			_show_prompt(move_text)
		TutorialStep.JUMP:
			_show_prompt(jump_text)
		TutorialStep.AIR_JUMP:
			_air_jump_was_available = _is_air_jump_available()
			_show_prompt(air_jump_text)
		TutorialStep.DASH:
			_show_prompt(dash_text)
		TutorialStep.GRAPPLE:
			_show_prompt(grapple_text)
		TutorialStep.ATTACK:
			_show_prompt(attack_text)
		TutorialStep.MENUS:
			_show_prompt(menu_text)
		TutorialStep.COMBAT:
			_show_prompt(combat_text)
			_spawn_tutorial_enemy()
		TutorialStep.THREAD_KNOTS:
			_thread_knot_prompt_seen = true
			_show_hud_prompt(thread_knot_text, thread_knot_spotlight_rect, thread_knot_pointer_start, thread_knot_pointer_end)
		TutorialStep.SAVE_POINT:
			_reveal_save_point()
			_show_save_point_prompt()
		TutorialStep.COMPLETE:
			_show_prompt(complete_text)
			_unlock_completion_targets()
		TutorialStep.DONE:
			if _prompt:
				_prompt.hide_prompt()
			tutorial_completed.emit()

func _advance_step() -> void:
	_set_step(_step + 1)

func debug_complete_tutorial() -> void:
	if _step == TutorialStep.DONE:
		return

	_combat_completion_handled = true
	_thread_knot_prompt_seen = true
	_tutorial_weave_spent = true
	_tutorial_rest_completed = true

	if _tutorial_enemy and is_instance_valid(_tutorial_enemy):
		_tutorial_enemy.queue_free()
		_tutorial_enemy = null

	_set_revealed(_save_point, true, true)
	if tutorial_floor_opens_after_save_point:
		_open_tutorial_floor()
	_unlock_completion_targets()

	_current_world_pointer_target = null
	_current_prompt_text = ""
	_current_prompt_pointer = false
	if _prompt:
		_prompt.set_spotlight(false)
		_prompt.hide_prompt()

	_step = TutorialStep.DONE
	tutorial_enabled = false
	tutorial_completed.emit()

func _show_prompt(text: String, pointer := false, _position := prompt_position, size := prompt_size) -> void:
	if not _prompt:
		return

	_current_world_pointer_target = null
	var layout_position: Vector2 = _position if _position != prompt_position else _bottom_center_position(size)
	_prompt.set_spotlight(false)
	_current_prompt_text = text
	_current_prompt_pointer = pointer
	_current_prompt_position = layout_position
	_current_prompt_size = size
	_prompt.set_prompt_layout(layout_position, size)
	_prompt.show_prompt(_format_prompt_text(text), pointer)

func _show_hud_prompt(text: String, focus_rect: Rect2, _pointer_start: Vector2, pointer_end: Vector2) -> void:
	if not _prompt:
		return

	_current_world_pointer_target = null
	var layout_position: Vector2 = _bottom_center_position(hud_prompt_size)
	var layout_pointer_start: Vector2 = layout_position + Vector2(hud_prompt_size.x * 0.5, 0.0)
	_current_prompt_text = text
	_current_prompt_pointer = true
	_current_prompt_position = layout_position
	_current_prompt_size = hud_prompt_size
	_prompt.set_prompt_layout(layout_position, hud_prompt_size)
	_prompt.set_pointer(layout_pointer_start, pointer_end)
	_prompt.set_spotlight(true, focus_rect)
	_prompt.show_prompt(_format_prompt_text(text), true)

func _show_save_point_prompt() -> void:
	_show_prompt(save_point_text, true)
	_current_world_pointer_target = _save_point as Node2D
	_update_world_pointer()

func _update_world_pointer() -> void:
	if not _prompt or not _current_world_pointer_target:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * _current_world_pointer_target.global_position
	screen_position.x = clampf(screen_position.x, 36.0, viewport_size.x - 36.0)
	screen_position.y = clampf(screen_position.y, 36.0, viewport_size.y - 36.0)
	var pointer_start_position := _current_prompt_position + Vector2(_current_prompt_size.x * 0.5, 0.0)
	_prompt.set_pointer(pointer_start_position, screen_position)

func _bottom_center_position(size: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(
		maxf(0.0, (viewport_size.x - size.x) * 0.5),
		maxf(0.0, viewport_size.y - size.y - bottom_prompt_margin)
	)

func _connect_input_binding_updates() -> void:
	var input_manager: Node = get_node_or_null("/root/InputBindingManager")
	if not input_manager:
		return
	var callback := Callable(self, "_on_input_bindings_changed")
	if not input_manager.is_connected("bindings_changed", callback):
		input_manager.connect("bindings_changed", callback)

func _on_input_bindings_changed() -> void:
	_refresh_current_prompt()

func _refresh_current_prompt() -> void:
	if not _prompt or _current_prompt_text.is_empty():
		return
	_prompt.set_prompt_layout(_current_prompt_position, _current_prompt_size)
	_prompt.show_prompt(_format_prompt_text(_current_prompt_text), _current_prompt_pointer, true)

func _format_prompt_text(text: String) -> String:
	var formatted := text
	for placeholder in INPUT_PLACEHOLDER_ACTIONS:
		var action := StringName(INPUT_PLACEHOLDER_ACTIONS[placeholder])
		var fallback := str(INPUT_PLACEHOLDER_FALLBACKS.get(placeholder, action))
		var input_label: String = InputGlyphFormatter.get_action_display_bbcode(action, fallback, _current_input_family)
		formatted = formatted.replace(placeholder, input_label)
	formatted = _replace_requirement_placeholders(formatted)
	return formatted

func _replace_requirement_placeholders(text: String) -> String:
	var formatted := text
	formatted = formatted.replace("{move_distance}", str(roundi(move_required_distance)))
	formatted = formatted.replace("{jump_goal}", str(required_jumps))
	formatted = formatted.replace("{jump_progress}", str(mini(_jump_count, required_jumps)))
	formatted = formatted.replace("{air_jump_goal}", str(required_air_jumps))
	formatted = formatted.replace("{air_jump_progress}", str(mini(_air_jump_count, required_air_jumps)))
	formatted = formatted.replace("{dash_goal}", str(required_dashes))
	formatted = formatted.replace("{dash_progress}", str(mini(_dash_count, required_dashes)))
	formatted = formatted.replace("{grapple_goal}", str(required_grapples))
	formatted = formatted.replace("{grapple_progress}", str(mini(_grapple_count, required_grapples)))
	formatted = formatted.replace("{attack_goal}", str(required_attacks))
	formatted = formatted.replace("{attack_progress}", str(mini(_attack_count, required_attacks)))
	return formatted

func _count_inputs() -> void:
	match _step:
		TutorialStep.JUMP:
			_count_jump_attempt()
		TutorialStep.AIR_JUMP:
			_count_air_jump_attempt()
		TutorialStep.DASH:
			_count_dash_attempt()
		TutorialStep.GRAPPLE:
			_count_grapple_throw()
		TutorialStep.ATTACK:
			_count_attack_attempt()

func _update_move_progress() -> void:
	if not _player:
		return

	if _step == TutorialStep.MOVE:
		_move_distance_accumulated += absf(_player.global_position.x - _last_player_position.x)
	_last_player_position = _player.global_position

func _count_jump_attempt() -> void:
	if not _player:
		return

	var on_floor: bool = _player.is_on_floor() if _player.has_method("is_on_floor") else false
	if Input.is_action_just_pressed("Jump") and _step_timer >= _jump_count_ready_at:
		_jump_press_buffer_until = _step_timer + jump_leave_floor_buffer
	if (
		_jump_was_on_floor
		and not on_floor
		and _step_timer <= _jump_press_buffer_until
		and _step_timer >= _jump_count_ready_at
	):
		_jump_count += 1
		_jump_count_ready_at = _step_timer + jump_count_cooldown
		_jump_press_buffer_until = 0.0
		_refresh_current_prompt()
	_jump_was_on_floor = on_floor

func _count_air_jump_attempt() -> void:
	if not _player:
		return

	var air_jump_available := _is_air_jump_available()
	var on_floor: bool = _player.is_on_floor() if _player.has_method("is_on_floor") else false
	if (
		not on_floor
		and _air_jump_was_available
		and not air_jump_available
		and _step_timer >= _air_jump_count_ready_at
	):
		_air_jump_count += 1
		_air_jump_count_ready_at = _step_timer + jump_count_cooldown
		_refresh_current_prompt()
	_air_jump_was_available = air_jump_available

func _is_air_jump_available() -> bool:
	if not _player or not ("air_jump_available" in _player):
		return false
	return bool(_player.air_jump_available)

func _count_dash_attempt() -> void:
	if _step_timer >= _dash_count_ready_at and Input.is_action_just_pressed("Dash"):
		_dash_count += 1
		_dash_count_ready_at = _step_timer + dash_count_cooldown
		_refresh_current_prompt()

func _count_grapple_throw() -> void:
	if _step_timer >= _grapple_count_ready_at and Input.is_action_just_pressed("Grapple"):
		_grapple_count += 1
		_grapple_count_ready_at = _step_timer + grapple_count_cooldown
		_refresh_current_prompt()

func _count_attack_attempt() -> void:
	if _step_timer >= _attack_count_ready_at and Input.is_action_just_pressed("Attack"):
		_attack_count += 1
		_attack_count_ready_at = _step_timer + attack_count_cooldown
		_refresh_current_prompt()

func _menu_input_pressed() -> bool:
	return (
		Input.is_action_just_pressed("open_inventory")
		or Input.is_action_just_pressed("open_map")
		or Input.is_action_just_pressed("open_controls")
		or Input.is_action_just_pressed("ui_cancel")
	)

func _hud_advance_pressed() -> bool:
	return (
		_click_advance_requested
		or Input.is_action_just_pressed("interact")
		or Input.is_action_just_pressed("Attack")
	)

func _spawn_tutorial_enemy() -> void:
	if _tutorial_enemy and is_instance_valid(_tutorial_enemy):
		return
	if not tutorial_enemy_scene:
		push_warning("TutorialController: tutorial_enemy_scene is not assigned.")
		_advance_step()
		return

	var parent: Node = get_node_or_null(enemy_parent_path)
	if not parent:
		parent = get_tree().current_scene

	_tutorial_enemy = tutorial_enemy_scene.instantiate()
	parent.add_child(_tutorial_enemy)
	if _tutorial_enemy is Node2D:
		(_tutorial_enemy as Node2D).global_position = _get_tutorial_enemy_spawn_position()
		_tutorial_enemy.modulate.a = 0.0

	var health_component: Node = _tutorial_enemy.get_node_or_null("HealthComponent")
	if health_component and health_component.has_signal("died"):
		health_component.died.connect(_on_tutorial_enemy_died)
	if not _tutorial_enemy.tree_exited.is_connected(_on_tutorial_enemy_tree_exited):
		_tutorial_enemy.tree_exited.connect(_on_tutorial_enemy_tree_exited)

	_fade_node(_tutorial_enemy, true, 0.45)

func _get_tutorial_enemy_spawn_position() -> Vector2:
	var spawn_marker: Node2D = get_node_or_null(tutorial_enemy_spawn_marker_path) as Node2D
	if spawn_marker:
		return spawn_marker.global_position
	return tutorial_enemy_spawn_position

func _on_tutorial_enemy_died(_damage: DamageData) -> void:
	_complete_tutorial_combat()

func _on_tutorial_enemy_tree_exited() -> void:
	_complete_tutorial_combat()

func _complete_tutorial_combat() -> void:
	if _combat_completion_handled or _step != TutorialStep.COMBAT:
		return
	_combat_completion_handled = true
	if _thread_knot_prompt_seen:
		_set_step(TutorialStep.SAVE_POINT)
	else:
		_set_step(TutorialStep.THREAD_KNOTS)

func handle_first_thread_knot_tutorial() -> bool:
	if not tutorial_enabled:
		return false
	if _thread_knot_prompt_seen:
		return _step >= TutorialStep.THREAD_KNOTS and _step <= TutorialStep.SAVE_POINT
	if _step < TutorialStep.COMBAT or _step > TutorialStep.SAVE_POINT:
		return false

	_thread_knot_prompt_seen = true
	call_deferred("_set_step", TutorialStep.THREAD_KNOTS)
	return true

func _reveal_save_point() -> void:
	if _save_point_revealed:
		return
	_save_point_revealed = true
	if move_save_point_to_marker_on_reveal:
		_move_save_point_to_tutorial_marker()
	if _save_point and _save_point.has_method("prepare_for_tutorial_reveal"):
		_save_point.call("prepare_for_tutorial_reveal")
	_set_revealed(_save_point, true)
	_refresh_save_point_overlap_for_tutorial()
	if _save_point and _save_point.has_signal("activated"):
		_save_point.activated.connect(_on_save_point_activated)
	if _save_point and _save_point.has_signal("menu_opened"):
		_save_point.menu_opened.connect(_on_tutorial_save_point_menu_opened)
	if _save_point and _save_point.has_signal("rested"):
		_save_point.rested.connect(_on_tutorial_save_point_rested)
	if _player and _player.has_signal("save_point_seated"):
		var seated_callback := Callable(self, "_on_tutorial_player_seated")
		if not _player.is_connected("save_point_seated", seated_callback):
			_player.connect("save_point_seated", seated_callback)

func _refresh_save_point_overlap_for_tutorial() -> void:
	if not _save_point:
		return
	if _save_point.has_method("refresh_current_player_overlap"):
		_save_point.call_deferred("refresh_current_player_overlap", _player)
		await get_tree().physics_frame
		_save_point.call_deferred("refresh_current_player_overlap", _player)
		await get_tree().create_timer(0.15).timeout
		_save_point.call_deferred("refresh_current_player_overlap", _player)

func _move_save_point_to_tutorial_marker() -> void:
	if not _save_point or not (_save_point is Node2D):
		return
	var marker: Node2D = get_node_or_null(tutorial_save_point_marker_path) as Node2D
	if not marker:
		return
	(_save_point as Node2D).global_position = marker.global_position

func handle_player_tutorial_death(player: Node) -> bool:
	if not tutorial_enabled or _step >= TutorialStep.SAVE_POINT:
		return false
	call_deferred("_reset_player_after_tutorial_death", player)
	return true

func _reset_player_after_tutorial_death(player: Node) -> void:
	if not player or not is_instance_valid(player):
		return

	var respawn_marker: Node2D = get_node_or_null(tutorial_player_respawn_marker_path) as Node2D
	var respawn_position: Vector2 = respawn_marker.global_position if respawn_marker else _step_start_position
	if player.has_method("revive_for_tutorial"):
		player.call("revive_for_tutorial", respawn_position)
	elif player is Node2D:
		(player as Node2D).global_position = respawn_position

	if _step == TutorialStep.COMBAT:
		_spawn_tutorial_enemy()

func _on_save_point_activated(_save_point_node: Area2D, _player_node: Node) -> void:
	pass

func _on_tutorial_player_seated(_player_node: CharacterBody2D) -> void:
	if _step == TutorialStep.SAVE_POINT:
		_show_prompt(save_point_weave_text, false, save_menu_prompt_position, save_menu_prompt_size)

func _on_tutorial_save_point_menu_opened(menu: Node) -> void:
	if _step != TutorialStep.SAVE_POINT:
		return
	if menu.has_signal("option_selected"):
		menu.option_selected.connect(_on_tutorial_save_point_option_selected)
	_show_prompt(save_point_weave_text, false, save_menu_prompt_position, save_menu_prompt_size)

func _on_tutorial_save_point_option_selected(option_name: StringName) -> void:
	if _step != TutorialStep.SAVE_POINT:
		return
	if option_name == &"Weave" and not _tutorial_weave_spent:
		_show_prompt("Spend one Thread Knot on any stat, then return to the Blossom menu.", false, save_menu_prompt_position, save_menu_prompt_size)

func _on_player_stat_upgraded(_stat_id: StringName) -> void:
	if _step != TutorialStep.SAVE_POINT:
		return
	_tutorial_weave_spent = true
	_show_prompt(save_point_reflect_text, false, save_menu_prompt_position, save_menu_prompt_size)

func _on_tutorial_save_point_rested(_save_point_node: Area2D, _player_node: Node) -> void:
	if _step != TutorialStep.SAVE_POINT or _tutorial_rest_completed:
		return
	if not _tutorial_weave_spent:
		_show_prompt(save_point_weave_text, false, save_menu_prompt_position, save_menu_prompt_size)
		return
	_tutorial_rest_completed = true
	_complete_save_point_tutorial()

func _complete_save_point_tutorial() -> void:
	DemoProgress.mark_tutorial_completed()
	if tutorial_floor_opens_after_save_point:
		_open_tutorial_floor()
	_advance_step()

func _open_tutorial_floor() -> void:
	if _tutorial_floor_opened:
		return
	_tutorial_floor_opened = true
	_set_tutorial_floor_open(true)

func _set_tutorial_floor_open(is_open: bool) -> void:
	for path in tutorial_pre_floor_paths:
		_set_revealed(get_node_or_null(path), not is_open, true)

func _unlock_completion_targets() -> void:
	for path in disable_until_complete_paths:
		_set_node_enabled(get_node_or_null(path), true)
	for path in reveal_on_complete_paths:
		_set_revealed(get_node_or_null(path), true)

func _set_revealed(node: Node, reveal: bool, instant := false) -> void:
	if not node:
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = reveal
		if reveal:
			(node as CanvasItem).modulate.a = 1.0
	_set_node_enabled(node, reveal)
	if node is CanvasItem:
		if instant:
			(node as CanvasItem).modulate.a = 1.0 if reveal else 0.0
			return
		_fade_node(node, reveal, 0.45)

func _fade_node(node: Node, reveal: bool, duration: float) -> void:
	if not node or not (node is CanvasItem):
		return
	var item := node as CanvasItem
	item.visible = true
	var tween := create_tween()
	tween.tween_property(item, "modulate:a", 1.0 if reveal else 0.0, duration)
	if not reveal:
		tween.tween_callback(func() -> void:
			if item:
				item.visible = false
		)

func _set_node_enabled(node: Node, enabled: bool) -> void:
	if not node:
		return
	if node is Area2D:
		var area := node as Area2D
		area.monitoring = enabled
		area.monitorable = enabled
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = not enabled
	if node is CollisionPolygon2D:
		(node as CollisionPolygon2D).disabled = not enabled
	if node is TileMapLayer:
		(node as TileMapLayer).enabled = enabled
	for child in node.get_children():
		_set_node_enabled(child, enabled)
