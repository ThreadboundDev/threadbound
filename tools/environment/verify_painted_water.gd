extends SceneTree
## GPU regression for the opt-in reflective surface / underwater reveal.
const OUT := "res://work/overnight-playtest-2026-10-30"
var failures: Array[String] = []
var checks := 0
class Observer extends CharacterBody2D:
	func get_water_sample_position() -> Vector2: return global_position
	func is_in_prototype_water() -> bool: return false # Dry chamber also stays underwater visually.
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("PAINTED_WATER_FAIL "+message)
func rectangle(bounds: Rect2, color: Color, depth: int) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	node.color = color
	node.z_index = depth
	return node
func image_at(view: Viewport) -> Image:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Painted water requires GPU pixel checks")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(512,512)
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(rectangle(Rect2(0,0,512,512),Color(.02,.08,.12),-30))
	view.add_child(rectangle(Rect2(128,60,80,80),Color(1,.02,.7),-10))
	view.add_child(rectangle(Rect2(245,140,50,100),Color.WHITE,0))
	view.add_child(rectangle(Rect2(245,360,50,80),Color.WHITE,0))
	view.add_child(rectangle(Rect2(310,270,30,60),Color.WHITE,90))
	var pocket_color := Color(1,.55,.2)
	view.add_child(rectangle(Rect2(370,260,30,60),pocket_color,0))
	var contact_color := Color(.4,.3,.2)
	view.add_child(rectangle(Rect2(240,450,60,20),contact_color,3))
	var observer := Observer.new()
	observer.add_to_group("player")
	observer.position = Vector2(475,90)
	observer.velocity = Vector2(150,260)
	view.add_child(observer)
	var lake = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	lake.lake_presentation = true
	lake.painted_surface = true
	lake.points = PackedVector2Array([Vector2(0,160),Vector2(512,160),Vector2(512,512),Vector2(0,512)])
	view.add_child(lake)
	lake.set_process(false)
	var pocket = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	pocket.air_pocket = true
	pocket.lake_presentation = true
	pocket.pocket_caustic_intensity = 0.0
	pocket.points = PackedVector2Array([Vector2(350,240),Vector2(430,240),Vector2(430,340),Vector2(350,340)])
	view.add_child(pocket)
	var authored: PackedVector2Array = lake.points.duplicate()
	lake._update_water_preview(.5)
	var dry := await image_at(view)
	check(lake.underwater_view < .001,"Above-surface eye uses opaque presentation")
	check(lake._immersion_fill.z_index>90,"Front water covers high-z enemy sprites as well as the player and solid rocks")
	check(dry.get_pixel(270,150).r > .98,"Above-water character pixels remain dry")
	check(dry.get_pixel(270,200).r < .60,"Below-water character pixels are concealed by the reflective surface")
	check(dry.get_pixel(325,300).r < .60,"High-z enemy pixels cannot draw on top of opaque water")
	check(dry.get_pixel(380,290).r < .75,"Underwater dry chamber cannot punch an orange hole through the outside surface")
	observer.position.y = 300
	lake._update_water_preview(1.0/60.0)
	check(lake.underwater_view>.05 and lake.underwater_view<.30,"The first crossing frame blends instead of instantly switching")
	lake._update_water_preview(.5)
	var wet := await image_at(view)
	check(lake.underwater_view>.98,"Submerged eye opens the underwater view even in a physically dry chamber")
	check(wet.get_pixel(270,150).r>.98,"Dry character pixels stay unchanged while underwater view opens")
	check(wet.get_pixel(270,200).r>dry.get_pixel(270,200).r+.15,"Submerged actor becomes clearly visible after the reveal")
	check(wet.get_pixel(270,200).b-wet.get_pixel(270,200).r>.08,"Visible submerged actor has a readable cool grade")
	check(wet.get_pixel(325,300).r>dry.get_pixel(325,300).r+.15,"Enemy is revealed with the same transition")
	check(wet.get_pixel(270,400).b-wet.get_pixel(270,400).r>=wet.get_pixel(270,200).b-wet.get_pixel(270,200).r,"Submerged grade strengthens with spatial depth")
	var pocket_pixel := wet.get_pixel(380,290)
	check(absf(pocket_pixel.r-pocket_color.r)<.02 and absf(pocket_pixel.g-pocket_color.g)<.02,"Physical air pocket reveals its dry contents underwater")
	var rock := wet.get_pixel(270,460)
	check(rock.b-rock.r > contact_color.b-contact_color.r+.05,"Solid contact rock receives water grading instead of looking completely dry")
	check(lake.points==authored and lake.collision.polygon==authored,"Presentation never changes authored water collision")
	check(pocket.contains_global_point(Vector2(380,290)),"Air pocket dry-state geometry remains authoritative")
	check(observer.velocity==Vector2(150,260),"The visual transition does not stop or launch the observer")
	observer.position.y = 90
	lake._update_water_preview(1.0/60.0)
	check(lake.underwater_view>.70 and lake.underwater_view<.95,"Exit also blends rather than popping")
	lake._update_water_preview(.5)
	check(lake.underwater_view<.01,"Surface presentation returns after exit")
	dry.save_png(OUT+"/water_fixture_above.png")
	wet.save_png(OUT+"/water_fixture_below.png")
	var report := {"checks":checks,"failures":failures,"outside_actor":str(dry.get_pixel(270,200)),"underwater_actor":str(wet.get_pixel(270,200)),"underwater_contact_rock":str(rock)}
	FileAccess.open(OUT+"/painted-water-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PAINTED_WATER ",JSON.stringify(report))
	view.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
