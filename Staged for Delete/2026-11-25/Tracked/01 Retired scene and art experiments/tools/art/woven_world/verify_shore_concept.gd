extends SceneTree
## Run through Godot with --script tools/art/woven_world/verify_shore_concept.gd.

const FOLDER := "res://Src/Tests/Art/WovenWorld/"
const SHORE := FOLDER + "woven_shore_concept.tscn"
const ROOFTOPS := FOLDER + "woven_concept_rooftops.tscn"
const AQUEDUCTS := FOLDER + "woven_concept_aqueducts.tscn"
const DELIVERY := "res://ArtSource/Deliveries/WovenShoreNativeStamps/"
const SCALE := 2.5
const FEET := 69.245

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if change_scene_to_file(SHORE) != OK:
		quit(1)
		return
	await scene_changed
	await _frames(35)
	_check(get_nodes_in_group(&"player").size() == 1, "One player instanced on arrival")
	_check(_player().is_on_floor() and _player().position.x < 825, "Arrival on dry cave floor")
	_check(current_scene.has_node("Encounters/ShorePatrol"), "Shore combat encounter instanced")
	_verify_art_stamps()
	await _capture("game_chamber.png")
	# Keep jump timings independent of enemies while checking the authored geometry.
	current_scene.get_node("Encounters").queue_free()
	await _jump_between(313, 434, 400, 399, false, "Chamber to tree island")
	await _jump_between(580, 399, 790, 371, true, "Tree island to second island")
	await _jump_between(1027, 371, 1230, 371, true, "Second island to farm road")
	await _jump_between(466, 399, 470, 321, false, "First island to tree perch")
	await _jump_between(480, 321, 577, 277, false, "Tree perch to floating steps")
	await _jump_between(620, 277, 683, 218, false, "West step to upper shelf")
	await _jump_between(441, 321, 289, 199, true, "Backtrack to hidden Chamber shelf")
	await _capture("game_hidden_shelf.png")
	await _jump_between(815, 218, 897, 173, false, "West shelf to upper high perch")
	await _jump_between(924, 173, 1043, 213, false, "High perch to east approach")
	await _jump_between(1062, 213, 1130, 169, false, "East approach to irrigation stepping stones")
	await _jump_between(1179, 169, 1263, 139, false, "Arrive at the locked high route")
	_check(current_scene.get_node("Art/IrrigationLatch").visible, "High gate starts closed")
	await _capture("game_upper_route.png")
	await _visit(Vector2(4760, 866))
	await _capture("game_farm_road.png")

	await _visit(Vector2(697, 608) * SCALE)
	_check(_player().is_in_prototype_water(), "Lake physics active beneath island gaps")
	Input.action_press(&"move_right")
	for frame in 95:
		await physics_frame
		if _player().position.x >= 881 * SCALE:
			break
	Input.action_release(&"move_right")
	_check(absf(_player().position.x / SCALE - 881) < 13.0, "Swim beneath the nook opening")
	Input.action_press(&"move_up")
	var surfaced := false
	for frame in 98:
		await physics_frame
		if _player().position.y < 486 * SCALE and not _player().is_in_prototype_water():
			surfaced = true
			break
	Input.action_release(&"move_up")
	_check(surfaced, "Swim up and surface inside the second island")
	await _capture("game_swim_nook.png")

	await _at("Interactions/VillageRoad")
	await _interact()
	_check(current_scene.scene_file_path == ROOFTOPS, "Farm road goes to the rooftop landing")
	if current_scene.scene_file_path == ROOFTOPS:
		await _at("UpperReturn")
		await _interact()
	_check(current_scene.scene_file_path == SHORE and _player().position.y < 400.0, "Rooftop ridge route returns behind the gate")
	if current_scene.scene_file_path == SHORE:
		await _at("Interactions/IrrigationLatch")
		await _interact()
		_check(not current_scene.get_node("Art/IrrigationLatch").visible, "Town-side latch opens high crossing")
		_check(current_scene.get_node("Terrain/IrrigationBarrier/Shape").disabled, "Open high crossing is passable")
		await _at("Interactions/IntakeLatch")
		await _capture("game_aqueduct_gate.png")
		await _interact()
		_check(not current_scene.get_node("Art/AqueductGrate").visible, "Underwater interaction opens intake")
		_check(current_scene.get_node("Terrain/IntakeBarrier/Shape").disabled, "Open intake is swimmable")
		Input.action_press(&"move_right")
		for frame in 320:
			await physics_frame
			if _player().position.x >= 2080 * SCALE:
				break
		Input.action_release(&"move_right")
		_check(_player().position.x >= 2052 * SCALE and _player().is_in_prototype_water(), "Swim the full Aqueducts conduit")
		await _capture("game_aqueduct_conduit.png")
		await _interact()
	_check(current_scene.scene_file_path == AQUEDUCTS, "Intake tunnel reaches the Aqueducts landing")
	if current_scene.scene_file_path == AQUEDUCTS:
		await _at("BackToShore")
		await _interact()
	_check(current_scene.scene_file_path == SHORE, "Aqueducts landing returns to the shore")
	if current_scene.scene_file_path == SHORE:
		_check(not current_scene.get_node("Art/AqueductGrate").visible, "Raised intake stays open on return")
		_check(not current_scene.get_node("Art/IrrigationLatch").visible, "Raised irrigation gate stays open on return")
		await _at("Interactions/IrrigationExit")
		await _interact()
		_check(current_scene.scene_file_path == ROOFTOPS, "High walk also leads to the rooftops")
		if current_scene.scene_file_path == ROOFTOPS:
			await _at("BackToShore")
			await _interact()
		_check(current_scene.scene_file_path == SHORE and _player().position.x > 4800, "Main rooftop exit returns to farm road")

	var rendered := DisplayServer.get_name() != "headless"
	var result := {"checks": checks, "failures": failures, "rendered": rendered}
	var report := FileAccess.open(DELIVERY + ("gpu_checks.json" if rendered else "headless_checks.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(result, "  ") + "\n")
	print("WOVEN_SHORE_CONCEPT ", JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)


func _verify_art_stamps() -> void:
	var stamps := current_scene.get_node("Art").find_children("*", "Sprite2D")
	var concept_crops: Array[String] = []
	var enlarged: Array[String] = []
	for stamp: Sprite2D in stamps:
		if stamp.texture == null or stamp.texture.resource_path.contains("/ConceptLayout/"):
			concept_crops.append(stamp.name)
		if stamp.scale.x > 1.0 or stamp.scale.y > 1.0:
			enlarged.append(stamp.name)
	_check(stamps.size() > 30 and concept_crops.is_empty(), "Gameplay art uses independently placed stamps: %s" % str(concept_crops))
	_check(enlarged.is_empty(), "Gameplay stamps are placed at or below their original pixel size: %s" % str(enlarged))
	_check(current_scene.has_node("Art/IslandTree") and current_scene.has_node("Art/FieldCottage"),
		"Tree and cottage art are editable separately from the ground")


func _jump_between(x_from: float, y_from: float, x_to: float, y_to: float, double_jump: bool, label: String) -> void:
	await _visit(Vector2(x_from * SCALE, y_from * SCALE - FEET - 1.0))
	var actor := _player()
	var direction := signf(x_to - x_from)
	var movement := &"move_left" if direction < 0 else &"move_right"
	if absf(x_to - x_from) > 10.0:
		Input.action_press(movement)
	Input.action_press(&"Jump")
	var landed := false
	var climb_pressed := false
	for frame in 115:
		await physics_frame
		if climb_pressed:
			Input.action_release(&"move_up")
			climb_pressed = false
		if actor.is_ledge_hanging and absf(actor.position.x / SCALE - x_to) < 54.0:
			Input.action_release(movement)
			Input.action_press(&"move_up")
			climb_pressed = true
		if (x_to * SCALE - actor.position.x) * direction < 12.0:
			Input.action_release(movement)
		if double_jump and frame == 25:
			Input.action_release(&"Jump")
		if double_jump and frame == 27:
			Input.action_press(&"Jump")
		if frame > 6 and actor.is_on_floor() and absf(actor.position.y + FEET - y_to * SCALE) < 8.0:
			landed = absf(actor.position.x / SCALE - x_to) < 34.0
			if landed:
				break
	Input.action_release(&"Jump")
	Input.action_release(movement)
	Input.action_release(&"move_up")
	_check(landed, "%s ended at %s (floor %s, hanging %s)" % [
		label, actor.position / SCALE, actor.is_on_floor(), actor.is_ledge_hanging])


func _player() -> CharacterBody2D:
	return current_scene.get_node("Player")


func _at(path: NodePath) -> void:
	await _visit(current_scene.get_node(path).global_position)


func _visit(position: Vector2) -> void:
	var actor := _player()
	actor.is_ledge_hanging = false
	actor.is_ledge_climbing = false
	actor.is_wall_clinging = false
	actor.position = position
	actor.velocity = Vector2.ZERO
	actor.reset_physics_interpolation()
	await _frames(12)


func _interact() -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	root.push_input(event)
	await _frames(2)
	event.pressed = false
	root.push_input(event)
	await _frames(16)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(40)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(DELIVERY + filename) == OK, "Captured " + filename)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)
