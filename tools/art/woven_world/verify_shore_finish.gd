extends SceneTree
## Run with Godot --script tools/art/woven_world/verify_shore_finish.gd.

const SHORE := "res://Src/Tests/Art/WovenWorld/woven_chunk_level.tscn"
const LANDINGS := "res://Src/Tests/Art/WovenWorld/woven_landing_"
const DELIVERY := "res://ArtSource/Deliveries/WovenWorldChunks/shore_finish/"

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if change_scene_to_file(SHORE) != OK:
		quit(1)
		return
	await scene_changed
	await _frames(16)
	var shore := current_scene
	var player := shore.get_node("Player")
	var visuals: Node = player.live_3d_visual.equipment_visuals
	_check(visuals.equipped[&"head_chest"].model_paths[0].ends_with("OutfitATrial/base_outfit_a.glb"), "Default actor wears the latest Outfit A export.")
	_check(visuals.equipped[&"gloves"].model_paths[0].ends_with("OutfitATrial/base_grapple_glove.glb"), "Fitted grapple glove is equipped by default.")
	var finish := shore.get_node("ShoreFinish")
	_check(finish.has_node("Encounters/ShorePatrol") and finish.has_node("Encounters/TerraceHeron"), "Normal level starts with both Blue Biome encounters.")
	await _visit(finish.get_node("Encounters/ShorePatrol").global_position + Vector2(-460, -70), "shore_patrol.png")
	await _visit(Vector2(4240, 331), "upper_heron.png")
	await _at("ShoreFinish/UpperGate", "upper_gate_locked.png")
	await _interact()
	_check(current_scene == shore and finish.get_node("UpperGate/Latch").visible, "Upper gate is visibly locked before the sluices are opened.")
	await _at("ShoreFinish/WestSluice")
	await _interact()
	await _interact()
	_check(finish.get_node("UpperGate").sluices_open == 1, "Repeating the west sluice counts only once.")
	await _at("ShoreFinish/UpperGate")
	await _interact()
	_check(current_scene == shore, "One sluice leaves the upper route locked.")
	await _check_round_trip("VillageRoad", "rooftops", "rooftop_exit.png")
	await _check_round_trip("FloodedCulvert", "cistern", "water_exit.png")
	if current_scene.scene_file_path == SHORE:
		_check(current_scene.get_node("ShoreFinish/UpperGate").sluices_open == 1, "A trip through either open route preserves the sluice state.")
		await _at("ShoreFinish/EastSluice")
		await _interact()
		_check(not current_scene.get_node("ShoreFinish/UpperGate/Latch").visible, "The second sluice opens the gate.")
		await _check_round_trip("UpperGate", "lookout", "upper_gate_open.png")
	var result := {"checks": checks, "failures": failures, "rendered": DisplayServer.get_name() != "headless"}
	var mode := "headless" if DisplayServer.get_name() == "headless" else "gpu"
	var report := FileAccess.open(DELIVERY + "routes_%s.json" % mode, FileAccess.WRITE)
	report.store_string(JSON.stringify(result, "  ") + "\n")
	print("WOVEN_SHORE_ROUTES ", JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)


func _check_round_trip(anchor: String, destination: String, approach_capture: String) -> void:
	if current_scene.scene_file_path != SHORE:
		return
	await _at("ShoreFinish/" + anchor, approach_capture)
	await _interact()
	var expected := LANDINGS + destination + ".tscn"
	_check(current_scene.scene_file_path == expected, "Interacting with %s reaches its playable landing." % anchor)
	if current_scene.scene_file_path != expected:
		return
	var landing := current_scene.get_node("Player")
	_check(landing.get("live_3d_visual").equipment_visuals.equipped[&"head_chest"].model_paths[0].ends_with("base_outfit_a.glb"), "Outfit A carries into " + destination)
	await _capture("landing_%s.png" % destination)
	await _at("BackToShore")
	await _interact()
	_check(current_scene.scene_file_path == SHORE, "The %s landing returns to the shore." % destination)
	if current_scene.scene_file_path == SHORE:
		var portal := current_scene.get_node("ShoreFinish/" + anchor) as Node2D
		var actor := current_scene.get_node("Player") as Node2D
		_check(actor.global_position.distance_to(portal.global_position) < 160.0, "Return arrives at the same exit.")


func _at(path: NodePath, filename := "") -> void:
	var target := current_scene.get_node(path) as Node2D
	await _visit(target.global_position, filename)


func _visit(position: Vector2, filename := "") -> void:
	var actor := current_scene.get_node("Player") as CharacterBody2D
	actor.global_position = position
	actor.velocity = Vector2.ZERO
	actor.reset_physics_interpolation()
	await _frames(9)
	if not filename.is_empty():
		await _capture(filename)


func _interact() -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	root.push_input(event)
	await _frames(2)
	event.pressed = false
	root.push_input(event)
	await _frames(12)


func _frames(count: int) -> void:
	for index in count:
		await physics_frame


func _capture(filename: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(DELIVERY + filename) == OK, "Captured " + filename)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)
