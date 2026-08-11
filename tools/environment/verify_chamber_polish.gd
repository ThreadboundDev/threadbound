extends Node

const CHAMBER_SCENE := preload("res://Src/Environment/World/Chamber Of The First Weave.tscn")
const OPTIONS_SCENE := preload("res://Src/UI/Options/options_panel.tscn")

var _failures: Array[String] = []

func _ready() -> void:
	_verify_brightness_mapping()
	_verify_options_ui()
	_verify_blue_attempt_timer()
	_verify_chamber_content()
	if _failures.is_empty():
		print("CHAMBER_POLISH_VERIFY: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("CHAMBER_POLISH_VERIFY: %s" % failure)
	get_tree().quit(1)

func _verify_brightness_mapping() -> void:
	var saved_preview := DisplaySettings._preview_brightness
	DisplaySettings._preview_brightness = DisplaySettings.DEFAULT_BRIGHTNESS
	_expect(
		is_equal_approx(DisplaySettings.get_brightness_multiplier(), 1.0),
		"The authored 80% brightness point must map to a neutral multiplier."
	)
	DisplaySettings._preview_brightness = 1.0
	_expect(
		DisplaySettings.get_brightness_multiplier() > 1.0,
		"Brightness above 80% must provide additional visibility."
	)
	DisplaySettings._preview_brightness = 0.0
	_expect(
		DisplaySettings.get_brightness_multiplier() >= 0.6,
		"Minimum brightness must remain playable rather than becoming black."
	)
	DisplaySettings._preview_brightness = saved_preview

func _verify_options_ui() -> void:
	var options := OPTIONS_SCENE.instantiate()
	_expect(
		options.get_node_or_null("Pages/Graphics/Rows/Brightness") is BrightnessSlider,
		"Graphics options must contain the brightness slider."
	)
	options.free()

func _verify_blue_attempt_timer() -> void:
	var objective := BalanceWingObjective.new()
	objective.attempt_duration = 1.0
	for index in 3:
		var button := BlueWingButton.new()
		button.name = "TestButton%d" % index
		objective.add_child(button)
		objective.call("_register_button", button)
	var first_button := objective.get_child(0) as BlueWingButton
	first_button.activate()
	_expect(bool(objective.get("_attempt_active")), "The first Blue button must begin an attempt.")
	objective.call("_process", 1.1)
	_expect(not first_button.is_active, "An expired Blue attempt must reset every button.")
	objective.free()

func _verify_chamber_content() -> void:
	var chamber := CHAMBER_SCENE.instantiate()
	var red_encounter := chamber.get_node_or_null(
		"WorldArt/Rooms/RedWing/EnemyEncounter"
	) as EnemySection
	_expect(
		red_encounter != null
		and red_encounter.enemy_influence == EnemyInfluenceController.Influence.RED,
		"The Red room breakout must apply Red influence recursively."
	)
	var blue_objective := chamber.get_node_or_null(
		"WorldArt/Rooms/BlueWing/Objective/BlueWingObjective"
	) as BalanceWingObjective
	_expect(blue_objective != null, "The Blue objective must be present in the chamber.")
	if blue_objective:
		_expect(
			blue_objective.enemy_spawn_marker_paths.size() == 6,
			"The Blue traversal encounter must contain six authored spawns."
		)
	var blue_encounter := chamber.get_node_or_null(
		"WorldArt/Rooms/BlueWing/Objective/BlueWingObjective/EncounterEnemies"
	) as EnemySection
	_expect(
		blue_encounter != null
		and blue_encounter.enemy_influence == EnemyInfluenceController.Influence.BLUE,
		"The Blue spawn breakout must apply Blue influence to every attempt spawn."
	)
	var yellow_encounter := chamber.get_node_or_null(
		"WorldArt/Rooms/YellowWing/EnemyEncounter"
	) as EnemySection
	_expect(
		yellow_encounter != null
		and yellow_encounter.enemy_influence == EnemyInfluenceController.Influence.YELLOW,
		"The Yellow room breakout must apply Yellow influence recursively."
	)
	if yellow_encounter:
		var enemy_count := 0
		for child in yellow_encounter.get_children():
			if child is EnemyBase:
				enemy_count += 1
		_expect(enemy_count == 4, "The Yellow wing must contain four restrained enemy placements.")
	chamber.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
