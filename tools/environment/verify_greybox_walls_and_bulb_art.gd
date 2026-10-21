extends Node2D
## Integration checks using real swordfish movement, terrain physics and bulb art.
const FISH = preload("res://Src/Enemies/TideDuelist/tide_duelist.tscn")
const WATER = preload("res://Src/Environment/Greybox/greybox_polygon_water.tscn")
const WALL = preload("res://Src/Environment/Greybox/greybox_breakable_wall.tscn")
const BLOCK = preload("res://Src/Environment/Greybox/greybox_block.tscn")
const BULB = preload("res://Src/Environment/Greybox/greybox_bumper.tscn")
var run_automatically := true
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	if run_automatically:
		call_deferred("_run_and_quit")

func _run_and_quit() -> void:
	var result: Dictionary = await run()
	print("GREYBOX_WALLS_AND_BULB_ART: ", result)
	get_tree().quit(0 if result.failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame

func run() -> Dictionary:
	position = Vector2(20000, 20000)
	var water = WATER.instantiate()
	water.points = PackedVector2Array([Vector2.ZERO, Vector2(2400, 0), Vector2(2400, 1800), Vector2(0, 1800)])
	add_child(water)
	var player := Node2D.new()
	player.position = Vector2(850, 600)
	player.add_to_group("player")
	add_child(player)
	var fish = FISH.instantiate()
	fish.position = Vector2(600, 600)
	add_child(fish)
	fish.set_physics_process(false)
	fish.state_machine.set_physics_process(false)
	var first = WALL.instantiate()
	first.position = Vector2(1000, 600)
	first.size = Vector2(128, 512)
	add_child(first)
	var second = WALL.instantiate()
	second.position = Vector2(1300, 600)
	second.size = Vector2(128, 384)
	add_child(second)
	var solid = BLOCK.instantiate()
	solid.position = Vector2(1800, 600)
	solid.size = Vector2(128, 512)
	add_child(solid)
	await frames(3)
	check(first.get_node("CollisionShape2D").shape.size == Vector2(128, 512), "Wall resize updates collision")
	check(second.get_node("CollisionShape2D").shape.size == Vector2(128, 384), "Wall instances keep independent collision sizes")
	check(not first.fracture_from_swordfish(player), "Player cannot fracture wall")
	check(not fish._move_in_water(Vector2(700, 0)), "Ordinary movement stops at wall")
	check(not first.is_queued_for_deletion(), "Ordinary movement leaves wall intact")
	fish.position = Vector2(600, 600)
	fish.target = player
	fish.begin_attack()
	check(not first.fracture_from_swordfish(fish), "Windup cannot fracture wall")
	fish.activate_attack_hitbox()
	check(not first.fracture_from_swordfish(fish), "Blade unsheathing cannot fracture wall before damage is active")
	fish.update_attack_motion(1.5)
	check(first.is_queued_for_deletion() and second.is_queued_for_deletion(), "A dash fractures successive walls")
	check(fish.position.x > 1400 and fish.position.x < 1740, "Dash continues through openings and stops at solid terrain")
	check(fish.dash_blocked and fish.attack_phase == &"recover", "Solid terrain ends the dash in recovery")
	check(is_instance_valid(solid) and not solid.is_queued_for_deletion(), "Normal terrain survives swordfish dash")
	await frames(2)
	check(not is_instance_valid(first) and not is_instance_valid(second), "Fractured walls disappear from physics")

	# Dry pockets must prevent reaching a wall behind them.
	var pocket = WATER.instantiate()
	pocket.air_pocket = true
	pocket.points = PackedVector2Array([Vector2(950, 350), Vector2(956, 350), Vector2(956, 850), Vector2(950, 850)])
	add_child(pocket)
	var unreachable = WALL.instantiate()
	unreachable.position = Vector2(1200, 600)
	add_child(unreachable)
	fish.position = Vector2(600, 600)
	fish.dash_blocked = false
	fish.target = player
	fish.begin_attack()
	fish.activate_attack_hitbox()
	await frames(2)
	fish.update_attack_motion(1.0)
	check(not unreachable.is_queued_for_deletion(), "Dash cannot fracture a wall beyond a dry pocket")
	check(fish.position.x < 950, "Fish stays before the dry pocket")
	fish.end_attack()

	# A bulb under a low-z parent still renders above the lake.
	var parent := Node2D.new()
	parent.z_index = -100
	parent.position = Vector2(300, 1400)
	add_child(parent)
	var bulb := BULB.instantiate() as GreyboxBumper2D
	bulb.size = Vector2(224, 80)
	bulb.regeneration_delay = 1.0
	parent.add_child(bulb)
	var art := bulb.get_node_or_null("BulbArt") as AnimatedSprite2D
	check(art != null and art.is_visible_in_tree(), "Every bulb has visible runtime art")
	if art:
		check(art.sprite_frames.resource_path.contains("PetalV2"), "Runtime uses the editor's petal art")
		check(not art.z_as_relative and art.z_index == 30, "Backdrop depth cannot bury bulb art")
		check(art.animation == &"rush" and art.is_playing(), "Ready bulb animates")
		check(art.global_position.is_equal_approx(bulb.global_position), "Art aligns with nested bulb position")
		bulb.size = Vector2(160, 160)
		check(is_equal_approx(art.scale.x, 160.0 / 202.6667), "Art follows bulb resize")
		check(bulb.get_node("ContactReceiver/CollisionShape2D").shape.size == Vector2(160, 160), "Art does not change gameplay collision")
		bulb.activate_from_grapple()
		check(art.animation == &"pop", "Pop starts with gameplay activation")
		await get_tree().create_timer(0.2).timeout
		check(art.animation == &"spent" and bulb.is_broken(), "Spent art matches spent gameplay")
		await get_tree().create_timer(0.4).timeout
		check(art.animation == &"refill" and bulb.is_broken(), "Refill anticipates regeneration")
		await get_tree().create_timer(0.5).timeout
		check(art.animation == &"rush" and not bulb.is_broken(), "Art and gameplay regenerate together")
		bulb.regeneration_delay = 0.0
		bulb.activate_from_grapple()
		await get_tree().create_timer(0.6).timeout
		check(art.animation == &"spent" and bulb.is_broken(), "Non-regenerating bulbs keep spent art")
	return {"checks": checks, "failures": failures}
