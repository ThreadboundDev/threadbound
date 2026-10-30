extends SceneTree
## Real, unchanged production attacks in a review-only stage.
const OUT := "res://tmp/scale-vfx-study/vfx"
const EFFECT := preload("res://work/scale-vfx-study-2026-10-30/thread_sweep.gd")
var player
var effect: Node2D

func _initialize() -> void: call_deferred("run")
func settle(n := 1) -> void:
	for i in n: await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2(-3000,-2000),Vector2(3000,-2000),Vector2(3000,2000),Vector2(-3000,2000)])
	background.color = Color("203139")
	background.z_index = -100
	stage.add_child(background)
	var floor_body := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(6000,60)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	floor_body.position.y = 100
	floor_body.add_child(collision)
	stage.add_child(floor_body)
	var floor_art := Polygon2D.new()
	floor_art.polygon = PackedVector2Array([Vector2(-3000,70),Vector2(3000,70),Vector2(3000,130),Vector2(-3000,130)])
	floor_art.color = Color("40545a")
	stage.add_child(floor_art)
	player = load("res://Src/Characters/Player/player.tscn").instantiate()
	stage.add_child(player)
	var camera := Camera2D.new()
	camera.position = Vector2(100,-40)
	var game_scale := "--game-scale" in OS.get_cmdline_user_args()
	camera.zoom = Vector2(0.83,0.83) if game_scale else Vector2(1.8,1.8)
	stage.add_child(camera)
	camera.make_current()
	effect = EFFECT.new()
	stage.add_child(effect)
	await settle(80)
	var candidate := "--candidate" in OS.get_cmdline_user_args()
	var facing := -1 if "--left" in OS.get_cmdline_user_args() else 1
	player.last_direction = facing
	Input.action_press("aim_left" if facing < 0 else "aim_right")
	var label := ("candidate" if candidate else "baseline") + ("_left" if facing < 0 else "_right")
	if game_scale: label += "_game_scale"
	var driver = load("res://work/scale-vfx-study-2026-10-30/vfx_review_driver.gd").new()
	driver.player = player
	driver.effect = effect
	driver.candidate = candidate
	driver.process_priority = 200
	stage.add_child(driver)
	player.start_attack(false)
	var index := 0
	var tail := 0
	while index < 300 and tail < 12:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"/%s_frame_%03d.png" % [label,index])
		if driver.finished: tail += 1
		index += 1
	FileAccess.open(OUT+"/"+label+".json",FileAccess.WRITE).store_string(JSON.stringify({"candidate":candidate,"frames":driver.frames,"trail_seconds":effect.trail_seconds,"reach_extension":effect.reach_extension,"camera_zoom":camera.zoom.x,"capture_note":"60 fps isolated review; public attack/queue API, illustrative contacts, unchanged production attack clips and combat."},"\t"))
	print("VFX_CAPTURE ",label," frames=",index," finished=",driver.finished)
	Input.action_release("aim_left")
	Input.action_release("aim_right")
	stage.queue_free()
	await process_frame
	quit()
