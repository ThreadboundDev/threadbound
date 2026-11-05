extends Node

## Global debug UI singleton
## Provides a single debug label accessible from anywhere

const DEMO_ENDING_SCENE := preload("res://Src/UI/DemoEnding/demo_ending.tscn")
const FEEDBACK_CAPTURE := preload("res://Src/DebugFeedback/feedback_capture.gd")
const ZOOM_BASE_META := &"_art_test_original_zoom"

var debug_label: Label
var target_node: Node2D = null  # Usually the player
var canvas_layer: CanvasLayer = null

func _ready():
	if not OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	if not OS.get_cmdline_user_args().has("--no-debug-feedback"):
		var feedback := FEEDBACK_CAPTURE.new()
		feedback.name = "FeedbackCapture"
		add_child(feedback)

	# Create canvas layer for debug UI (always on top)
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DebugCanvas"
	add_child(canvas_layer)
	
	# Create debug label
	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 18)
	debug_label.text = "Debug: F3 Kill Proto-Weaver | F4 End Demo"
	debug_label.position = Vector2(10, 10)  # Top-left corner by default
	canvas_layer.add_child(debug_label)

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventMouseButton and event.pressed:
		# Close-up review also works in normal editor runs without art-test unlocks.
		if not get_tree().paused and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var step := 1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8
			var ticks: float = event.factor if event.factor > 0.0 else 1.0
			if _adjust_art_test_zoom(pow(step, ticks)):
				get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_BACKSLASH:
			if not get_tree().paused and _adjust_art_test_zoom(0.0):
				get_viewport().set_input_as_handled()
		KEY_F3:
			if _kill_proto_weaver():
				get_viewport().set_input_as_handled()
		KEY_F4:
			if get_tree().get_first_node_in_group("demo_ending_screen"):
				return
			get_viewport().set_input_as_handled()
			var ending := DEMO_ENDING_SCENE.instantiate()
			ending.set("record_completion", false)
			get_tree().root.add_child(ending)

func _adjust_art_test_zoom(step: float) -> bool:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return false
	var original: Vector2 = camera.get_meta(ZOOM_BASE_META, camera.zoom)
	if step == 0.0:
		camera.zoom = original
		camera.remove_meta(ZOOM_BASE_META)
	else:
		camera.set_meta(ZOOM_BASE_META, original)
		camera.zoom = original * clampf(camera.zoom.x / original.x * step, 1.0, 16.0)
	return true

func _kill_proto_weaver() -> bool:
	var boss := get_tree().get_first_node_in_group("proto_weaver") as Node2D
	if not boss:
		update_debug("F3: No Proto-Weaver found")
		return false
	var health_component := boss.get("health_component") as HealthComponent
	if not health_component or health_component.is_dead:
		update_debug("F3: Proto-Weaver is already defeated")
		return false

	var damage := DamageData.new()
	damage.amount = health_component.current_health
	damage.source = target_node
	damage.hit_position = boss.global_position
	health_component.apply_damage(damage)
	update_debug("F3: Proto-Weaver death triggered")
	return true

## Update debug text - call from anywhere
func update_debug(text: String):
	if not OS.is_debug_build():
		return
	if debug_label:
		debug_label.text = text

## Clear debug text
func clear_debug():
	if not OS.is_debug_build():
		return
	if debug_label:
		debug_label.text = ""

## Set target node for relative positioning (optional)
## When set, the debug label will follow the target node
func set_target_node(node: Node2D):
	if not OS.is_debug_build():
		return
	target_node = node
	if target_node and debug_label:
		# Position relative to target (above player)
		debug_label.position = Vector2(0, -120)
		# Move label to follow target
		if debug_label.get_parent() != target_node:
			debug_label.get_parent().remove_child(debug_label)
			target_node.add_child(debug_label)

## Reset to screen-relative positioning
func reset_position():
	if not OS.is_debug_build():
		return
	if debug_label and target_node:
		if debug_label.get_parent() == target_node:
			target_node.remove_child(debug_label)
		canvas_layer.add_child(debug_label)
		debug_label.position = Vector2(10, 10)
		target_node = null
