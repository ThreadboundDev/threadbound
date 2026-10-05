extends SceneTree
## Repeat two real placeables and walk the project's player across their seam.
const DECK_PATH := "res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_deck_2m.tscn"
const PLAYER_PATH := "res://Src/Characters/Player/player.tscn"
const FOOT_OFFSET := 69.245

var stage: Node2D
var player: CharacterBody2D
var failures: Array[String] = []
var capture_dir := ""

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

func verify() -> void:
	stage = Node2D.new()
	stage.name = "DeckRepeatVerification"
	root.add_child(stage)
	current_scene = stage
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([
		Vector2(-1500, -1500), Vector2(1500, -1500),
		Vector2(1500, 1500), Vector2(-1500, 1500)
	])
	background.color = Color("619bb0")
	background.z_index = -50
	stage.add_child(background)
	var packed_deck := load(DECK_PATH) as PackedScene
	if packed_deck == null:
		check(false, "Deck placeable scene must load")
		await finish()
		return
	var modules: Array[Node2D] = []
	for index in 2:
		var module := packed_deck.instantiate() as Node2D
		module.name = "Deck%d" % index
		module.position = Vector2(index * 160.0, 0)
		stage.add_child(module)
		modules.append(module)
		check(module.has_node("DeckCollision/WalkingSurface"), "Deck must provide its 2D walking surface")
		var shape := module.get_node("DeckCollision/WalkingSurface") as CollisionPolygon2D
		check(shape.polygon[0] == Vector2.ZERO and shape.polygon[1] == Vector2(160, 0), "Collision endpoints must remain exactly 160 px apart")
		check(not shape.one_way_collision, "Lower deck collision must be solid by default")
		module.one_way = true
		check(shape.one_way_collision, "One Way must update an existing collision surface")
		module.one_way = false
		var far_view := module.get_node("FarRender") as SubViewport
		var near_view := module.get_node("NearRender") as SubViewport
		check(far_view.world_3d != null and far_view.find_world_3d() == near_view.find_world_3d(), "Deck art passes must share their non-null World3D")
		check(far_view.find_children("*", "CollisionObject3D", true, false).is_empty(), "Deck art must contain no 3D player collision")
		check(module.get_node("FarArtwork").z_index < 0 and module.get_node("NearArtwork").z_index > 0, "Deck fascia must draw ahead of the player")
		check(module.get_node("FarArtwork").position == Vector2(80, 0), "Artwork center must match collision midpoint")
		var front_groups := far_view.find_children("Foreground_Trim", "", true, false)
		check(not front_groups.is_empty(), "Model must have separate foreground fascia")
		for light: Light3D in far_view.find_children("*", "Light3D", true, false):
			check((light.layers & 3) == 3, "Module lighting must reach both art passes")
	check(modules[0].far_view.world_3d != modules[1].far_view.world_3d, "Repeated modules must keep isolated lighting stages")
	var end_a: Vector2 = modules[0].to_global(Vector2(160, 0))
	var start_b: Vector2 = modules[1].to_global(Vector2.ZERO)
	check(end_a == start_b, "Repeated 160 px modules must join without a collision gap or overlap")
	var camera := Camera2D.new()
	camera.position = Vector2(160, -75)
	camera.zoom = Vector2(3, 3)
	stage.add_child(camera)
	player = load(PLAYER_PATH).instantiate() as CharacterBody2D
	player.name = "Player"
	stage.add_child(player)
	player.position = Vector2(80, -FOOT_OFFSET - 2.0)
	player.velocity = Vector2.ZERO
	await frames(40)
	check(player.is_on_floor(), "Real player must stand on the first deck module")
	check(absf(player.position.y + FOOT_OFFSET) < 3.0, "Real player's feet must align with the deck walking plane")
	Input.action_press("move_right")
	var crossed := false
	var seam_floor_continuous := true
	for i in 120:
		await physics_frame
		if player.position.x >= 120 and player.position.x <= 200:
			seam_floor_continuous = seam_floor_continuous and player.is_on_floor() and absf(player.position.y + FOOT_OFFSET) < 3.0
		if player.position.x >= 248:
			crossed = true
			break
	Input.action_release("move_right")
	await frames(8)
	check(crossed and player.position.x < 300, "Real player must cross the join onto the second deck module")
	check(seam_floor_continuous, "Player must stay grounded at the same height throughout the module join")
	check(player.is_on_floor(), "Crossing the module join must preserve grounded movement")
	check(absf(player.position.y + FOOT_OFFSET) < 3.0, "Player must remain on the same height across adjacent modules")
	print("DECK SEAM CHECK feet=", player.position + Vector2(0, FOOT_OFFSET), " on_floor=", player.is_on_floor())
	if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		await frames(12)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(not image.is_empty(), "Deck seam preview must contain a rendered frame")
		if not image.is_empty():
			check(image.save_png(capture_dir.path_join("playtest-reusable-deck.png")) == OK, "Deck seam preview must save")
	await finish()

func finish() -> void:
	Input.action_release("move_right")
	Input.action_release("move_left")
	print("BLUE DECK MODULE PLAYTEST: ", "PASS" if failures.is_empty() else "FAIL", " | ", failures)
	current_scene = null
	if is_instance_valid(stage):
		stage.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
