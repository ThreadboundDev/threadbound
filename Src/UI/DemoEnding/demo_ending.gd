class_name DemoEndingScreen
extends CanvasLayer

signal closed

const MAIN_MENU_SCENE := "res://Src/UI/MainMenu/main_menu.tscn"

@export var config: DemoEndingConfig
@export var record_completion := true
@export_range(0.05, 3.0, 0.05) var fade_duration := 0.8

@onready var root: Control = $Root as Control
@onready var main_page: Control = $Root/MainPage as Control
@onready var credits_page: Control = $Root/CreditsPage as Control
@onready var note_page: Control = $Root/NotePage as Control
@onready var title_label: Label = $Root/MainPage/Content/Title as Label
@onready var message_label: Label = $Root/MainPage/Content/Message as Label
@onready var qr_texture: TextureRect = $Root/MainPage/Content/FeedbackRow/QRColumn/QRFrame/QR as TextureRect
@onready var feedback_button: Button = $Root/MainPage/Content/FeedbackRow/Actions/FeedbackButton as Button
@onready var note_button: Button = $Root/MainPage/Content/FeedbackRow/Actions/NoteButton as Button
@onready var credits_button: Button = $Root/MainPage/Content/FeedbackRow/Actions/CreditsButton as Button
@onready var main_menu_button: Button = $Root/MainPage/Content/FeedbackRow/Actions/MainMenuButton as Button
@onready var feedback_status: Label = $Root/MainPage/Content/FeedbackStatus as Label
@onready var credits_text: RichTextLabel = $Root/CreditsPage/CreditsPanel/Margin/CreditsText as RichTextLabel
@onready var credits_back_button: Button = $Root/CreditsPage/BackButton as Button
@onready var note_text: RichTextLabel = $Root/NotePage/NotePanel/Margin/NoteText as RichTextLabel
@onready var note_back_button: Button = $Root/NotePage/BackButton as Button

var _closing := false
var _focus_visuals_enabled := true
var _focus_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("demo_ending_screen")
	feedback_button.pressed.connect(_open_feedback)
	note_button.pressed.connect(_show_note)
	credits_button.pressed.connect(_show_credits)
	main_menu_button.pressed.connect(_return_to_main_menu)
	credits_back_button.pressed.connect(_show_main_page)
	note_back_button.pressed.connect(_show_main_page)
	_focus_buttons = [feedback_button, note_button, credits_button, main_menu_button, credits_back_button, note_back_button]
	_set_focus_visuals(false)
	_apply_config()
	_prepare_intro()
	if record_completion:
		DemoProgress.mark_demo_completed()
	get_tree().paused = true
	_run_intro()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_focus_visuals(false)
	elif (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		_set_focus_visuals(true)

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("ui_cancel") and (credits_page.visible or note_page.visible):
		get_viewport().set_input_as_handled()
		_show_main_page()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and get_tree():
		get_tree().paused = false

func _apply_config() -> void:
	if not config:
		feedback_button.disabled = true
		feedback_status.text = "Feedback form is not configured."
		return

	title_label.text = config.title
	message_label.text = config.message
	note_text.text = config.personal_note
	note_button.visible = not config.personal_note.strip_edges().is_empty()
	var support := config.playtest_support
	qr_texture.texture = support.feedback_qr_texture if support else null
	qr_texture.visible = support != null and support.feedback_qr_texture != null
	feedback_button.disabled = support == null or not support.has_playtest_report()
	feedback_status.text = (
		"SCAN THE CODE OR OPEN THE PLAYTEST REPORT"
		if not feedback_button.disabled
		else "FEEDBACK FORM IS NOT CONFIGURED"
	)
	credits_text.text = _build_credits_text()

func _build_credits_text() -> String:
	if not config:
		return "Credits are not configured."

	var sections: PackedStringArray = []
	var section_count := mini(config.credit_categories.size(), config.credit_entries.size())
	for index in section_count:
		var section := (
			"[center][font_size=25][color=#d9c58c]%s[/color][/font_size]\n"
			+ "[font_size=34][color=#f2e5c4]%s[/color][/font_size][/center]"
		)
		sections.append(section % [config.credit_categories[index], config.credit_entries[index]])
	return "\n\n".join(sections)

func _prepare_intro() -> void:
	root.modulate.a = 0.0
	main_page.visible = true
	credits_page.visible = false
	note_page.visible = false
	feedback_status.modulate.a = 0.72

func _run_intro() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 1.0, fade_duration)
	await tween.finished
	if is_instance_valid(feedback_button) and not feedback_button.disabled:
		feedback_button.grab_focus()
	else:
		credits_button.grab_focus()

func _open_feedback() -> void:
	if not config or not config.playtest_support or not config.playtest_support.has_playtest_report():
		feedback_status.text = "FEEDBACK FORM IS NOT CONFIGURED"
		return
	AudioManager.play_ui(&"menu_select")
	var error := OS.shell_open(config.playtest_support.playtest_report_url)
	feedback_status.text = (
		"PLAYTEST REPORT OPENED IN YOUR BROWSER"
		if error == OK
		else "COULD NOT OPEN THE PLAYTEST REPORT"
	)

func _show_credits() -> void:
	AudioManager.play_ui(&"ui_click")
	main_page.visible = false
	credits_page.visible = true
	credits_back_button.grab_focus()

func _show_note() -> void:
	AudioManager.play_ui(&"ui_click")
	main_page.visible = false
	credits_page.visible = false
	note_page.visible = true
	note_text.scroll_to_line(0)
	note_back_button.grab_focus()

func _show_main_page() -> void:
	AudioManager.play_ui(&"ui_click")
	credits_page.visible = false
	note_page.visible = false
	main_page.visible = true
	note_button.grab_focus()

func _return_to_main_menu() -> void:
	if _closing:
		return
	_closing = true
	AudioManager.play_ui(&"menu_select")
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate:a", 0.0, fade_duration * 0.65)
	await tween.finished
	get_tree().paused = false
	closed.emit()
	var tree := get_tree()
	queue_free()
	var error := tree.change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_warning("Demo ending could not return to the main menu: %s." % error_string(error))
		_closing = false

func _set_focus_visuals(enabled: bool) -> void:
	if _focus_visuals_enabled == enabled:
		return
	_focus_visuals_enabled = enabled
	for button in _focus_buttons:
		if enabled:
			button.add_theme_stylebox_override("focus", button.get_theme_stylebox("hover"))
		else:
			button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
