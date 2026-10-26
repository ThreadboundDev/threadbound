extends SceneTree
## Fixed-camera scenery must not fade with wet state; water covers wet actor pixels.
const OUT := "res://work/water-immersion-2026-10-26"
var failures: Array[String] = []
var checks := 0
var samples := {}
var baseline := false

class Observer extends CharacterBody2D:
	func is_in_prototype_water() -> bool:
		return global_position.y > 160.0

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("WATER_IMMERSION_FAIL "+message)

func rectangle(bounds: Rect2, color: Color, depth: int) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	node.color = color
	node.z_index = depth
	return node

func frames(count := 5) -> void:
	for i in count: await physics_frame

func image_at(view: Viewport) -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Water immersion pixel checks require a GPU")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	var view := SubViewport.new()
	view.size = Vector2i(512,512)
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(rectangle(Rect2(0,0,512,512),Color(.02,.08,.12),-30))
	view.add_child(rectangle(Rect2(128,60,80,80),Color(1,.02,.7),-10))
	view.add_child(rectangle(Rect2(245,140,50,100),Color.WHITE,0))
	view.add_child(rectangle(Rect2(245,360,50,80),Color.WHITE,0))
	var pocket_color := Color(1,.55,.2)
	view.add_child(rectangle(Rect2(370,260,30,60),pocket_color,0))
	var contact_color := Color(.4,.3,.2)
	view.add_child(rectangle(Rect2(240,450,60,20),contact_color,3))
	var observer := Observer.new()
	observer.add_to_group("player")
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(8,8)
	shape.shape = box
	observer.add_child(shape)
	observer.position = Vector2(475,90)
	view.add_child(observer)
	var lake = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	lake.lake_presentation = true
	lake.points = PackedVector2Array([Vector2(0,160),Vector2(512,160),Vector2(512,512),Vector2(0,512)])
	view.add_child(lake)
	var pocket = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	pocket.air_pocket = true
	pocket.lake_presentation = true
	pocket.pocket_caustic_intensity = 0.0
	pocket.points = PackedVector2Array([Vector2(350,240),Vector2(430,240),Vector2(430,340),Vector2(350,340)])
	view.add_child(pocket)
	await frames()
	lake._update_water_preview(.5)
	var dry := await image_at(view)
	var opacity_before: float = lake.get_presentation_opacity()
	observer.position.y = 300
	await frames()
	lake._update_water_preview(.5)
	var wet := await image_at(view)
	check(is_equal_approx(lake.get_presentation_opacity(),opacity_before),"Scenery opacity is independent of the player's wet state")
	var dry_reflection := dry.get_pixel(168,220)
	var wet_reflection := wet.get_pixel(168,220)
	check(absf(dry_reflection.r-wet_reflection.r)<.016,"Fixed-camera reflection does not reveal/fade on water entry")
	var above := wet.get_pixel(270,150)
	var below := wet.get_pixel(270,200)
	var deep := wet.get_pixel(270,400)
	check(above.r>.98 and above.g>.98 and above.b>.98,"Above-surface actor pixels remain dry")
	check(below.b-below.r>.08 and below.r<.87,"Submerged actor pixels receive a visible cool water veil")
	check(deep.b-deep.r>=below.b-below.r,"Water immersion increases with spatial depth")
	check(wet.get_pixel(380,290).is_equal_approx(dry.get_pixel(380,290)),"Dry pocket actor color does not change with observer state")
	var dry_actor := wet.get_pixel(380,290)
	check(absf(dry_actor.r-pocket_color.r)<.01 and absf(dry_actor.g-pocket_color.g)<.01 and absf(dry_actor.b-pocket_color.b)<.01,"Dry pockets exclude the foreground water veil")
	var rock := wet.get_pixel(270,460)
	check(absf(rock.r-contact_color.r)<.01 and absf(rock.g-contact_color.g)<.01 and absf(rock.b-contact_color.b)<.01,"Solid foreground rock remains above the water veil")
	check(lake._fill.z_index<0 and lake._immersion_fill.z_index==2,"Reflections stay behind actors; immersion stays ahead of them")
	check(lake._ripple_visual.z_index==2,"Water movement cues can overlap the swimmer, below rock contact")
	samples = {"body_opacity_dry":opacity_before,"body_opacity_wet":lake.get_presentation_opacity(),"reflection_red_dry":dry_reflection.r,"reflection_red_wet":wet_reflection.r,"shallow_actor":str(below),"deep_actor":str(deep)}
	wet.save_png(OUT.path_join("before_fixture.png" if baseline else "after_fixture.png"))
	view.queue_free()
	await frames(2)
	await capture_player()
	var report := {"baseline":baseline,"checks":checks,"failures":failures,"samples":samples,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("before.json" if baseline else "verification.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("WATER_IMMERSION ",JSON.stringify(report))
	quit(1 if failures.size() else 0)

func capture_player() -> void:
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(20)
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for ui: CanvasLayer in room.find_children("*","CanvasLayer",true,false): ui.visible = false
	var player: CharacterBody2D = room.get_node("Player")
	player.set_physics_process(false)
	player.get_node("Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	var camera := Camera2D.new()
	camera.zoom = Vector2.ONE*1.25
	camera.position = Vector2(2816,600)
	room.add_child(camera)
	camera.make_current()
	var visual = player.get_node("Live3DVisual")
	for label: String in ["surface","submerged"]:
		player.global_position = Vector2(2816,420 if label=="surface" else 660)
		player.velocity = Vector2(180,0)
		player.reset_physics_interpolation()
		visual.play_gameplay_animation(&"Swim")
		await frames(20)
		visual._animation_player.pause()
		var image := await image_at(root)
		image.save_png(OUT.path_join(("before_" if baseline else "after_")+label+".png"))
	room.queue_free()
	await frames(2)
