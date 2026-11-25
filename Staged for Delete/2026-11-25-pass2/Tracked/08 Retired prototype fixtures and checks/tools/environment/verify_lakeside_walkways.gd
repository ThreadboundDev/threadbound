extends "res://tools/environment/verify_lakeside_krita.gd"
## Real capsule landings plus fixed-end art fitting; no GPU visual acceptance.
const PREFABS := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/"
const LAYOUT := [Vector3(4608, -1664, 640), Vector3(3052, -1134, 384), Vector3(4864, -768, 128), Vector3(-640, -128, 256), Vector3(244, 397, 384), Vector3(2048, -128, 384), Vector3(-896, 384, 256), Vector3(3200, 384, 512), Vector3(4096, 384, 768)]
const BODY_POSITIONS := [Vector2(4928, -1659), Vector2(3136, -1019), Vector2(4928, -763), Vector2(-512, -123), Vector2(704, -123), Vector2(2240, -123), Vector2(-768, 389), Vector2(3456, 389), Vector2(4480, 389)]
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("WALKWAY_FAIL " + message)

func verify() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Assets/BlueBiome/Art/WalkwayStamps/provenance.json"))
	check(manifest.assets.size() == 4, "Exactly four approved timber textures")
	for asset: Dictionary in manifest.assets:
		check(FileAccess.get_sha256("res://Assets/BlueBiome/Art/WalkwayStamps/" + asset.file) == asset.sha256, "Runtime PNG matches original bytes: " + asset.file)
	for prefab: String in ["plank_crossing_2d", "railed_veranda_2d", "engawa_balcony_2d", "broken_timber_bridge_2d"]:
		var art: Node2D = load(PREFABS + prefab + ".tscn").instantiate()
		check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), prefab + ": no duplicate colliders")
		check(art.get_node("WalkPlane").position == Vector2.ZERO and art.z_index == -6 and not art.z_as_relative, prefab + ": left walk anchor and rock-nestable default depth")
		for width: float in [32.0, 128.0, 256.0, 384.0, 512.0, 640.0, 768.0, 4096.0]:
			art.span_width = width
			var sections: Array[Dictionary] = art.get_draw_sections()
			var end := 0.0
			for section: Dictionary in sections:
				var src: Rect2 = section.source
				var dst: Rect2 = section.target
				check(is_equal_approx(dst.position.x, end), prefab + ": adjacent texture slices at " + str(width))
				check(absf(dst.size.x / src.size.x - dst.size.y / src.size.y) < 0.0001, prefab + ": uniformly scaled source detail")
				check(Rect2(Vector2.ZERO, art.source_texture().get_size()).encloses(src), prefab + ": source slice in original bounds")
				var profile: Dictionary = art.PROFILES[art.stamp]
				check(absf(dst.position.y + profile.walk_y * dst.size.y / src.size.y) < 0.001, prefab + ": texture walk plane at origin")
				end = dst.end.x
			check(absf(end - width) < 0.001, prefab + ": requested span is exact")
			if art.stamp == art.Stamp.BROKEN_TIMBER:
				check(sections.size() == 1, "Broken pair keeps original transparent gap without tiling")
		art.free()
	room = load(ROOM).instantiate()
	root.add_child(room)
	current_scene = room
	for enemy in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await frames(30)
	var player := room.get_node("Player") as CharacterBody2D
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var foot_offset := shape.to_global(Vector2(0, shape.shape.get_rect().end.y)).y - player.global_position.y
	var original_exceptions := player.get_collision_exceptions()
	var mask := player.collision_mask
	var rows: Array[Dictionary] = []
	for i in LAYOUT.size():
		var label := "%02d" % (i + 1)
		var expected: Vector3 = LAYOUT[i]
		var deck: Node2D = room.get_node("Geometry/BridgeLandings/Deck" + label)
		var body := room.get_node("Geometry/BuildingCollision/BridgeLanding" + label) as StaticBody2D
		var outline := body.get_node("Outline") as CollisionPolygon2D
		var bounds := Rect2(outline.to_global(outline.polygon[0]), Vector2.ZERO)
		for point: Vector2 in outline.polygon:
			bounds = bounds.expand(outline.to_global(point))
		check(bounds.position.is_equal_approx(Vector2(expected.x, expected.y)) and bounds.size.is_equal_approx(Vector2(expected.z, 10)), label + ": authored landing bounds unchanged")
		var half := expected.z * 0.5
		var vertices := PackedVector2Array([Vector2(-half, -5), Vector2(half, -5), Vector2(half, 5), Vector2(-half, 5)])
		if i == 1:
			vertices.insert(3, Vector2(101.2887, 5))
		var offset := Vector2(108, -110) if i == 1 else (Vector2(-268, 525) if i == 4 else Vector2.ZERO)
		check(outline.polygon == vertices and outline.position == offset and body.position == BODY_POSITIONS[i], label + ": original vertices and independent shape/body transforms retained")
		check(outline.one_way_collision and outline.one_way_collision_margin == 12 and body.collision_layer == 1 and body.collision_mask == 0, label + ": one-way physics unchanged")
		check(deck.global_position.is_equal_approx(bounds.position) and deck.span_width == bounds.size.x and deck.scale == Vector2.ONE, label + ": visual walk plane fits existing collision")
		check(deck.stamp != deck.Stamp.BROKEN_TIMBER, label + ": no new broken route")
		check(effective_z(deck) > effective_z(room.get_node("Geometry/TerrainArtwork/rear_supports")) and effective_z(deck) < effective_z(room.get_node("Geometry/TerrainArtwork/rear_cave")) and effective_z(deck) < effective_z(player), label + ": bridge ends tuck behind rock but ahead of background supports")
		# Isolate each real authored platform from overlapping terrain for this
		# fixture. Preserve real player gravity, capsule, input and one-way solver.
		for other: PhysicsBody2D in room.find_children("*", "PhysicsBody2D", true, false):
			if other != player:
				if other == body:
					player.remove_collision_exception_with(other)
				else:
					player.add_collision_exception_with(other)
		player.global_position = Vector2(bounds.get_center().x, bounds.position.y - foot_offset - 80)
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
		await frames(55)
		var error := absf(player.global_position.y + foot_offset - bounds.position.y)
		var landed_on_target := false
		for hit in player.get_slide_collision_count():
			landed_on_target = landed_on_target or player.get_slide_collision(hit).get_collider() == body
		check(player.is_on_floor() and landed_on_target and error < 0.1, label + ": real capsule lands at visible walk plane")
		var start_x := player.global_position.x
		Input.action_press("move_right")
		await frames(5)
		Input.action_release("move_right")
		check(player.global_position.x > start_x + 1 and player.is_on_floor(), label + ": real input walks along landing")
		rows.append({"deck": label, "feet_error_pixels": error, "walked_pixels": player.global_position.x - start_x})
	for body: PhysicsBody2D in player.get_collision_exceptions():
		if body not in original_exceptions:
			player.remove_collision_exception_with(body)
	for body: PhysicsBody2D in original_exceptions:
		player.add_collision_exception_with(body)
	check(player.collision_mask == mask, "Fixture never changes player collision mask")
	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "landings": rows, "visual_review": "Pending: seams, source deck perspective, house match, daylight/dusk"}
	DirAccess.make_dir_recursive_absolute("res://tmp/walkways")
	var file := FileAccess.open("res://tmp/walkways/verification.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WALKWAY_CHECK " + JSON.stringify(report))
	room.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
