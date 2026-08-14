extends Control

signal back_requested
signal stat_upgrade_requested(stat_id: StringName)

const STAT_DATA := [
	{
		"id": &"health",
		"title": "HEALTH",
		"short": "HP",
		"color": Color(0.439, 0.682, 1.0, 1.0),
		"description": "Increases the Threadborne vitality.",
		"quote": "A stronger weave endures longer.",
		"node": "Health",
		"line": "HealthLine",
		"angle": -90.0,
	},
	{
		"id": &"attack",
		"title": "ATTACK",
		"short": "ATK",
		"color": Color(0.922, 0.227, 0.188, 1.0),
		"description": "Increases basic weapon damage.",
		"quote": "Power follows the hand that commits.",
		"node": "Attack",
		"line": "AttackLine",
		"angle": -150.0,
	},
	{
		"id": &"skill_damage",
		"title": "SKILL DAMAGE",
		"short": "SKL",
		"color": Color(0.922, 0.227, 0.188, 1.0),
		"description": "Increases future skill damage.",
		"quote": "A sharper thread cuts deeper.",
		"node": "SkillDamage",
		"line": "SkillLine",
		"angle": -210.0,
	},
	{
		"id": &"momentum_generation",
		"title": "MOMENTUM GAIN",
		"short": "MOM",
		"color": Color(0.933, 0.729, 0.243, 1.0),
		"description": "Builds momentum more quickly.",
		"quote": "Motion remembers devotion.",
		"node": "Momentum",
		"line": "MomentumLine",
		"angle": 90.0,
	},
	{
		"id": &"ap_recharge",
		"title": "AP RECHARGE",
		"short": "AP",
		"color": Color(0.933, 0.729, 0.243, 1.0),
		"description": "Restores action points faster.",
		"quote": "Stillness teaches the hand to return.",
		"node": "APRecharge",
		"line": "APLine",
		"angle": 30.0,
	},
	{
		"id": &"resistance",
		"title": "RESISTANCE",
		"short": "RES",
		"color": Color(0.439, 0.682, 1.0, 1.0),
		"description": "Reduces incoming damage.",
		"quote": "The weave bends before it breaks.",
		"node": "Resistance",
		"line": "ResistanceLine",
		"angle": -30.0,
	},
]

@export_range(0, 9999, 1) var weave_upgrade_cost := 1
@export var selected_scale := Vector2(1.16, 1.16)
@export var normal_scale := Vector2.ONE
@export var radial_center := Vector2(554.0, 320.0)
@export_range(180.0, 520.0, 1.0) var radial_radius := 250.0
@export_range(120.0, 360.0, 1.0) var center_emblem_size := 205.0
@export var stat_ring_blue: Texture2D
@export var stat_ring_red: Texture2D
@export var stat_ring_gold: Texture2D

@onready var knot_count_label: Label = $KnotPanel/KnotCountLabel as Label
@onready var prompt_title_label: Label = $PromptPanel/PromptTitleLabel as Label
@onready var prompt_description_label: Label = $PromptPanel/PromptDescriptionLabel as Label
@onready var prompt_quote_label: Label = $PromptPanel/PromptQuoteLabel as Label
@onready var prompt_cost_label: Label = $PromptPanel/PromptCostLabel as Label
@onready var prompt_input_label: Label = $PromptPanel/PromptInputLabel as Label
@onready var prompt_input_action_label: Label = $PromptPanel/PromptInputActionLabel as Label
@onready var prompt_stat_icon: TextureRect = $PromptPanel/PromptStatIcon as TextureRect
@onready var back_input_label: Label = $BackHint/BackInputLabel as Label
@onready var stat_nodes_root: Control = $GraphRoot/Stats as Control
@onready var graph_root: Control = $GraphRoot as Control
@onready var connectors: Node2D = $GraphRoot/Connectors as Node2D
@onready var center_emblem: TextureRect = $GraphRoot/CenterEmblem as TextureRect
@onready var center_ornament: TextureRect = $GraphRoot/CenterOrnament as TextureRect
@onready var knot_panel: TextureRect = $KnotPanel as TextureRect

var _player: Node
var _selected_index := 0
var _stat_nodes: Array[Control] = []
var _selected_pulse_tween: Tween
var _center_idle_tween: Tween
var _displayed_knot_count := -1
var _stick_navigation_armed := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interaction_prompt_owners")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cache_stat_nodes()
	_layout_radial_graph()
	_refresh_input_labels()
	_refresh()
	_select_index(0, true)
	_play_intro_animation()
	_start_center_idle()

func set_player(player: Node) -> void:
	_player = player
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var stick_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if stick_direction.length() <= 0.35:
			_stick_navigation_armed = true
		elif _stick_navigation_armed and stick_direction.length() >= 0.65:
			_stick_navigation_armed = false
			_select_in_direction(stick_direction.normalized())
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.is_action_pressed("move_up")):
		_select_in_direction(Vector2.UP)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.is_action_pressed("move_down")):
		_select_in_direction(Vector2.DOWN)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.is_action_pressed("move_left")):
		_select_in_direction(Vector2.LEFT)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.is_action_pressed("move_right")):
		_select_in_direction(Vector2.RIGHT)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_activate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _select_in_direction(direction: Vector2) -> void:
	if _stat_nodes.is_empty() or direction.length_squared() <= 0.0:
		return
	var current_center := _stat_nodes[_selected_index].position + _stat_nodes[_selected_index].size * 0.5
	var best_index := -1
	var best_score := -INF
	for i in _stat_nodes.size():
		if i == _selected_index:
			continue
		var candidate_center := _stat_nodes[i].position + _stat_nodes[i].size * 0.5
		var offset := candidate_center - current_center
		if offset.length_squared() <= 0.0:
			continue
		var alignment := offset.normalized().dot(direction.normalized())
		if alignment <= 0.2:
			continue
		var score := alignment * 1000.0 - offset.length()
		if score > best_score:
			best_score = score
			best_index = i
	if best_index >= 0:
		_select_index(best_index)

func _cache_stat_nodes() -> void:
	_stat_nodes.clear()
	for i in STAT_DATA.size():
		var data: Dictionary = STAT_DATA[i]
		var node := stat_nodes_root.get_node_or_null(String(data["node"])) as Control
		if not node:
			continue
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		node.pivot_offset = node.size * 0.5
		node.mouse_entered.connect(_select_index.bind(i))
		node.gui_input.connect(_on_stat_gui_input.bind(i))
		_stat_nodes.append(node)

func _layout_radial_graph() -> void:
	_layout_center_piece()
	for i in _stat_nodes.size():
		var data: Dictionary = STAT_DATA[i]
		var node := _stat_nodes[i]
		var angle := deg_to_rad(float(data["angle"]))
		var direction := Vector2(cos(angle), sin(angle))
		node.position = radial_center + direction * radial_radius - node.size * 0.5
		node.pivot_offset = node.size * 0.5
		_layout_connector(String(data["line"]), direction)

func _layout_center_piece() -> void:
	var center_rect := Rect2(radial_center - Vector2.ONE * center_emblem_size * 0.5, Vector2.ONE * center_emblem_size)
	center_emblem.position = center_rect.position
	center_emblem.size = center_rect.size
	center_emblem.pivot_offset = center_emblem.size * 0.5

	var ornament_size := center_emblem_size + 92.0
	center_ornament.position = radial_center - Vector2.ONE * ornament_size * 0.5
	center_ornament.size = Vector2.ONE * ornament_size
	center_ornament.pivot_offset = center_ornament.size * 0.5

func _layout_connector(line_name: String, direction: Vector2) -> void:
	var line := connectors.get_node_or_null(line_name) as Line2D
	if not line:
		return

	var start := radial_center + direction * (center_emblem_size * 0.46)
	var bend := radial_center + direction * (radial_radius * 0.58)
	var end := radial_center + direction * (radial_radius - 94.0)
	line.points = PackedVector2Array([start, bend, end])

func _on_stat_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)
		_activate_selected()

func _select_index(index: int, instant := false) -> void:
	if _stat_nodes.is_empty():
		return

	if not instant:
		AudioManager.play_ui(&"ui_click")

	_selected_index = wrapi(index, 0, _stat_nodes.size())
	for i in _stat_nodes.size():
		var node := _stat_nodes[i]
		var selected: bool = i == _selected_index
		node.scale = selected_scale if selected else normal_scale
		node.modulate = Color.WHITE if selected else Color(0.62, 0.58, 0.5, 0.78)
		_set_node_selected_visuals(node, selected)

	_update_prompt()
	_start_selected_pulse(_stat_nodes[_selected_index])

func _activate_selected() -> void:
	if _stat_nodes.is_empty():
		return

	AudioManager.play_ui(&"menu_select")
	var data: Dictionary = STAT_DATA[_selected_index]
	stat_upgrade_requested.emit(StringName(data["id"]))

func _refresh() -> void:
	_refresh_knot_count()
	_refresh_stat_nodes()
	_update_prompt()

func refresh_after_upgrade() -> void:
	_refresh()
	if not _stat_nodes.is_empty():
		var node := _stat_nodes[_selected_index]
		var tween := create_tween()
		tween.tween_property(node, "scale", selected_scale * 1.08, 0.08)
		tween.tween_property(node, "scale", selected_scale, 0.12)

func _refresh_knot_count() -> void:
	var knots := 0
	if _player:
		var knot_value = _player.get("thread_knot_count")
		if knot_value != null:
			knots = int(knot_value)
	if _displayed_knot_count < 0:
		_displayed_knot_count = knots
		knot_count_label.text = str(knots)
		return
	if _displayed_knot_count == knots:
		knot_count_label.text = str(knots)
		return

	var start_count := _displayed_knot_count
	_displayed_knot_count = knots
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_knot_count_display, start_count, knots, 0.24)
	tween.tween_property(knot_panel, "scale", Vector2(1.035, 1.035), 0.1)
	tween.tween_property(knot_panel, "scale", Vector2.ONE, 0.14).set_delay(0.1)

func _refresh_stat_nodes() -> void:
	for i in _stat_nodes.size():
		var data: Dictionary = STAT_DATA[i]
		var node := _stat_nodes[i]
		var accent := data["color"] as Color
		var ring := node.get_node_or_null("Ring") as TextureRect
		var title := node.get_node_or_null("Title") as Label
		var icon := node.get_node_or_null("Icon") as TextureRect
		var values := node.get_node_or_null("Values") as Label
		var cost := node.get_node_or_null("Cost") as Label
		if ring:
			ring.texture = _get_ring_texture(accent)
			ring.modulate = Color.WHITE
		if title:
			title.text = String(data["title"])
			title.modulate = accent
		if icon:
			icon.modulate = accent
		if values:
			var current_value := _get_player_stat_display(StringName(data["id"]))
			var next_value := _get_player_stat_preview(StringName(data["id"]))
			values.text = "%s  >  %s" % [current_value, next_value]
		if cost:
			cost.text = str(weave_upgrade_cost)

func _update_prompt() -> void:
	if _stat_nodes.is_empty():
		return

	var data: Dictionary = STAT_DATA[_selected_index]
	var selected_node := _stat_nodes[_selected_index]
	var icon := selected_node.get_node_or_null("Icon") as TextureRect
	prompt_title_label.text = String(data["title"])
	prompt_title_label.modulate = data["color"] as Color
	if icon and prompt_stat_icon:
		prompt_stat_icon.texture = icon.texture
		prompt_stat_icon.modulate = data["color"] as Color
	prompt_description_label.text = String(data["description"])
	prompt_quote_label.text = String(data["quote"])
	prompt_cost_label.text = str(weave_upgrade_cost)
	InteractionPromptFormatter.apply_action_glyph(prompt_input_label, &"ui_accept", "ENTER", 42)
	if prompt_input_action_label:
		prompt_input_action_label.text = "WEAVE THREAD"

func _set_node_selected_visuals(node: Control, selected: bool) -> void:
	var ring := node.get_node_or_null("Ring") as CanvasItem
	var title := node.get_node_or_null("Title") as Label
	var icon := node.get_node_or_null("Icon") as CanvasItem
	var values := node.get_node_or_null("Values") as Label
	var cost := node.get_node_or_null("Cost") as Label
	var cost_icon := node.get_node_or_null("CostIcon") as CanvasItem
	var bright := Color.WHITE
	var muted := Color(0.8, 0.74, 0.62, 0.72)

	if ring:
		ring.modulate = bright if selected else muted
	if title:
		title.modulate.a = 1.0 if selected else 0.72
	if icon:
		icon.modulate = bright if selected else muted
	if values:
		values.modulate = Color(0.98, 0.92, 0.76, 1.0) if selected else Color(0.76, 0.68, 0.52, 0.78)
	if cost:
		cost.modulate = Color(0.98, 0.88, 0.46, 1.0) if selected else Color(0.76, 0.68, 0.52, 0.78)
	if cost_icon:
		cost_icon.modulate = Color.WHITE if selected else Color(0.72, 0.66, 0.52, 0.72)

func _start_selected_pulse(node: Control) -> void:
	if _selected_pulse_tween:
		_selected_pulse_tween.kill()
	var ring := node.get_node_or_null("Ring") as CanvasItem
	if not ring:
		return

	_selected_pulse_tween = create_tween()
	_selected_pulse_tween.set_loops()
	_selected_pulse_tween.tween_property(ring, "modulate", Color(1.0, 0.94, 0.68, 1.0), 0.72).set_trans(Tween.TRANS_SINE)
	_selected_pulse_tween.tween_property(ring, "modulate", Color.WHITE, 0.72).set_trans(Tween.TRANS_SINE)

func _play_intro_animation() -> void:
	modulate.a = 0.0
	graph_root.scale = Vector2(0.94, 0.94)
	graph_root.pivot_offset = graph_root.size * 0.5
	for node in _stat_nodes:
		node.modulate.a = 0.0
		node.scale = Vector2(0.78, 0.78)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(graph_root, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in _stat_nodes.size():
		var node := _stat_nodes[i]
		tween.tween_property(node, "modulate:a", 1.0, 0.24).set_delay(0.05 + float(i) * 0.035)
		tween.tween_property(node, "scale", selected_scale if i == _selected_index else normal_scale, 0.28).set_delay(0.05 + float(i) * 0.035).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_center_idle() -> void:
	if _center_idle_tween:
		_center_idle_tween.kill()
	center_emblem.pivot_offset = center_emblem.size * 0.5
	center_ornament.pivot_offset = center_ornament.size * 0.5
	_center_idle_tween = create_tween()
	_center_idle_tween.set_loops()
	_center_idle_tween.set_parallel(true)
	_center_idle_tween.tween_property(center_emblem, "rotation_degrees", 2.0, 2.8).set_trans(Tween.TRANS_SINE)
	_center_idle_tween.tween_property(center_ornament, "rotation_degrees", -3.0, 4.2).set_trans(Tween.TRANS_SINE)
	_center_idle_tween.chain().tween_property(center_emblem, "rotation_degrees", -2.0, 2.8).set_trans(Tween.TRANS_SINE)
	_center_idle_tween.parallel().tween_property(center_ornament, "rotation_degrees", 3.0, 4.2).set_trans(Tween.TRANS_SINE)

func _set_knot_count_display(value: float) -> void:
	knot_count_label.text = str(roundi(value))

func _get_ring_texture(accent: Color) -> Texture2D:
	if accent.r > 0.8 and accent.g < 0.35:
		return stat_ring_red
	if accent.b > 0.8:
		return stat_ring_blue
	return stat_ring_gold

func _get_player_stat_display(stat_id: StringName) -> String:
	if _player and _player.has_method("get_weave_stat_display"):
		return _player.get_weave_stat_display(stat_id)
	return "--"

func _get_player_stat_preview(stat_id: StringName) -> String:
	if _player and _player.has_method("get_weave_stat_preview"):
		return _player.get_weave_stat_preview(stat_id)
	return "--"

func _refresh_input_labels() -> void:
	InteractionPromptFormatter.apply_action_glyphs(
		back_input_label,
		[&"pause_menu", &"ui_cancel"],
		"ESC",
		34
	)

func refresh_interaction_prompt() -> void:
	_refresh_input_labels()
	_update_prompt()

func _get_action_display(action: StringName, fallback: String) -> String:
	var manager := get_node_or_null("/root/InputBindingManager")
	if manager and manager.has_method("get_primary_keyboard_event"):
		var event = manager.get_primary_keyboard_event(action)
		var formatted := _format_input_event(event)
		if not formatted.is_empty():
			return formatted

	for event in InputMap.action_get_events(action):
		var formatted := _format_input_event(event)
		if not formatted.is_empty():
			return formatted
	return fallback

func _format_input_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_ESCAPE:
			return "ESC"
		if code == KEY_SPACE:
			return "SPACE"
		return OS.get_keycode_string(code).to_upper()
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
	return ""

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
