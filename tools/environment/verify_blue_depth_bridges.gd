extends SceneTree
const OUT := "res://work/blue-depth-bridges-2026-10-30"
var checks := 0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failures.append(text)
		push_error(text)
func screen(node: Node2D) -> Vector2:
	return node.get_global_transform_with_canvas()*Vector2(2000,1600)
func run() -> void:
	var room=load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	room.tree_entered.connect(func(): current_scene=room,CONNECT_ONE_SHOT)
	root.add_child(room)
	room.get_node("Player").set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	await frames(8)
	var artwork=room.get_node("Geometry/TerrainArtwork")
	var far: Parallax2D=artwork.get_node("underwater_background")
	var wood: Node2D=artwork.get_node("rear_supports")
	check(far.z_index<wood.z_index and wood.z_index<artwork.get_node("rear_cave").z_index,"Far rock is behind world-locked timber and collision rock art")
	check(wood is not Parallax2D,"Structural rear timber has no parallax")
	check(far.get_child_count()==25 and wood.get_child_count()==15,"Independent rock/timber section counts remain intact")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://Assets/BlueBiome/Art/LakesideMap/underwater_background_manifest.json"))
	for i in manifest.chunks.size():
		var sprite: Sprite2D=far.get_node("Rock_%02d"%i)
		var chunk: Dictionary=manifest.chunks[i]
		check(sprite.position.is_equal_approx(Vector2(chunk.position[0],chunk.position[1])) and sprite.use_parent_material,"Source coordinates and waterline material retained: "+str(i))
	check(is_equal_approx(far.material.get_shader_parameter("water_surface_y"),411.0),"Parallax art clips to the fixed waterline")
	var before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"/before.json"))
	var anchors: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"/anchors.json"))
	var floats := 0
	var braces := 0
	for deck in room.get_node("Geometry/BridgeLandings").get_children():
		var body=room.get_node("Geometry/BuildingCollision/BridgeLanding"+String(deck.name).trim_prefix("Deck"))
		var shape: CollisionPolygon2D=body.get_node("Outline")
		var expected: Array=before.collision[String(deck.name)]
		var identical: bool=shape.polygon.size()==expected.size()
		for i in shape.polygon.size():
			identical=identical and shape.to_global(shape.polygon[i]).distance_to(Vector2(expected[i][0],expected[i][1]))<0.001
		check(identical,"World collision unchanged: "+String(deck.name))
		var excluded: Array[RID]=[]
		for other in room.find_children("*","CollisionObject2D",true,false):
			if other!=body: excluded.append(other.get_rid())
		var origin: Vector2=deck.to_global(Vector2(deck.span_width*.5,-10))
		var ray=PhysicsRayQueryParameters2D.create(origin,origin+Vector2(0,40),1)
		ray.exclude=excluded
		var hit=room.get_world_2d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y-deck.global_position.y)<0.01,"Art WalkPlane matches the actual one-way floor: "+String(deck.name))
		check(deck.get_node("WalkPlane").position==Vector2.ZERO,"Reusable asset keeps its walking anchor: "+String(deck.name))
		if deck.structure==0:
			floats+=1
			check(is_equal_approx(deck.global_position.y+deck.waterline_offset,411.0),"Pontoon waterline matches the lake: "+String(deck.name))
		else:
			braces+=1
			var query=PhysicsPointQueryParameters2D.new()
			query.position=deck.to_global(deck.support_anchor)
			query.collision_mask=1
			var supported:=false
			for result in room.get_world_2d().direct_space_state.intersect_point(query):
				if String(room.get_path_to(result.collider))==String(anchors[String(deck.name)].collider): supported=true
			check(supported,"Brace terminates inside actual rock/tower collision: "+String(deck.name))
	check(floats==4 and braces==5,"Four floating and five braced placements are installed")
	for old in room.find_children("*","Camera2D",true,false): old.enabled=false
	var camera=Camera2D.new()
	camera.zoom=Vector2(0.83,0.83)
	room.add_child(camera)
	camera.make_current()
	var points := []
	for p in [Vector2(2048,1600),Vector2(2448,1600),Vector2(2448,1800)]:
		camera.position=p
		camera.force_update_scroll()
		await frames(4)
		points.append({"rock":screen(far),"wood":screen(wood)})
		if points.size()==1:
			check(far.global_position.length()<0.01,"Authored rock coordinates agree at the camera-center anchor")
	var rock_dx: float=points[1].rock.x-points[0].rock.x
	var wood_dx: float=points[1].wood.x-points[0].wood.x
	var rock_dy: float=points[2].rock.y-points[1].rock.y
	var wood_dy: float=points[2].wood.y-points[1].wood.y
	check(absf(rock_dx/wood_dx-0.65)<0.001,"Horizontal rock scrolling is 65 percent of the world")
	check(absf(rock_dy/wood_dy-0.85)<0.001,"Vertical rock scrolling is 85 percent of the world")
	check(absf(wood_dx+400.0*0.83)<0.01 and absf(wood_dy+200.0*0.83)<0.01,"Timber remains aligned with normal collision scrolling")
	var report={"checks":checks,"failures":failures,"horizontal_ratio":rock_dx/wood_dx,"vertical_ratio":rock_dy/wood_dy,"floats":floats,"braces":braces}
	FileAccess.open(OUT+"/validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BLUE_DEPTH_BRIDGES ",JSON.stringify(report))
	room.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
