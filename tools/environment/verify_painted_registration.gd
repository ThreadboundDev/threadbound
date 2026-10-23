extends SceneTree
## Exercise camera motion between physics ticks; static screenshots miss drift.
const ROOM := "res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn"
var room: Node2D
var camera: Camera2D
var phase := 0.0
var failures: Array[String] = []
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("verify")

func _physics_process(delta: float) -> bool:
	if is_instance_valid(camera):
		phase += delta
		camera.position = Vector2(0,-100)+Vector2(sin(phase*2.7)*160,cos(phase*3.1)*120)
	return false

func marker(parent: Node, color: Color, offset: Vector2) -> void:
	var square := Polygon2D.new()
	square.polygon = PackedVector2Array([Vector2(-6,-6),Vector2(6,-6),Vector2(6,6),Vector2(-6,6)])
	square.position = Vector2(0,-100)+offset
	square.color = color
	square.z_index = 100
	square.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	square.material = material
	parent.add_child(square)

func center_of(image: Image, expected: Vector2, magenta: bool) -> Vector2:
	var total := Vector2.ZERO
	var count := 0
	for y in range(maxi(0,int(expected.y)-45),mini(image.get_height(),int(expected.y)+45)):
		for x in range(maxi(0,int(expected.x)-45),mini(image.get_width(),int(expected.x)+45)):
			var c := image.get_pixel(x,y)
			if (c.r>.9 and c.g<.1 and c.b>.9) if magenta else (c.r<.1 and c.g>.9 and c.b>.9):
				total += Vector2(x+.5,y+.5)
				count += 1
	return total/maxi(count,1) if count>0 else Vector2.INF

func verify() -> void:
	room = load(ROOM).instantiate()
	root.add_child(room)
	current_scene = room
	for n in 20:
		await physics_frame
	var art = room.get_node("ArtComparison")
	room.get_node("Player").set_physics_process(false)
	room.get_node("Player/Camera2D").enabled = false
	room.get_node("OverviewCamera").enabled = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for ui: CanvasLayer in root.find_children("*","CanvasLayer",true,false):
		ui.visible = false
	camera = Camera2D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position_smoothing_enabled = true
	room.add_child(camera)
	camera.make_current()
	marker(room,Color.CYAN,Vector2(40,0))
	marker(art.stage.far_view,Color.MAGENTA,Vector2.ZERO)
	for rate in [30,90,144]:
		Engine.max_fps = rate
		for n in 20:
			await process_frame
		var maximum := 0.0
		for n in 45:
			await RenderingServer.frame_post_draw
			var canvas := root.get_canvas_transform()
			var picture := root.get_texture().get_image()
			var painted := center_of(picture,canvas*Vector2(0,-100),true)
			var direct := center_of(picture,canvas*Vector2(40,-100),false)
			var error := (painted-direct+canvas.basis_xform(Vector2(40,0))).length()
			maximum = maxf(maximum,error)
		results.append({"fps_cap":rate,"samples":45,"max_drift_px":maximum})
		if maximum>1.5:
			failures.append("Painted/direct camera drift at "+str(rate)+" FPS: "+str(maximum))
	var report := {"passed":failures.is_empty(),"motion":results,"failures":failures}
	DirAccess.make_dir_recursive_absolute("res://tmp/painted_registration")
	FileAccess.open("res://tmp/painted_registration/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("PAINTED_REGISTRATION_CHECK ",JSON.stringify(report))
	room.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
