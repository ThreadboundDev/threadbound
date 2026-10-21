extends SceneTree
## Actual player scene: capsule stance, headroom, hand-height grabs, and rendered
## hand registration. Run headlessly, or with a renderer to save contact views.
const PLAYER := "res://Src/Characters/Player/player.tscn"
var failures: Array[String] = []
var checks := 0
var rig: Node2D
var results := {}

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func body(rect: Rect2, one_way := false) -> StaticBody2D:
	var object := StaticBody2D.new()
	object.position = rect.get_center()
	object.collision_layer = 1
	object.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	collider.one_way_collision = one_way
	object.add_child(collider)
	var art := Polygon2D.new()
	var half := rect.size*0.5
	art.polygon = PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
	art.color = Color(0.28,0.37,0.43)
	object.add_child(art)
	rig.add_child(object)
	return object

func fixture() -> void:
	if rig:
		rig.queue_free()
		await frames(2)
	rig = Node2D.new()
	root.add_child(rig)
	var camera := Camera2D.new()
	camera.position = Vector2(0,35)
	camera.zoom = Vector2(3,3)
	rig.add_child(camera)
	camera.make_current()

func player(with_visual := false):
	var actor = load(PLAYER).instantiate()
	actor.get_node("Live3DVisual").enabled = with_visual
	rig.add_child(actor)
	actor.set_physics_process(false)
	actor.velocity = Vector2(0,80)
	return actor

func verify() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","Jump","Block"]:
		Input.action_release(action)
	await verify_stance()
	await verify_one_way()
	await verify_grabs()
	await verify_wall_contacts()
	await verify_visual_grip(1)
	await verify_visual_grip(-1)
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"results":results,"display":DisplayServer.get_name()}
	FileAccess.open("res://work/capsule-ledges/verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CAPSULE_LEDGE_VERIFICATION ",JSON.stringify(report))
	rig.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)

func verify_stance() -> void:
	await fixture()
	var p = player()
	var second = player()
	second.position.x = 500
	var collider: CollisionShape2D = p.get_node("CollisionShape2D")
	var capsule := collider.shape as CapsuleShape2D
	check(capsule != null,"Movement collider must be a capsule")
	check(is_equal_approx(capsule.radius,18.5) and is_equal_approx(capsule.height,126.244995),"Standing width and height must match the existing body")
	var feet: float = p._get_player_collision_bottom_offset()
	p._apply_crouch_collision(true)
	check(is_equal_approx(capsule.height,126.244995*0.62),"Crouch must shorten the capsule to the existing ratio")
	check(is_equal_approx(capsule.radius,18.5) and collider.scale == Vector2.ONE,"Crouch must preserve the rounded footprint without scaling the node")
	check(is_equal_approx(p._get_player_collision_bottom_offset(),feet),"Crouching must keep the feet planted")
	check(is_equal_approx((second.get_node("CollisionShape2D").shape as CapsuleShape2D).height,126.244995),"Crouching one player must not resize another instance")
	check(p.get_node("Hurtbox/CollisionShape2D").shape is RectangleShape2D,"Existing damage hurtbox must remain separate")
	var ceiling := body(Rect2(-60,-45,120,25))
	await frames(2)
	check(not p._can_restore_standing_collision(),"Low ceiling must prevent standing up")
	ceiling.queue_free()
	await frames(2)
	check(p._can_restore_standing_collision(),"Player must be able to stand after clearing the ceiling")
	# At the capsule's rounded upper corner, a box query would falsely block.
	var corner := body(Rect2(17,-57,20,4))
	await frames(2)
	check(p._can_restore_standing_collision(),"Standing clearance must query the actual capsule rather than its bounding rectangle")
	corner.queue_free()
	p._apply_crouch_collision(false)
	check(is_equal_approx(capsule.height,126.244995) and is_equal_approx(p._get_player_collision_bottom_offset(),feet),"Standing must restore original size and foot position")
	results["stance"] = {"width":capsule.radius*2,"standing_height":capsule.height,"crouched_height":capsule.height*p.crouch_height_ratio,"feet":feet}

func verify_one_way() -> void:
	await fixture()
	var platform := body(Rect2(-120,0,240,12),true)
	var p = player()
	p.position = Vector2(0,140)
	p.velocity = Vector2(0,-1100)
	await frames(2)
	var rose_above := false
	for i in 100:
		await physics_frame
		p.velocity.y += p.gravity/60.0
		p.move_and_slide()
		rose_above = rose_above or p._get_player_collision_bottom_offset()+p.position.y < -2
	check(rose_above,"Capsule must pass upward through a one-way platform")
	check(p.is_on_floor() and absf(p.position.y+p._get_player_collision_bottom_offset())<1,"Capsule must land on the platform from above")
	p._begin_one_way_drop()
	for i in 18:
		await physics_frame
		p.velocity.y += p.gravity/60.0
		p.move_and_slide()
		p._process_one_way_drop_input(1.0/60.0)
	check(p.position.y+p._get_player_collision_bottom_offset()>16,"Drop-through must still release the capsule")
	check(p.get_collision_mask_value(1),"Drop-through must restore the terrain collision mask")

func verify_grabs() -> void:
	var cases := {"hand":-84.0,"hand_lower_tolerance":-75.0,"hand_upper_tolerance":-95.0,"too_low":-68.0,"too_high":-101.0,"torso":-12.0,"knee":35.0,"feet":65.0,"full_wall":-300.0}
	var accepted := {}
	for direction in [1,-1]:
		for label: String in cases:
			await fixture()
			body(Rect2(24 if direction>0 else -184,cases[label],160,500))
			var p = player()
			p.last_direction = direction
			await frames(2)
			var grab: bool = p._try_grab_ledge()
			accepted[label+str(direction)] = grab
			check(grab == label.begins_with("hand"),"Only a reachable hand-height lip may grab: "+label+str(direction))
			if label == "hand" and grab:
				p._start_ledge_climb(false)
				p._process_ledge_climb(p.ledge_climb_duration)
				check(p.position.y+p._get_player_collision_bottom_offset()<float(cases[label]),"Pull-over must clear the platform with the full capsule")
				p.is_ledge_hanging = true
				p._start_ledge_climb(true)
				p._process_ledge_climb(p.ledge_climb_duration)
				check(not p.is_ledge_hanging and p.velocity.y<0,"Ledge jump must release with upward velocity")
	# Grapple assistance extends horizontal reach, never knee/foot-height reach.
	for top in [-84.0,35.0]:
		await fixture()
		body(Rect2(50,top,160,500))
		var p = player()
		p.request_grapple_ledge_assist(Vector2(60,top))
		await frames(2)
		check(p._try_grab_ledge() == (top<0),"Grapple assistance must retain the hand-height requirement")
	results["ledge_candidates"] = accepted

func verify_wall_contacts() -> void:
	for tall_wall in [false,true]:
		await fixture()
		body(Rect2(24,-300 if tall_wall else 20,160,800))
		var p = player()
		p.position.x = 5.4
		Input.action_press("move_right")
		await frames(2)
		p.velocity = Vector2(100,80)
		p.move_and_slide()
		check(p.is_on_wall_only(),"Fixture must produce a real wall contact")
		p.handle_wall_cling(1.0/60.0)
		check(p.is_wall_clinging == tall_wall,"Wall cling requires wall at hand height, not a leg-only collision")
		Input.action_release("move_right")

func verify_visual_grip(direction: int) -> void:
	await fixture()
	body(Rect2(24 if direction>0 else -184,-84,160,500))
	var p = player(true)
	p.last_direction = direction
	await frames(3)
	var display = p.live_3d_visual._display
	check(is_equal_approx(display.position.y,69.244997),"3D visuals must retain their foot registration with the capsule")
	# Approach while falling with the real controller, rather than invoking
	# only the grab predicate at a preselected position.
	p.position = Vector2(0,-160)
	p.velocity = Vector2(0,500)
	var action := "move_right" if direction>0 else "move_left"
	Input.action_press(action)
	p.set_physics_process(true)
	for i in 80:
		await physics_frame
		if p.is_ledge_hanging:
			break
	Input.action_release(action)
	check(p.is_ledge_hanging,"Actual falling 3D player must catch the lip when its hands reach it")
	await frames(60)
	var hand: Vector2 = p.live_3d_visual.get_ledge_grip_player_offset(direction)
	var error: float = (p.position+hand).distance_to(p._ledge_top)
	check(p.is_ledge_hanging and error<2.0,"Rendered hanging hand must touch the actual lip in both directions")
	results["3d_grip_"+str(direction)] = {"error_pixels":error,"hand_offset":str(hand),"root_position":str(p.position)}
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/capsule-ledges/ledge_contact_"+str(direction)+".png")
