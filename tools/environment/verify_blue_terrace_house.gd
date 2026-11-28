extends SceneTree
## Regression for the painted house's deliberate entry, focus, and same-room exit.

const ROOM := "res://Src/Environment/BlueBiome/blue_blockout.tscn"
const OUT := "res://tmp/blue-terrace-entry"
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(label)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame


func _move_to(player: CharacterBody2D, target: Vector2) -> void:
	player.global_position = target
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await _frames(30)


func _action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var path := ROOM
	for argument in args:
		if argument.begins_with("--room="):
			path = argument.trim_prefix("--room=")
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("Could not load " + path)
		quit(1)
		return
	var room := scene.instantiate()
	root.add_child(room)
	current_scene = room
	var house := room.get_node("Geometry/EastTerraceHouse") as Sprite2D
	var door := house.get_node("Door") as Area2D
	var interior := house.get_node("Interior") as Node2D
	var glow := door.get_node("Glow") as Sprite2D
	var focus := house.get_node("InteriorFocus")
	var player := room.get_node("Player") as CharacterBody2D
	var camera := player.get_node("Camera2D") as Camera2D
	var workbench := room.get_node("Geometry/PaintedBridge/HouseTableStep") as CollisionShape2D
	var atmosphere := room.get_node("Atmosphere")
	atmosphere.set_preview(12.0, 0)
	atmosphere.time_scale = 0.0
	var door_position := door.global_position
	var previous_zoom := camera.zoom
	var previous_position := camera.position
	var previous_limits := Vector4i(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom)
	var previous_mask := player.collision_mask

	await _move_to(player, door_position + Vector2(-400, -110))
	_check(player.is_on_floor() and not interior.visible and workbench.disabled,
		"The former automatic cutaway boundary now stays closed on the deck")
	_check(not house.can_use_door(player) and glow.modulate.a == 1.0, "The glow marks the actual door and the rest of the deck cannot trigger it")
	await _move_to(player, door_position + Vector2(-42, -110))
	_check(house.can_use_door(player) and player.current_selector == door and not interior.visible,
		"The normal Interact adapter offers entry on a closed door")
	if args.has("--render"):
		await _capture("terrace-outside")
	_action(&"move_up", true)
	await _frames(23)
	_check(player.house_door_transition_owner == house and player.live_3d_visual.get("_door_active"),
		"Up starts the existing turn-and-walk pose")
	_check(interior.visible and interior.modulate.a > 0.0 and interior.modulate.a < 0.95,
		"The cutaway has a visible intermediate fade")
	await _frames(49)
	_check(house.is_player_inside(player) and player.is_on_floor() and interior.modulate.a == 1.0 and not workbench.disabled,
		"Holding Up leaves the player inside on the two-story floor")
	_check(player.get_collision_mask_value(32) and player.house_door_transition_owner == null,
		"The occupied actor scans the interior boundaries and has normal movement back")
	_check(focus.weight > 0.99 and camera.zoom.x > previous_zoom.x and focus.outside_blur_lod > 0.0,
		"The camera frames the room with the exterior blur active")
	if args.has("--render"):
		await _capture("terrace-inside")
		await _verify_blur(room, focus)
	_action(&"move_up", false)
	await _frames(3)
	_check(player.current_selector == door, "The same door offers Exit indoors")

	_action(&"interact", true)
	await _frames(3)
	_action(&"interact", false)
	await _frames(64)
	_check(not house.is_player_inside(player) and not interior.visible and workbench.disabled,
		"Interact exits and restores the painted facade")
	_check(player.collision_mask == previous_mask and player.house_door_transition_owner == null,
		"Exit restores the outside player's original collision mask and controls")
	_check(camera.zoom == previous_zoom and camera.position == previous_position and
		Vector4i(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom) == previous_limits,
		"Focus restores the exact outdoor camera settings after exit")
	await _frames(6)
	house.request_door(player)
	await _frames(41)
	room.return_to_spawn()
	_check(not house.is_player_inside(player) and player.house_door_transition_owner == null and
		player.collision_mask == previous_mask and camera.zoom == previous_zoom and not interior.visible,
		"Respawn during the handoff restores the house, camera and actor immediately")
	await _frames(3)
	_check(workbench.disabled and not focus.overlay.visible, "Respawn clears deferred interior collision and screen effects")
	print("BLUE TERRACE HOUSE ", _checks, " checks, ", _failures, " failed")
	quit(0 if _failures == 0 else 1)


func _pixels() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _capture(filename: String) -> void:
	var image := await _pixels()
	DirAccess.make_dir_recursive_absolute(OUT)
	image.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	image.save_png(OUT.path_join(filename + ".png"))


func _verify_blur(room: Node, focus: Node) -> void:
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var material := focus.effect.material as ShaderMaterial
	var lod: float = material.get_shader_parameter("outside_blur_lod")
	var bounds: Vector4 = material.get_shader_parameter("room_screen_rect")
	var blurred := await _pixels()
	material.set_shader_parameter("outside_blur_lod", 0.0)
	var sharp := await _pixels()
	var exterior_changes := 0
	var interior_changes := 0
	for y in range(blurred.get_height() / 8, blurred.get_height() * 6 / 8, 6):
		for x in range(blurred.get_width() / 8, blurred.get_width() * 7 / 8, 6):
			var uv := Vector2(float(x) / blurred.get_width(), float(y) / blurred.get_height())
			var outside := uv.x < bounds.x - 0.03 or uv.x > bounds.z + 0.03 or uv.y < bounds.y - 0.03 or uv.y > bounds.w + 0.03
			var inside := uv.x > bounds.x + 0.03 and uv.x < bounds.z - 0.03 and uv.y > bounds.y + 0.03 and uv.y < bounds.w - 0.03
			var diff := blurred.get_pixel(x, y) - sharp.get_pixel(x, y)
			if absf(diff.r) + absf(diff.g) + absf(diff.b) > 0.08:
				exterior_changes += int(outside)
				interior_changes += int(inside)
	_check(exterior_changes > 60 and exterior_changes > interior_changes * 4,
		"Exterior pixels soften while the cutaway stays sharp: %d outside, %d inside" % [exterior_changes, interior_changes])
	material.set_shader_parameter("outside_blur_lod", lod)
	room.process_mode = Node.PROCESS_MODE_INHERIT
