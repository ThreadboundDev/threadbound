extends Node
const BASE := preload("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_bulb_choice_room.tscn")
const ART := preload("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_preview.tscn")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	var base := BASE.instantiate()
	base.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(base)
	var room := ART.instantiate()
	add_child(room)
	room.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().physics_frame
	for original in base.get_node("Geometry").get_children():
		var actual = room.get_node("Geometry").get_node(NodePath(str(original.name)))
		check(actual.position == original.position, "Art must preserve collision position: " + str(original.name))
		check(actual.size == original.size, "Art must preserve collider dimensions.")
		check(actual.get_node("CollisionShape2D").shape.size == original.get_node("CollisionShape2D").shape.size, "Art must preserve physics shapes.")
		check(actual.one_way == original.one_way, "Art must preserve one-way collision.")
	for original in base.get_node("Bulbs").get_children():
		var actual = room.get_node("Bulbs").get_node(NodePath(str(original.name)))
		check(actual.position == original.position and actual.size == original.size, "Bulb art must preserve target layout.")
		check(actual.regeneration_delay == original.regeneration_delay, "Bulb art must preserve timing.")
	base.queue_free()
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://Assets/BlueBiome/StillVillage/kit_manifest.json"))
	check(manifest.size() == 12, "All twelve kit pieces must be packaged.")
	for entry in manifest:
		var path: String = "res://Src/Environment/BlueBiome/ArtPlaceables/StillVillage/" + entry.id + ".tscn"
		var piece = load(path).instantiate()
		check(piece.get_node("Art").texture != null, "Placeable texture missing: " + entry.id)
		check(piece.get_child_count() == 1 and piece.get_child(0) is Sprite2D, "Art placeables must not introduce collision.")
		piece.free()
	check(room.get_node("TwoLayerParallax").get_child_count() == 4, "Expected two image layers plus sky and lower lake fills.")
	check(room.far_layer.texture != null and room.near_layer.texture != null, "Both parallax plates must load.")
	room.get_node("Player/Camera2D").enabled = false
	var camera := Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	room.add_child(camera)
	camera.make_current()
	camera.position = Vector2(2304,256)
	camera.force_update_scroll()
	await get_tree().physics_frame
	await get_tree().physics_frame
	room._update_parallax()
	var center_before := camera.get_screen_center_position()
	var far_before: Vector2 = room.far_layer.position
	var near_before: Vector2 = room.near_layer.position
	camera.position.x += 100
	camera.force_update_scroll()
	await get_tree().physics_frame
	await get_tree().physics_frame
	room._update_parallax()
	var camera_delta := camera.get_screen_center_position().x - center_before.x
	check(camera_delta > 0.0, "Parallax test camera must actually move.")
	check(is_equal_approx(room.far_layer.position.x - far_before.x, -camera_delta * 0.10), "Far parallax must follow at ten percent camera speed.")
	check(is_equal_approx(room.near_layer.position.x - near_before.x, -camera_delta * 0.26), "Near parallax must follow at twenty-six percent camera speed.")
	for x in [704.0,3904.0]:
		camera.position = Vector2(x,256)
		camera.force_update_scroll()
		await get_tree().process_frame
		room._update_parallax()
		var far_half: float = room.far_layer.texture.get_width() * room.far_layer.scale.x * 0.5
		var near_half: float = room.near_layer.region_rect.size.x * room.near_layer.scale.x * 0.5
		check(room.far_layer.position.x - far_half <= 0 and room.far_layer.position.x + far_half >= 1920, "Far plate must cover both room ends.")
		check(room.near_layer.position.x - near_half <= 0 and room.near_layer.position.x + near_half >= 1920, "Near plate must cover both room ends.")
	var bulb = room.get_node("Bulbs/DashChoice")
	var visual = room.get_node("StillVillageArt/DashChoiceArt")
	check(visual.animation == &"rush", "Ready bulb must show rushing loop.")
	check(visual.sprite_frames.get_frame_count(&"rush") == 24, "Rush must include complete loop.")
	check(bulb.activate_from_grapple(), "Existing grapple pop must still work.")
	check(visual.animation == &"pop", "Broken signal must start pop animation.")
	await get_tree().create_timer(1.4).timeout
	check(bulb.is_broken() and visual.animation == &"refill", "Refill must anticipate regeneration while bulb is still spent.")
	await get_tree().create_timer(1.2).timeout
	check(not bulb.is_broken() and visual.animation == &"rush", "Visual and gameplay availability must agree after regeneration.")
	print("STILL VILLAGE: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	get_tree().quit(0 if failures == 0 else 1)
