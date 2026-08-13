extends Node

const SUPPORT: PlaytestSupportConfig = preload("res://Src/UI/PlaytestSupport/threadbound_playtest_support.tres")
const PAUSE_MENU := preload("res://Src/UI/PauseMenu/pause_menu.tscn")
const WELCOME := preload("res://Src/UI/PlaytestSupport/playtest_welcome.tscn")
const MAIN_MENU := preload("res://Src/UI/MainMenu/main_menu.tscn")

const EXPECTED_PLAYTEST_URL := "https://tally.so/r/Bzo0z5"
const EXPECTED_BUG_URL := "https://tally.so/r/81DrqP"

var _failures: PackedStringArray = []

func _ready() -> void:
	_verify_shared_configuration()
	_verify_pause_menu()
	_verify_welcome()
	_verify_main_menu()
	_verify_progress_api()
	if _failures.is_empty():
		print("Playtest support verification passed.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("Playtest support verification: " + failure)
	get_tree().quit(1)

func _verify_shared_configuration() -> void:
	_expect(SUPPORT.playtest_report_url == EXPECTED_PLAYTEST_URL, "Published playtest-report URL is configured.")
	_expect(SUPPORT.bug_report_url == EXPECTED_BUG_URL, "Published bug-report URL is configured.")
	_expect(SUPPORT.feedback_qr_texture != null, "Feedback QR asset remains configured.")

func _verify_pause_menu() -> void:
	var pause_menu := PAUSE_MENU.instantiate()
	_expect(pause_menu.get_node_or_null("MenuRoot/Buttons/PlaytestSupport") != null, "Pause menu exposes Playtest Support.")
	var report_button := pause_menu.get_node_or_null("PlaytestSupportPanel/Panel/Margin/Content/PlaytestReportButton") as Button
	var bug_button := pause_menu.get_node_or_null("PlaytestSupportPanel/Panel/Margin/Content/BugReportButton") as Button
	_expect(report_button != null and report_button.text == "FILL OUT PLAYTEST REPORT", "Pause submenu exposes the full report.")
	_expect(bug_button != null and bug_button.text == "REPORT A BUG", "Pause submenu exposes the bug report.")
	pause_menu.free()

func _verify_welcome() -> void:
	var welcome := WELCOME.instantiate()
	_expect(welcome.config == SUPPORT, "Welcome overlay uses shared support configuration.")
	var message := welcome.get_node_or_null("Root/Panel/Margin/Content/Message") as Label
	_expect(message != null and message.text.contains("At any time"), "Welcome explains that support remains available.")
	_expect(welcome.get_node_or_null("Root/Panel/Margin/Content/BeginButton") != null, "Welcome has a non-blocking begin action.")
	welcome.free()

func _verify_main_menu() -> void:
	var main_menu := MAIN_MENU.instantiate()
	var support_label := main_menu.get_node_or_null("MenuButtons/Extras/Label") as Label
	_expect(support_label != null and support_label.text == "PLAYTEST SUPPORT", "Main menu exposes Playtest Support.")
	var support_panel := main_menu.get_node_or_null("PlaytestSupportPanel") as PlaytestSupportPanel
	_expect(support_panel != null and support_panel.config == SUPPORT, "Main menu uses the shared support panel and configuration.")
	main_menu.free()

func _verify_progress_api() -> void:
	_expect(DemoProgress.has_method("acknowledge_playtest_welcome"), "Welcome acknowledgement can be persisted.")
	_expect(DemoProgress.has_method("has_acknowledged_playtest_welcome"), "Welcome acknowledgement can be queried.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
