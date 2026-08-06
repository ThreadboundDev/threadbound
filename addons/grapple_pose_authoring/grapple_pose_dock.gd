@tool
extends Control

var editor_plugin: EditorPlugin
var updating_controls := false

@onready var variant_option: OptionButton = %VariantOption
@onready var animation_option: OptionButton = %AnimationOption
@onready var frame_spin: SpinBox = %FrameSpin
@onready var frame_info: Label = %FrameInfo
@onready var play_button: Button = %PlayButton
@onready var status_label: Label = %StatusLabel


func setup(plugin: EditorPlugin) -> void:
	editor_plugin = plugin


func _ready() -> void:
	variant_option.item_selected.connect(_on_variant_selected)
	animation_option.item_selected.connect(_on_animation_selected)
	frame_spin.value_changed.connect(_on_frame_changed)
	%ShortcutsToggle.toggled.connect(_on_shortcuts_toggled)
	%OnionSkinToggle.toggled.connect(_on_onion_skin_toggled)
	%OpenButton.pressed.connect(_on_open_pressed)
	%PreviousButton.pressed.connect(_on_previous_pressed)
	%NextButton.pressed.connect(_on_next_pressed)
	play_button.pressed.connect(_on_play_pressed)
	%SelectHandButton.pressed.connect(_on_select_hand_pressed)
	%SelectWristButton.pressed.connect(_on_select_wrist_pressed)
	%CaptureButton.pressed.connect(_on_capture_pressed)
	%CaptureNextButton.pressed.connect(_on_capture_next_pressed)
	%ResetInterpolateButton.pressed.connect(_on_reset_interpolate_pressed)
	%RevertButton.pressed.connect(_on_revert_pressed)


func set_animation_data(
	names: PackedStringArray,
	selected_name: StringName,
	frame_count: int
) -> void:
	updating_controls = true
	animation_option.clear()
	var selected_index := 0
	for index in names.size():
		animation_option.add_item(names[index])
		if names[index] == selected_name:
			selected_index = index
	animation_option.select(selected_index)
	frame_spin.max_value = maxi(0, frame_count - 1)
	updating_controls = false


func set_frame_display(frame: int, frame_count: int, fps: float) -> void:
	updating_controls = true
	frame_spin.max_value = maxi(0, frame_count - 1)
	frame_spin.value = frame
	updating_controls = false
	frame_info.text = "Frame %d / %d   Time %.3fs   %.2f FPS" % [
		frame,
		maxi(0, frame_count - 1),
		float(frame) / maxf(fps, 0.001),
		fps,
	]


func set_playing_display(playing: bool) -> void:
	play_button.text = "Pause" if playing else "Play"


func set_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.45, 0.4) if is_error else Color(0.72, 0.9, 0.78)


func _on_variant_selected(index: int) -> void:
	if not updating_controls and editor_plugin:
		editor_plugin.call("set_variant", index)


func _on_animation_selected(index: int) -> void:
	if updating_controls or not editor_plugin or index < 0:
		return
	editor_plugin.call("set_animation", StringName(animation_option.get_item_text(index)))


func _on_frame_changed(value: float) -> void:
	if not updating_controls and editor_plugin:
		editor_plugin.call("set_frame", roundi(value))


func _on_open_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("open_authoring_view")


func _on_shortcuts_toggled(enabled: bool) -> void:
	if editor_plugin:
		editor_plugin.call("set_shortcuts_enabled", enabled)


func _on_onion_skin_toggled(enabled: bool) -> void:
	if editor_plugin:
		editor_plugin.call("set_onion_skin_enabled", enabled)


func _on_previous_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("step_frame", -1)


func _on_next_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("step_frame", 1)


func _on_play_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("set_playing", play_button.text != "Pause")


func _on_select_hand_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("select_hand")


func _on_select_wrist_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("select_wrist")


func _on_capture_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("capture_pose")


func _on_capture_next_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("capture_pose_and_advance")


func _on_reset_interpolate_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("reset_frame_to_interpolate")


func _on_revert_pressed() -> void:
	if editor_plugin:
		editor_plugin.call("revert_frame")
