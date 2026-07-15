extends CanvasLayer

signal option_selected(option_name: StringName)
signal rise_requested

const WEAVE_LEVEL_MENU_SCENE := preload("res://Src/UI/SavePointMenu/weave_level_menu.tscn")

const MAIN_OPTIONS := [
	{"name": &"Reflect", "label": "REFLECT"},
	{"name": &"Weave", "label": "WEAVE"},
	{"name": &"Listen", "label": "LISTEN"},
	{"name": &"Rise", "label": "RISE"},
]
const MAIN_OPTION_DESCRIPTIONS := {
	&"Reflect": "Rest at the Blossom, restore your health, save your progress, and reset the world.",
	&"Weave": "Spend Thread Knots to strengthen your Threadborne.",
	&"Listen": "Hear the whispered memories of Eryndor.",
	&"Rise": "Leave the Blossom and continue your journey.",
}
const WEAVE_OPTIONS := [
	{"name": &"health", "label": "HEALTH"},
	{"name": &"attack", "label": "ATTACK"},
	{"name": &"skill_damage", "label": "SKILL DAMAGE"},
	{"name": &"ap_recharge", "label": "AP RECHARGE"},
	{"name": &"momentum_generation", "label": "MOMENTUM"},
	{"name": &"resistance", "label": "RESISTANCE"},
	{"name": &"back", "label": "BACK"},
]

@export var selector_offset := Vector2(18.0, -10.0)
@export var selected_scale := Vector2(1.04, 1.04)
@export var normal_scale := Vector2.ONE
@export var menu_left_position := Vector2(180.0, 318.0)
@export var menu_right_position := Vector2(1140.0, 318.0)
@export var fade_duration := 0.18
@export var focus_left_center := Vector2(0.25, 0.50)
@export var focus_right_center := Vector2(0.75, 0.50)
@export var focus_radius := Vector2(0.24, 0.34)
@export_range(0, 9999, 1) var weave_upgrade_cost := 1

@onready var blur_rect: ColorRect = $BlurRect as ColorRect
@onready var menu_root: Control = $MenuRoot as Control
@onready var prompt_label: Label = $MenuRoot/TextBox/Prompt as Label
@onready var description_label: Label = $MenuRoot/Description as Label
@onready var options_root: Control = $MenuRoot/Options as Control
@onready var selector: TextureRect = $MenuRoot/Selector as TextureRect
@onready var rows: Array[Control] = [
	$MenuRoot/Options/Reflect,
	$MenuRoot/Options/Weave,
	$MenuRoot/Options/Listen,
	$MenuRoot/Options/Rise,
]

var _selected_index := 0
var _row_tweens: Dictionary = {}
var _closing := false
var _started_pause_music := false
var _mode: StringName = &"main"
var _active_options: Array = []
var _player: Node
var _weave_panel: Control
var _pre_weave_blur_state: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	add_to_group("save_point_menu")
	_configure_initial_state()
	_ensure_row_count(WEAVE_OPTIONS.size())
	for i in rows.size():
		var row := rows[i]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.pivot_offset = row.size * 0.5
		row.mouse_entered.connect(_select_index.bind(i))
		row.gui_input.connect(_on_row_gui_input.bind(i))

	_show_main_options()
	_select_index(_selected_index, true)

func set_player(player: Node) -> void:
	_player = player
	_refresh_weave_labels()

func open(menu_side: int) -> void:
	AudioManager.play_pause_music()
	_started_pause_music = true
	menu_root.position = menu_right_position if menu_side >= 0 else menu_left_position
	_configure_focus(menu_side)
	_select_index(_selected_index, true)
	blur_rect.modulate.a = 0.0
	menu_root.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 1.0, fade_duration)
	tween.tween_property(menu_root, "modulate:a", 1.0, fade_duration)

func close() -> void:
	if _closing:
		return

	_closing = true
	_close_weave_panel(false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 0.0, fade_duration)
	tween.tween_property(menu_root, "modulate:a", 0.0, fade_duration)
	await tween.finished
	if _started_pause_music:
		AudioManager.stop_pause_music()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if _weave_panel and is_instance_valid(_weave_panel):
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_activate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if _mode == &"weave":
			_show_main_options()
		else:
			rise_requested.emit()
		get_viewport().set_input_as_handled()

func _configure_initial_state() -> void:
	blur_rect.material = blur_rect.material.duplicate()
	blur_rect.visible = true
	menu_root.modulate.a = 0.0
	blur_rect.modulate.a = 0.0

func _configure_focus(menu_side: int) -> void:
	var shader_material := blur_rect.material as ShaderMaterial
	if not shader_material:
		return

	var focus_center := focus_left_center if menu_side >= 0 else focus_right_center
	shader_material.set_shader_parameter("focus_center", focus_center)
	shader_material.set_shader_parameter("focus_radius", focus_radius)
	shader_material.set_shader_parameter("focus_softness", 0.28)
	shader_material.set_shader_parameter("blur_amount", 5.6)
	shader_material.set_shader_parameter("desaturation", 0.88)
	shader_material.set_shader_parameter("blue_tint_strength", 0.0)
	shader_material.set_shader_parameter("darken_strength", 0.58)
	shader_material.set_shader_parameter("vignette_strength", 0.94)
	shader_material.set_shader_parameter("vignette_radius", 0.26)
	shader_material.set_shader_parameter("vignette_softness", 0.48)
	shader_material.set_shader_parameter("focus_warmth", 0.28)
	shader_material.set_shader_parameter("focus_warm_color", Color(1.0, 0.62, 0.22, 1.0))
	shader_material.set_shader_parameter("focus_glow_strength", 0.06)
	shader_material.set_shader_parameter("focus_glow_radius", 0.62)
	shader_material.set_shader_parameter("focus_glow_softness", 0.58)

func _ensure_row_count(count: int) -> void:
	if rows.is_empty():
		return

	var template := rows[rows.size() - 1]
	while rows.size() < count:
		var row := template.duplicate()
		row.name = "GeneratedOption%d" % rows.size()
		row.position.y = float(rows.size()) * 96.0
		options_root.add_child(row)
		rows.append(row)

func _show_main_options() -> void:
	_mode = &"main"
	_active_options = MAIN_OPTIONS.duplicate(true)
	_selected_index = 0
	if prompt_label:
		prompt_label.text = "THE BLOSSOM AWAITS"
	if description_label:
		description_label.visible = true
	_apply_active_options()

func _show_weave_options() -> void:
	_mode = &"weave"
	_active_options = WEAVE_OPTIONS.duplicate(true)
	_selected_index = 0
	if description_label:
		description_label.visible = false
	_apply_active_options()
	_refresh_weave_labels()

func _apply_active_options() -> void:
	for i in rows.size():
		var row := rows[i]
		var should_show := i < _active_options.size()
		row.visible = should_show
		if not should_show:
			continue

		var option: Dictionary = _active_options[i]
		row.name = String(option["name"])
		var label := row.get_node("Label") as Label
		if label:
			label.text = String(option["label"])
	_select_index(clampi(_selected_index, 0, max(0, _active_options.size() - 1)), true)

func _on_row_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)
		_activate_selected()

func _select_index(index: int, instant := false) -> void:
	if _active_options.is_empty():
		return
	if not instant:
		AudioManager.play_ui(&"ui_click")

	_selected_index = wrapi(index, 0, _active_options.size())
	for i in rows.size():
		if rows[i].visible:
			_set_row_selected(i, i == _selected_index, instant)

	var row := rows[_selected_index]
	var plaque := row.get_node("Plaque") as TextureRect
	selector.visible = true
	selector.global_position = plaque.global_position + Vector2(plaque.size.x, 0.0) + selector_offset
	_refresh_description()

func _set_row_selected(index: int, is_selected: bool, instant: bool) -> void:
	var row := rows[index]
	var plaque := row.get_node("Plaque") as TextureRect
	var label := row.get_node("Label") as Label
	var target_scale := selected_scale if is_selected else normal_scale
	var label_color := Color(1.0, 0.88, 0.58, 1.0) if is_selected else Color(0.58, 0.5, 0.36, 0.76)
	var plaque_color := Color(1.0, 0.9, 0.62, 1.0) if is_selected else Color(0.48, 0.42, 0.32, 0.66)

	if instant:
		row.scale = target_scale
		label.modulate = label_color
		plaque.modulate = plaque_color
		return

	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.set_parallel(true)
	tween.tween_property(row, "scale", target_scale, 0.12)
	tween.tween_property(label, "modulate", label_color, 0.12)
	tween.tween_property(plaque, "modulate", plaque_color, 0.12)

func _refresh_description() -> void:
	if not description_label or _mode != &"main" or _active_options.is_empty():
		return

	var selected_name := StringName(_active_options[_selected_index]["name"])
	description_label.text = String(MAIN_OPTION_DESCRIPTIONS.get(selected_name, ""))

func _activate_selected() -> void:
	AudioManager.play_ui(&"menu_select")
	if _active_options.is_empty():
		return

	var selected_name := StringName(_active_options[_selected_index]["name"])
	if _mode == &"weave":
		_activate_weave_option(selected_name)
		return

	if selected_name == &"Rise":
		rise_requested.emit()
		return
	if selected_name == &"Weave":
		_open_weave_panel()
		return

	option_selected.emit(selected_name)
	_pulse(rows[_selected_index])

func _open_weave_panel() -> void:
	if _weave_panel and is_instance_valid(_weave_panel):
		return

	_mode = &"weave_panel"
	menu_root.visible = false
	selector.visible = false
	_weave_panel = WEAVE_LEVEL_MENU_SCENE.instantiate() as Control
	add_child(_weave_panel)
	_apply_weave_focus()
	_weave_panel.set("weave_upgrade_cost", weave_upgrade_cost)
	if _weave_panel.has_method("set_player"):
		_weave_panel.set_player(_player)
	if _weave_panel.has_signal("back_requested"):
		_weave_panel.back_requested.connect(_close_weave_panel.bind(true))
	if _weave_panel.has_signal("stat_upgrade_requested"):
		_weave_panel.stat_upgrade_requested.connect(_on_weave_panel_stat_upgrade)

func _close_weave_panel(return_to_main := true) -> void:
	if _weave_panel and is_instance_valid(_weave_panel):
		_weave_panel.queue_free()
	_weave_panel = null
	_restore_pre_weave_focus()
	if return_to_main:
		menu_root.visible = true
		_show_main_options()

func _on_weave_panel_stat_upgrade(stat_id: StringName) -> void:
	if not _player or not _player.has_method("weave_stat_upgrade"):
		return

	var success: bool = _player.weave_stat_upgrade(stat_id, weave_upgrade_cost)
	if success and _weave_panel and is_instance_valid(_weave_panel) and _weave_panel.has_method("refresh_after_upgrade"):
		_weave_panel.refresh_after_upgrade()

func _activate_weave_option(stat_id: StringName) -> void:
	if stat_id == &"back":
		_show_main_options()
		return
	if not _player or not _player.has_method("weave_stat_upgrade"):
		return

	var success: bool = _player.weave_stat_upgrade(stat_id, weave_upgrade_cost)
	if success:
		_pulse(rows[_selected_index])
	_refresh_weave_labels()

func _refresh_weave_labels() -> void:
	if _mode != &"weave":
		return

	if prompt_label:
		var knots := 0
		if _player:
			var knot_value = _player.get("thread_knot_count")
			if knot_value != null:
				knots = int(knot_value)
		prompt_label.text = "WEAVE THE THREADBORNE  KNOTS %d" % knots

	for i in _active_options.size():
		var option: Dictionary = _active_options[i]
		var stat_id := StringName(option["name"])
		var label := rows[i].get_node("Label") as Label
		if not label:
			continue
		if stat_id == &"back":
			label.text = "BACK"
			continue

		var value := ""
		var points := 0
		if _player:
			if _player.has_method("get_weave_stat_display"):
				value = _player.get_weave_stat_display(stat_id)
			if _player.has_method("get_weave_stat_points"):
				points = _player.get_weave_stat_points(stat_id)
		label.text = "%s %s  LV %d" % [String(option["label"]), value, points]

func _pulse(row: Control) -> void:
	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.tween_property(row, "modulate", Color(0.72, 0.66, 0.58, 1.0), 0.08)
	tween.tween_property(row, "modulate", Color.WHITE, 0.14)

func _apply_weave_focus() -> void:
	var shader_material := blur_rect.material as ShaderMaterial
	if not shader_material:
		return

	_pre_weave_blur_state = {
		"blur_amount": shader_material.get_shader_parameter("blur_amount"),
		"desaturation": shader_material.get_shader_parameter("desaturation"),
		"blue_tint_strength": shader_material.get_shader_parameter("blue_tint_strength"),
		"focus_radius": shader_material.get_shader_parameter("focus_radius"),
		"focus_softness": shader_material.get_shader_parameter("focus_softness"),
	}
	shader_material.set_shader_parameter("blur_amount", 3.2)
	shader_material.set_shader_parameter("desaturation", 0.78)
	shader_material.set_shader_parameter("blue_tint_strength", 0.0)
	shader_material.set_shader_parameter("focus_radius", focus_radius * 1.12)
	shader_material.set_shader_parameter("focus_softness", 0.28)

func _restore_pre_weave_focus() -> void:
	var shader_material := blur_rect.material as ShaderMaterial
	if not shader_material or _pre_weave_blur_state.is_empty():
		return

	for parameter in _pre_weave_blur_state:
		shader_material.set_shader_parameter(String(parameter), _pre_weave_blur_state[parameter])
	_pre_weave_blur_state.clear()

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("Attack") or event.is_action_pressed("Jump")
