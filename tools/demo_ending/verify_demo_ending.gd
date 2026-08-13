extends Node

const ENDING_SCENE := preload("res://Src/UI/DemoEnding/demo_ending.tscn")
const EXIT_SCENE := preload("res://Src/Environment/Doors/demo_ending_exit.tscn")
const EXPECTED_FEEDBACK_URL := "https://tally.so/r/Bzo0z5"

var _failures: PackedStringArray = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_verification")

func _run_verification() -> void:
	_verify_progress_api()
	await _verify_ending_screen()
	await _verify_ending_exit()
	get_tree().paused = false
	if _failures.is_empty():
		print("Demo ending verification passed.")
		get_tree().quit(0)
		return

	for failure in _failures:
		push_error("Demo ending verification: " + failure)
	print("Demo ending verification failed with %d issue(s)." % _failures.size())
	get_tree().quit(1)

func _verify_progress_api() -> void:
	_expect(DemoProgress.has_method("mark_demo_completed"), "DemoProgress can record completion.")
	_expect(DemoProgress.has_method("is_demo_completed"), "DemoProgress exposes completion state.")

func _verify_ending_screen() -> void:
	var ending := ENDING_SCENE.instantiate()
	ending.record_completion = false
	ending.fade_duration = 0.05
	add_child(ending)
	await get_tree().process_frame
	_expect(ending.is_in_group("demo_ending_screen"), "Ending screen registers its active group.")
	_expect(ending.config != null, "Ending screen has editable configuration.")
	if ending.config:
		_expect(ending.config.playtest_support != null, "Ending screen shares playtest-support configuration.")
		if ending.config.playtest_support:
			_expect(ending.config.playtest_support.playtest_report_url == EXPECTED_FEEDBACK_URL, "Feedback URL matches the published Tally form.")
			_expect(ending.config.playtest_support.feedback_qr_texture != null, "Feedback QR texture is configured.")
	var feedback_button := ending.get_node_or_null("Root/MainPage/Content/FeedbackRow/Actions/FeedbackButton") as Button
	var note_button := ending.get_node_or_null("Root/MainPage/Content/FeedbackRow/Actions/NoteButton") as Button
	var credits_button := ending.get_node_or_null("Root/MainPage/Content/FeedbackRow/Actions/CreditsButton") as Button
	var main_menu_button := ending.get_node_or_null("Root/MainPage/Content/FeedbackRow/Actions/MainMenuButton") as Button
	_expect(feedback_button != null and feedback_button.text == "GIVE PLAYTEST FEEDBACK", "Feedback action is present.")
	_expect(note_button != null and note_button.text == "A NOTE FROM CHASE", "Personal-note action is present.")
	var note_text := ending.get_node_or_null("Root/NotePage/NotePanel/Margin/NoteText") as RichTextLabel
	_expect(note_text != null and note_text.text.contains("God bless you and keep you"), "Chase's personal note is configured.")
	_expect(credits_button != null and credits_button.text == "VIEW CREDITS", "Credits action is present.")
	_expect(main_menu_button != null and main_menu_button.text == "RETURN TO MAIN MENU", "Main-menu action is present.")
	var credits_text := ending.get_node_or_null("Root/CreditsPage/CreditsPanel/Margin/CreditsText") as RichTextLabel
	_expect(credits_text != null and credits_text.text.contains("Chase King"), "Primary creator credit is present.")
	_expect(credits_text != null and credits_text.text.contains("Jeremy Wilcox"), "Jeremy Wilcox credit is present.")
	_expect(credits_text != null and credits_text.text.contains("dallen72"), "dallen72 credit is present.")
	_expect(credits_text != null and credits_text.text.contains("Ben Lutz"), "Ben Lutz credit is present.")
	ending.queue_free()
	get_tree().paused = false
	await get_tree().process_frame

func _verify_ending_exit() -> void:
	var ending_exit := EXIT_SCENE.instantiate()
	ending_exit.reveal_duration = 0.05
	add_child(ending_exit)
	await get_tree().process_frame
	_expect(not ending_exit.visible, "Ending exit begins hidden.")
	ending_exit.reveal()
	await get_tree().create_timer(0.08).timeout
	_expect(ending_exit.visible, "Ending exit reveals after boss resolution.")
	_expect(ending_exit.monitoring, "Revealed ending exit accepts player interaction.")
	ending_exit.queue_free()
	await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
