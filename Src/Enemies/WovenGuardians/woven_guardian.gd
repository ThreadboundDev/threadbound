extends EnemyBase
## Helpers local to the two woven guardians; the shared combat system is unchanged.
@export var home_leash := 950.0
@onready var model: Node2D = $Visuals/Model
var attack_phase: StringName = &""
var phase_time := 0.0
var _death_fade: Tween

func _ready() -> void:
	super._ready()
	add_to_group("hermit_guardians")
	attack_hitbox.area_entered.disconnect(attack_hitbox._on_area_entered)
	state_machine.state_changed.connect(_guardian_state_changed)

func _try_contact_hurtbox(_area: Area2D) -> bool:
	return false

func dry_at(point: Vector2) -> bool:
	for pocket in get_tree().get_nodes_in_group("lake_air_pockets"):
		if pocket.contains_global_point(point):
			return true
	for water in get_tree().get_nodes_in_group("lake_water_volumes"):
		if water.contains_global_point(point):
			return false
	return true

func terrain_ray(from: Vector2, to: Vector2) -> Dictionary:
	var excludes: Array[RID] = [get_rid()]
	for player in get_tree().get_nodes_in_group("player"):
		if player is CollisionObject2D:
			excludes.append(player.get_rid())
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, collision_mask, excludes))

func _can_target_player(candidate: Node2D) -> bool:
	return super._can_target_player(candidate) and candidate.global_position.distance_to(home_position) < home_leash and dry_at(target_feet(candidate) - Vector2(0, 8)) and terrain_ray(global_position - Vector2(0, 75), target_center(candidate)).is_empty()

func target_center(candidate: Node2D) -> Vector2:
	var shape := candidate.get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
	return shape.global_position if shape else candidate.global_position - Vector2(0, 70)

func target_feet(candidate: Node2D) -> Vector2:
	var shape := candidate.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape.to_global(Vector2(0, shape.shape.get_rect().end.y)) if shape and shape.shape else candidate.global_position

func _refresh_target_availability() -> void:
	if state_machine and state_machine.current_state_name in [&"Attack", &"Hurt", &"Dead"]:
		# A lost target never cancels a committed attack or bypasses its recovery.
		if target and not _can_target_player(target):
			_release_target()
		return
	super._refresh_target_availability()

func sweep_hits(previous: Vector2) -> void:
	if not attack_hitbox.active:
		return
	var offset := attack_hitbox.global_position - global_position
	var distance := previous.distance_to(global_position)
	var steps := maxi(1, ceili(distance / 10.0))
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = ($AttackHitbox/CollisionShape2D as CollisionShape2D).shape
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for index in range(steps + 1):
		var sample := previous.lerp(global_position, float(index) / steps)
		query.transform = Transform2D(0, sample + offset)
		for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
			var box := result.collider as HurtboxComponent
			if box and box.hurtbox_owner is Node2D and terrain_ray(sample - Vector2(0, 75), _get_hurtbox_feedback_position(box)).is_empty():
				attack_hitbox._on_area_entered(box)

func end_attack() -> void:
	super.end_attack()
	attack_phase = &""
	phase_time = 0
	if model:
		model.set_tell(0)

func begin_polished_hurt_response() -> void:
	super.begin_polished_hurt_response()
	model.play_clip(&"hurt", stats.hurt_time)

func _play_death_collapse() -> void:
	model.play_clip(&"death", 1.2)
	_death_fade = create_tween()
	_death_fade.tween_interval(.9)
	_death_fade.tween_property(visuals, "modulate:a", 0.0, .35)

func reset_for_save_point() -> void:
	if _death_fade and _death_fade.is_valid():
		_death_fade.kill()
	super.reset_for_save_point()
	model.rotation = 0
	model.play_clip(&"idle")

func _guardian_state_changed(state: StringName) -> void:
	if state in [&"Idle", &"Patrol", &"Chase"]:
		model.play_clip(&"idle")
