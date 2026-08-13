class_name PlaytestWelcome
extends CanvasLayer

@export var config: PlaytestSupportConfig

@onready var root: Control = $Root as Control
@onready var begin_button: Button = $Root/Panel/Margin/Content/BeginButton as Button
@onready var playtest_report_button: Button = $Root/Panel/Margin/Content/Links/PlaytestReportButton as Button
@onready var bug_report_button: Button = $Root/Panel/Margin/Content/Links/BugReportButton as Button
@onready var status_label: Label = $Root/Panel/Margin/Content/Status as Label

var _focus_visuals_enabled := true
var _focus_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("playtest_welcome")
	if DemoProgress.has_checkpoint() or DemoProgress.has_acknowledged_playtest_welcome():
		queue_free()
		return

	begin_button.pressed.connect(_begin_demo)
	playtest_report_button.pressed.connect(_open_playtest_report)
	bug_report_button.pressed.connect(_open_bug_report)
	playtest_report_button.disabled = config == null or not config.has_playtest_report()
	bug_report_button.disabled = config == null or not config.has_bug_report()
	_focus_buttons = [begin_button, playtest_report_button, bug_report_button]
	_set_focus_visuals(false)
	root.modulate.a = 0.0
	get_tree().paused = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate:a", 1.0, 0.45)
	begin_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_focus_visuals(false)
	elif (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		_set_focus_visuals(true)

func _begin_demo() -> void:
	DemoProgress.acknowledge_playtest_welcome()
	AudioManager.play_ui(&"menu_select")
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().paused = false
	queue_free()

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
