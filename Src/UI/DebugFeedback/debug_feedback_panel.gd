extends Window
## Exclusive window keeps text/navigation input out of gameplay and pause menus.

var capture: Node
var title_field: LineEdit
var type_field: OptionButton
var area_field: OptionButton
var impact_field: OptionButton
var frequency_field: OptionButton
var description: TextEdit
var expected: TextEdit
var reproduction: TextEdit
var preview: TextureRect
var context: Label
var status: Label
var save_button: Button
var copy_button: Button
var close_button: Button
var _draft_timer: Timer
var _saved := false
var _loading := false
var _directory := ""

func configure(owner_capture: Node) -> void:
	capture = owner_capture
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_requested.connect(_close)
	window_input.connect(_window_input)
	_build()

func _build() -> void:
	var background := PanelContainer.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	background.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var heading := Label.new()
	heading.text = "THREADBOUND · DEVELOPMENT FEEDBACK"
	heading.add_theme_font_size_override("font_size", 23)
	layout.add_child(heading)
	context = _label("Game paused. Capture and context are attached automatically.", layout)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 8)
	scroll.add_child(form)
	preview = TextureRect.new()
	preview.custom_minimum_size.y = 160
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	form.add_child(preview)
	_label("Short title (optional)", form)
	title_field = LineEdit.new()
	title_field.placeholder_text = "e.g. Sword arm disappears during the run"
	form.add_child(title_field)
	title_field.text_changed.connect(func(_text): _changed())
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	form.add_child(row)
	type_field = _option("Kind", ["Bug", "Suggestion", "Positive feedback", "Question", "Unsure"], row)
	area_field = _option("Area", ["Gameplay", "Art / animation", "Level / camera", "Controls", "UI", "Audio", "Performance", "Crash / error", "Other"], row)
	impact_field = _option("Impact", ["Unspecified", "Minor", "Disruptive", "Blocks progress", "Crash / lost progress"], row)
	description = _text("What happened, or what would you like changed?", "Your own words are enough. What felt wrong, good, or confusing?", 100, form)
	expected = _text("Expected / desired result (optional)", "What should happen instead?", 60, form)
	reproduction = _text("How to reproduce (optional)", "Anything you did just before it happened. Controls and state are already attached.", 60, form)
	frequency_field = _option("Frequency", ["Unknown / first time", "Every time", "Sometimes", "Only once", "Not applicable"], form)
	_label("Saved locally with media, level/player/gear/checkpoint state, recent inputs, performance and errors. Nothing is uploaded.", form)
	status = _label("Notes autosave as a draft. Save & copy makes this ready for review.", layout)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 8)
	layout.add_child(buttons)
	save_button = _button("Save & copy handoff", _save, buttons)
	copy_button = _button("Copy handoff", _copy, buttons)
	_button("Open report folder", func(): OS.shell_open(_directory), buttons)
	close_button = _button("Keep draft & close", _close, buttons)
	_draft_timer = Timer.new()
	_draft_timer.one_shot = true
	_draft_timer.wait_time = 0.5
	_draft_timer.timeout.connect(_autosave)
	add_child(_draft_timer)

func _label(text: String, parent: Node) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _option(label: String, values: Array, parent: Node) -> OptionButton:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size.x = 190
	parent.add_child(box)
	_label(label, box)
	var option := OptionButton.new()
	for item in values:
		option.add_item(item)
	option.item_selected.connect(func(_index): _changed())
	box.add_child(option)
	return option

func _text(label: String, placeholder: String, height: int, parent: Node) -> TextEdit:
	_label(label, parent)
	var edit := TextEdit.new()
	edit.placeholder_text = placeholder
	edit.custom_minimum_size.y = height
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.text_changed.connect(_changed)
	parent.add_child(edit)
	return edit

func _button(text: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_report(data: Dictionary, directory: String, image: Image) -> void:
	_loading = true
	_directory = directory
	_saved = false
	save_button.disabled = false
	copy_button.disabled = true
	close_button.text = "Keep draft & close"
	title_field.text = ""
	description.text = ""
	expected.text = ""
	reproduction.text = ""
	for option in [type_field, area_field, impact_field, frequency_field]:
		option.select(0)
	preview.texture = ImageTexture.create_from_image(image) if image else null
	preview.visible = image != null
	context.text = "%s · %.0f FPS · %s\nGame paused; prior pause state will be restored." % [
		data.capture.scene_name, data.capture.fps,
		"Screenshot + clip" if data.attachments.has("recording") else "Screenshot"]
	status.text = "Notes autosave as a draft. Ctrl+Enter saves and copies a handoff."
	if not data.capture_errors.is_empty():
		status.text = "Capture issue: " + "; ".join(data.capture_errors) + " Notes and diagnostics can still be saved."
	var available := get_tree().root.size - Vector2i(40, 40)
	size = Vector2i(mini(980, available.x), mini(860, available.y))
	popup_centered()
	description.grab_focus()
	_loading = false

func fields() -> Dictionary:
	return {"title": title_field.text.strip_edges(), "description": description.text,
		"expected": expected.text, "reproduction": reproduction.text,
		"type": type_field.get_item_text(type_field.selected),
		"area": area_field.get_item_text(area_field.selected),
		"impact": impact_field.get_item_text(impact_field.selected),
		"frequency": frequency_field.get_item_text(frequency_field.selected)}

func _changed() -> void:
	if _loading:
		return
	_saved = false
	save_button.disabled = false
	copy_button.disabled = true
	close_button.text = "Keep draft & close"
	_draft_timer.start()

func _autosave() -> void:
	if visible and not _saved:
		var error: Error = capture.save_fields(fields(), false)
		status.text = "Draft saved locally." if error == OK else "Draft could not be saved: " + error_string(error) + ". Keep this panel open and copy your notes."

func _save() -> void:
	if description.text.strip_edges().is_empty():
		status.text = "Add a short description so the capture has your feedback."
		description.grab_focus()
		return
	_draft_timer.stop()
	var error: Error = capture.save_fields(fields(), true)
	if error != OK:
		status.text = "Could not finish saving: " + error_string(error) + ". Notes remain here; try again."
		return
	_saved = true
	save_button.disabled = true
	copy_button.disabled = false
	close_button.text = "Close & return"
	_copy()
	status.text = "Saved locally; handoff copied. Tell Codex ‘review my latest feedback’ or paste the handoff."

func _copy() -> void:
	DisplayServer.clipboard_set(capture.handoff())

func _close() -> void:
	_draft_timer.stop()
	if not _saved:
		var error: Error = capture.save_fields(fields(), false)
		if error != OK:
			status.text = "Draft save failed: " + error_string(error) + ". Copy your notes before closing."
			return
	capture.close_report()

func _window_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			set_input_as_handled()
			_close()
		elif event.ctrl_pressed and event.keycode == KEY_ENTER:
			set_input_as_handled()
			_save()
