extends Node

var _failures: Array[String] = []

func _ready() -> void:
	_verify_catalog()
	_verify_progress_api()
	_verify_scenes()
	_verify_hud()
	_verify_controller_defaults()
	if _failures.is_empty():
		print("Demo lore and guidance verification passed.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _verify_catalog() -> void:
	for lore_id in LoreCatalog.ORDER:
		var entry := LoreCatalog.get_entry(lore_id)
		_expect(not entry.is_empty(), "Lore entry %s exists." % lore_id)
		_expect(not String(entry.get("title", "")).is_empty(), "Lore entry %s has a title." % lore_id)
		_expect(not String(entry.get("body", "")).is_empty(), "Lore entry %s has body text." % lore_id)
	_expect(LoreCatalog.ORDER.size() == 10, "The demo catalog contains all ten planned entries.")

func _verify_progress_api() -> void:
	for method_name in [&"unlock_lore", &"has_lore", &"mark_lore_read", &"is_lore_read"]:
		_expect(DemoProgress.has_method(method_name), "DemoProgress exposes %s." % method_name)
	_expect(DemoProgress.has_signal("lore_unlocked"), "DemoProgress exposes the lore pickup signal.")
	_expect(DemoProgress.has_signal("lore_changed"), "DemoProgress exposes the Lore menu refresh signal.")

func _verify_scenes() -> void:
	for scene_path in [
		"res://Src/UI/MainMenu/main_menu.tscn",
		"res://Src/UI/GameMenu/game_menu.tscn",
		"res://Src/UI/combat_hud.tscn",
		"res://Src/UI/MerchantMenu/merchant_menu.tscn",
		"res://Src/Environment/Objectives/balance_wing_objective.tscn",
		"res://Src/Pickups/DemoThreads/thread_of_power_pickup.tscn",
		"res://Src/Pickups/DemoThreads/thread_of_balance_pickup.tscn",
		"res://Src/Pickups/DemoThreads/thread_of_essence_pickup.tscn",
	]:
		_expect(load(scene_path) is PackedScene, "%s loads." % scene_path)
	var main_scene := load("res://Src/UI/MainMenu/main_menu.tscn") as PackedScene
	var main_menu := main_scene.instantiate()
	_expect(main_menu.has_node("NewJourneyConfirmation/Panel/Confirm"), "New Journey has an erase confirmation choice.")
	_expect(main_menu.has_node("NewJourneyConfirmation/Panel/Cancel"), "New Journey has a safe cancellation choice.")
	add_child(main_menu)
	var original_checkpoint_path := DemoProgress.get_checkpoint_scene_path()
	DemoProgress.set("_checkpoint_scene_path", "res://test_checkpoint.tscn")
	main_menu.call("_request_new_journey")
	_expect((main_menu.get_node("NewJourneyConfirmation") as Control).visible, "A resumable run opens the New Journey warning.")
	_expect(int(main_menu.get("_confirmation_index")) == 1, "New Journey confirmation safely defaults to keeping progress.")
	main_menu.call("_hide_new_journey_confirmation")
	DemoProgress.set("_checkpoint_scene_path", original_checkpoint_path)
	main_menu.queue_free()

func _verify_hud() -> void:
	var hud_scene := load("res://Src/UI/combat_hud.tscn") as PackedScene
	var hud := hud_scene.instantiate()
	_expect(hud.has_node("LorePickup/PageIcon"), "HUD lore pickup includes a page icon.")
	_expect(hud.has_node("LorePickup/Title"), "HUD lore pickup includes the entry name.")
	var lore_prompt := hud.get_node("LorePickup/Kind") as RichTextLabel
	_expect(lore_prompt != null and lore_prompt.bbcode_enabled, "HUD lore pickup supports input glyph BBCode.")
	var keyboard_lore_glyph := InputGlyphFormatter.get_action_display_bbcode(&"open_lore", "L", &"keyboard_mouse", 24)
	var controller_lore_glyph := InputGlyphFormatter.get_action_display_bbcode(&"open_lore", "D-PAD DOWN", &"xbox", 24)
	_expect(keyboard_lore_glyph.contains("[img="), "Lore notification resolves the keyboard L glyph.")
	_expect(controller_lore_glyph.contains("[img="), "Lore notification resolves the controller D-pad Down glyph.")
	_expect(hud.has_node("TrialTimer/Title"), "HUD labels the Blue trial clearly.")
	_expect(hud.has_node("TrialTimer/Countdown"), "HUD includes the Blue trial countdown.")
	_expect(hud.has_method("show_lore_pickup"), "HUD can present lore pickups.")
	_expect(hud.has_method("set_trial_timer"), "HUD can update the Blue trial countdown.")
	hud.free()

func _verify_controller_defaults() -> void:
	var hot_swap_on_l2 := false
	for event in InputMap.action_get_events(&"open_menu"):
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_LEFT and event.axis_value > 0.5:
			hot_swap_on_l2 = true
	_expect(hot_swap_on_l2, "Controller Hot Swap defaults to L2.")
	var pause_on_options := false
	for event in InputMap.action_get_events(&"pause_menu"):
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
			pause_on_options = true
	_expect(pause_on_options, "Pause remains on the Options/Menu button.")

func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
