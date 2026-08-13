class_name PlaytestSupportPanel
extends Control

signal back_requested

@export var config: PlaytestSupportConfig

@onready var playtest_report_button: Button = $Panel/Margin/Content/PlaytestReportButton as Button
@onready var bug_report_button: Button = $Panel/Margin/Content/BugReportButton as Button
@onready var back_button: Button = $Panel/Margin/Content/BackButton as Button
@onready var status_label: Label = $Panel/Margin/Content/Status as Label

var _focus_visuals_enabled := true
var _focus_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_focus_buttons = [playtest_report_button, bug_report_button, back_button]
	playtest_report_button.pressed.connect(_open_playtest_report)
	bug_report_button.pressed.connect(_open_bug_report)
	back_button.pressed.connect(close)
	playtest_report_button.disabled = config == null or not config.has_playtest_report()
	bug_report_button.disabled = config == null or not config.has_bug_report()
	_set_focus_visuals(false)

func open() -> void:
	visible = true
	status_label.text = ""
	_set_focus_visuals(false)
	if not playtest_report_button.disabled:
		playtest_report_button.grab_focus()
	elif not bug_report_button.disabled:
		bug_report_button.grab_focus()
	else:
		back_button.grab_focus()

func close() -> void:
	visible = false
	for button in _focus_buttons:
		button.release_focus()
	back_requested.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		_set_focus_visuals(false)
	elif (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		_set_focus_visuals(true)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _open_playtest_report() -> void:
	if config:
		_open_url(config.playtest_report_url, "PLAYTEST REPORT OPENED IN YOUR BROWSER")

func _open_bug_report() -> void:
	if config:
		_open_url(config.bug_report_url, "BUG REPORT OPENED IN YOUR BROWSER")

func _open_url(url: String, success_message: String) -> void:
	if url.strip_edges().is_empty():
		status_label.text = "THIS FORM IS NOT CONFIGURED"
		return
	AudioManager.play_ui(&"menu_select")
	var error := OS.shell_open(url)
	status_label.text = success_message if error == OK else "COULD NOT OPEN THE FORM"

func _set_focus_visuals(enabled: bool) -> void:
	if _focus_visuals_enabled == enabled:
		return
	_focus_visuals_enabled = enabled
	for button in _focus_buttons:
		if enabled:
			button.add_theme_stylebox_override("focus", button.get_theme_stylebox("hover"))
		else:
			button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
