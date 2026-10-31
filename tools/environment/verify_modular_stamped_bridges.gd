extends SceneTree
const OUT := "res://work/overnight-playtest-2026-10-30"
const PARTS := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	current_scene = stage
	for entry in [["bridge_deck_2d.tscn",0],["bridge_railing_2d.tscn",1],["bridge_pontoons_2d.tscn",2],["bridge_braces_2d.tscn",3]]:
		var piece = load(PARTS+entry[0]).instantiate()
		stage.add_child(piece)
		check(piece.part == entry[1],"Standalone part loads: "+entry[0])
		check(piece.find_children("*","CollisionObject2D",true,false).is_empty(),"Standalone art does not add collision: "+entry[0])
		if piece.part == 1:
			check(piece.material is ShaderMaterial,"Painted rail uses its deck-removal mask")
			check(piece.PROFILES[1].texture.resource_path.ends_with("J03_Japanese_Veranda.png"),"Rail samples the exact approved painted stamp")
		piece.queue_free()
	for file in ["pontoon_bridge_2d.tscn","braced_landing_2d.tscn"]:
		var bridge = load(PARTS+file).instantiate()
		stage.add_child(bridge)
		bridge.span_width = 640
		bridge.rock_inset_left = 96
		bridge.rock_inset_right = 32
		bridge._sync_parts()
		check(bridge.get_node("WalkPlane").position == Vector2.ZERO,"Assembly retains walk anchor: "+file)
		for label in ["Deck","RearRail","FrontRail","PontoonFloats","SupportBraces"]:
			var piece = bridge.get_node(label)
			check(piece.span_width == 640 and piece.rock_inset_left == 96 and piece.rock_inset_right == 32,"Width/stone trim reaches independent part: "+label)
		check(bridge.get_node("RearRail").z_index < 0 and bridge.get_node("FrontRail").z_index > 0,"Painted rails occupy rear/foreground layers")
		check(bridge.get_node("PontoonFloats").visible == (bridge.structure == 0),"Only floating assembly shows floats")
		check(bridge.get_node("SupportBraces").visible == (bridge.structure == 1),"Only elevated assembly shows braces")
		bridge.front_rail_visible = false
		bridge._sync_parts()
		check(not bridge.get_node("FrontRail").visible and bridge.get_node("RearRail").visible,"Near rail can be independently disabled")
		check(bridge.find_children("*","CollisionObject2D",true,false).is_empty(),"Assembly remains art only")
		bridge.queue_free()
	var report := {"checks":checks,"failures":failures}
	FileAccess.open(OUT+"/modular-bridges-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("MODULAR_STAMP_BRIDGES ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
