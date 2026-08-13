extends Node

const LOOMKIN_SCENE := preload("res://Src/Enemies/Loomkin/loomkin.tscn")

var _failures: Array[String] = []

func _ready() -> void:
	await _verify_red_influence()
	await _verify_blue_dynamic_influence()
	await _verify_yellow_combat_guard()
	if _failures.is_empty():
		print("ENEMY_INFLUENCE_VERIFY: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("ENEMY_INFLUENCE_VERIFY: %s" % failure)
	get_tree().quit(1)

func _verify_red_influence() -> void:
	var section := EnemySection.new()
	section.enemy_influence = EnemyInfluenceController.Influence.RED
	var nesting := Node.new()
	section.add_child(nesting)
	var enemy := LOOMKIN_SCENE.instantiate() as EnemyBase
	var base_move_speed := enemy.stats.move_speed
	var base_chase_speed := enemy.stats.chase_speed
	var base_attack_cooldown := enemy.stats.attack_cooldown
	var base_detection_radius := _detection_radius(enemy)
	nesting.add_child(enemy)
	add_child(section)
	await get_tree().process_frame

	_expect(enemy.enemy_influence == EnemyInfluenceController.Influence.RED, "Red influence must reach enemies nested below a room breakout.")
	_expect(is_equal_approx(enemy.get_chase_speed(), base_chase_speed * 1.15), "Red influence must increase chase speed modestly.")
	_expect(is_equal_approx(enemy.get_attack_cooldown_multiplier(), 0.8), "Red influence must reduce attack downtime without changing telegraphs.")
	_expect(is_equal_approx(_detection_radius(enemy), base_detection_radius * 1.3), "Red influence must expand detection range.")
	_expect(is_equal_approx(enemy.stats.move_speed, base_move_speed), "Influences must not mutate shared EnemyStats movement values.")
	_expect(is_equal_approx(enemy.stats.attack_cooldown, base_attack_cooldown), "Influences must not mutate shared EnemyStats attack values.")
	_expect(enemy.get_node_or_null("EnemyInfluenceVFX") is EnemyInfluenceVFX, "Influenced enemies must receive the shared graphic VFX controller.")
	_verify_soul_light(enemy)
	section.queue_free()
	await get_tree().process_frame

func _verify_blue_dynamic_influence() -> void:
	var section := EnemySection.new()
	section.enemy_influence = EnemyInfluenceController.Influence.BLUE
	add_child(section)
	await get_tree().process_frame
	var nesting := Node.new()
	section.add_child(nesting)
	var enemy := LOOMKIN_SCENE.instantiate() as EnemyBase
	var base_move_speed := enemy.stats.move_speed
	var base_chase_speed := enemy.stats.chase_speed
	nesting.add_child(enemy)
	await get_tree().process_frame

	_expect(enemy.enemy_influence == EnemyInfluenceController.Influence.BLUE, "Blue influence must reach enemies added later under nested spawn containers.")
	_expect(is_equal_approx(enemy.get_move_speed(), base_move_speed * 1.2), "Blue influence must increase battlefield movement speed.")
	_expect(is_equal_approx(enemy.get_chase_speed(), base_chase_speed * 1.25), "Blue influence must increase chase speed.")
	_expect(is_equal_approx(enemy.get_reposition_speed_multiplier(), 1.2), "Blue influence must improve repositioning speed.")
	_expect(is_equal_approx(enemy.get_attack_cooldown_multiplier(), 1.0), "Blue influence must preserve attack timing and telegraph readability.")
	section.queue_free()
	await get_tree().process_frame

func _verify_yellow_combat_guard() -> void:
	var section := EnemySection.new()
	section.enemy_influence = EnemyInfluenceController.Influence.YELLOW
	var enemy := LOOMKIN_SCENE.instantiate() as EnemyBase
	section.add_child(enemy)
	add_child(section)
	await get_tree().process_frame
	var controller := enemy.get_node_or_null("EnemyInfluenceController") as EnemyInfluenceController

	_expect(enemy.enemy_influence == EnemyInfluenceController.Influence.YELLOW, "Yellow influence must be assigned by its room breakout.")
	_expect(controller != null, "Yellow enemies must use the reusable influence controller.")
	if controller:
		_expect(bool(controller.call("_can_begin_yellow_phase")), "Yellow enemies must be allowed to phase while patrolling without a target.")
		var vfx := enemy.get_node_or_null("EnemyInfluenceVFX") as EnemyInfluenceVFX
		if vfx:
			vfx.call("_update_yellow_history", 0.1)
			vfx.begin_yellow_unravel()
			_expect(
				(vfx.get("_yellow_afterimages") as Array).size() == 3,
				"Yellow unravel must leave three stepped positional afterimages."
			)
		var combat_target := Node2D.new()
		enemy.target = combat_target
		_expect(not bool(controller.call("_can_begin_yellow_phase")), "Yellow enemies must never begin a phase while fighting the player.")
		enemy.target = null
		combat_target.free()
		controller.call("_begin_yellow_phase")
		controller.physics_process(0.3)
		controller.physics_process(0.5)
		controller.physics_process(0.3)
		_expect(not controller.is_phasing(), "Yellow phasing must always finish and return control to the enemy.")
		_expect(enemy.visuals.visible, "Yellow reform must restore enemy visuals.")
		controller.call("_begin_yellow_phase")
		enemy.enemy_influence = EnemyInfluenceController.Influence.NONE
		_expect(not controller.is_phasing(), "Changing influence must safely cancel an in-progress Yellow phase.")
	section.queue_free()
	await get_tree().process_frame

func _detection_radius(enemy: EnemyBase) -> float:
	var shape_node := enemy.get_node_or_null("DetectionArea/CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape is CircleShape2D:
		return 0.0
	return (shape_node.shape as CircleShape2D).radius

func _verify_soul_light(enemy: EnemyBase) -> void:
	var soul_light := enemy.get_node_or_null("EnemySoulLight") as PointLight2D
	_expect(soul_light != null, "Enemies must inherit the shared subtle Soul light.")
	if soul_light:
		_expect(soul_light.energy <= 0.2, "Enemy Soul light must remain restrained rather than reading as an aura.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
