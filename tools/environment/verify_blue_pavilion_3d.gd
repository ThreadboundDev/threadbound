extends SceneTree
## Isolated route checks with the project's existing player and input actions.

var room: Node2D
var capture_dir := ""
var failures: Array[String] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func feet() -> Vector2:
	return room.player.position + Vector2(0, room.FOOT_OFFSET)

func surface_kind(entry: Dictionary) -> String:
	var label := str(entry["name"]).to_lower()
	if "roof" in label:
		return "roof"
	if "stair" in label:
		return "stairs"
	if "lower" in label or "ground" in label:
		return "lower"
	if "deck" in label:
		return "deck"
	return "unknown"

func height_at(surface: Dictionary, x: float) -> float:
	var a: Array = surface["a"]
	var b: Array = surface["b"]
	return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))

func roof_height_at(surfaces: Array[Dictionary], x: float) -> float:
	for surface in surfaces:
		if x >= float(surface["a"][0]) - 0.001 and x <= float(surface["b"][0]) + 0.001:
			return height_at(surface, x)
	return NAN

func move_to_x(target_m: float, action: String, budget := 240) -> bool:
	Input.action_press(action)
	var reached := false
	for i in budget:
		await physics_frame
		if (action == "move_right" and feet().x >= target_m * room.PPM) or (action == "move_left" and feet().x <= target_m * room.PPM):
			reached = true
			break
	Input.action_release(action)
	await frames(8)
	return reached

func screenshot(name_text: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(not image.is_empty(), "Rendered screenshot cannot be empty: " + name_text)
	if not image.is_empty():
		check(image.save_png(capture_dir.path_join(name_text + ".png")) == OK, "Could not save screenshot: " + name_text)

func verify() -> void:
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_pavilion_3d_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(30)
	var surfaces: Array = room.routes["walk_surfaces"]
	var roof_surfaces: Array[Dictionary] = []
	var lower: Dictionary = {}
	var deck: Dictionary = {}
	var stairs: Dictionary = {}
	for raw: Dictionary in surfaces:
		match surface_kind(raw):
			"roof": roof_surfaces.append(raw)
			"lower": lower = raw
			"deck": deck = raw
			"stairs": stairs = raw
			_: check(false, "Unexpected extra walking surface: " + str(raw["name"]))
		check("balcony" not in str(raw["name"]).to_lower() and "access" not in str(raw["name"]).to_lower(), "Floating roof-access platforms must be removed")
	check(not lower.is_empty() and not deck.is_empty() and not stairs.is_empty(), "Expected lower floor, upper deck and one stair route")
	check(surfaces.size() == roof_surfaces.size() + 3, "Only roof, lower floor, upper deck and stairs may be collision routes")
	check(room.geometry.get_child_count() == surfaces.size(), "All declared walking surfaces must have collision")
	check(room.player is CharacterBody2D, "Uses the established 2D player")
	check(room.near_sprite.z_index > room.player.z_index, "Near rails and posts must draw in front of player")
	check(room.far_view.world_3d != null and room.far_view.find_world_3d() == room.near_view.find_world_3d(), "Both art passes must share the same non-null 3D world")
	check(room.far_view.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art cannot introduce 3D player collision")
	for light: Light3D in room.far_view.find_children("*", "Light3D", true, false):
		check((light.layers & 3) == 3, "Lights must reach both art camera layers: " + light.name)
	check(room.far_view.find_children("*Room*", "", true, false).is_empty(), "Lower house geometry must be absent")
	if lower.is_empty() or deck.is_empty() or stairs.is_empty() or roof_surfaces.is_empty():
		finish()
		return
	# Check checkpoint placement against gravity and the real player body.
	for index in [1, 2, 3, 4]:
		room.set_checkpoint(index)
		await frames(40)
		check(room.player.is_on_floor(), "Checkpoint %d must settle on its walking surface" % index)
	# Continuous stairs: real input from the checkpoint, no test-only controller changes.
	room.set_checkpoint(2)
	await frames(25)
	var stair_exit := float(stairs["b"][0]) + 1.1
	var climbed := await move_to_x(stair_exit, "move_right", 240)
	print("STAIR CHECK feet=", feet(), " target=", room.point(stair_exit, float(deck["a"][1])), " on_floor=", room.player.is_on_floor())
	check(climbed and room.player.is_on_floor(), "Player must walk up the stairs onto the upper deck")
	check(absf(feet().y - room.point(0, float(deck["a"][1])).y) < 18.0, "Stairs must connect to the taller upper deck")
	# Run through the pavilion's upper floor and capture the foreground occlusion.
	var deck_target := minf(float(deck["b"][0]) - 1.0, 4.3)
	var crossed_deck := await move_to_x(deck_target, "move_right", 240)
	check(crossed_deck and room.player.is_on_floor(), "Upper deck must be continuously runnable")
	check(absf(feet().y - room.point(0, float(deck["a"][1])).y) < 18.0, "Player must remain on the upper deck")
	print("UPPER DECK CHECK feet=", feet(), " on_floor=", room.player.is_on_floor())
	room.set_checkpoint(3)
	await frames(25)
	await screenshot("playtest-upper-deck")
	room.near_sprite.visible = false
	await frames(8)
	await screenshot("playtest-upper-deck-without-foreground")
	room.near_sprite.visible = true
	# Open lower deck: walk below the pavilion instead of entering an enclosed room.
	room.set_checkpoint(1)
	await frames(25)
	var lower_target := maxf(float(lower["a"][0]) + 1.0, -4.5)
	var crossed_lower := await move_to_x(lower_target, "move_left", 240)
	check(crossed_lower and room.player.is_on_floor(), "Player must run across the open lower deck")
	check(absf(feet().y - room.point(0, float(lower["a"][1])).y) < 18.0, "Lower floor must align with its visual boards")
	print("LOWER DECK CHECK feet=", feet(), " on_floor=", room.player.is_on_floor())
	await screenshot("playtest-lower-deck")
	# Roof traversal starts at its inspection checkpoint; no removed perches are assumed.
	var peak_x := 0.0
	var peak_z := -INF
	var roof_min_x := INF
	var roof_max_x := -INF
	for surface in roof_surfaces:
		for endpoint: Array in [surface["a"], surface["b"]]:
			var x := float(endpoint[0])
			var z := float(endpoint[1])
			roof_min_x = minf(roof_min_x, x)
			roof_max_x = maxf(roof_max_x, x)
			if z > peak_z:
				peak_z = z
				peak_x = x
	room.set_checkpoint(4)
	await frames(30)
	var left_target := maxf(roof_min_x + 1.0, peak_x - 2.5)
	var right_target := minf(roof_max_x - 1.0, peak_x + 2.5)
	var reached_left := await move_to_x(left_target, "move_left", 240)
	check(reached_left and room.player.is_on_floor(), "Player must run along the left roof slope")
	var crossed_peak := await move_to_x(right_target, "move_right", 300)
	var actual_height := roof_height_at(roof_surfaces, feet().x / room.PPM)
	check(crossed_peak and room.player.is_on_floor(), "Player must run across the asymmetric roof peak")
	check(is_finite(actual_height) and absf(feet().y - room.point(0, actual_height).y) < 24.0, "Player must stay on the continuous sampled roof collision")
	print("ROOF RUN CHECK feet=", feet(), " peak_x=", peak_x, " on_floor=", room.player.is_on_floor())
	await screenshot("playtest-roof")
	# Review surface detail at a larger zoom, preserving the gameplay camera's angle.
	room.set_checkpoint(3)
	await frames(25)
	var camera := room.get_node("PavilionCamera") as Camera2D
	camera.zoom = Vector2(0.95, 0.95)
	camera.position = room.point(-0.4, float(deck["a"][1]) + 2.8)
	await frames(10)
	await screenshot("playtest-detail")
	finish()

func finish() -> void:
	print("PAVILION V2 PLAYTEST: ", "PASS" if failures.is_empty() else "FAIL", " | ", failures)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("Jump")
	current_scene = null
	room.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
