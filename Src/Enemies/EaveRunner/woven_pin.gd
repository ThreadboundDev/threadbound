extends Node2D
## Straight, dodgeable pin. Continuous terrain/area queries prevent tunnelling.
var source: Node2D
var velocity := Vector2.ZERO
var damage_amount := 12
var lifetime := 0.0
var _spent := false

func _ready() -> void:
	add_to_group("woven_pins")
	# Keeping the travelling pin as the damage source gives blocking the correct
	# incoming side even after the thrower has moved to the opposite wall.
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _spent:
		return
	lifetime += delta
	if lifetime > 2.0 or not is_instance_valid(source) or not source.is_inside_tree() or source.is_dead:
		queue_free()
		return
	var destination := global_position + velocity * delta
	var excludes: Array[RID] = [source.get_rid()]
	for player in get_tree().get_nodes_in_group("player"):
		if player is CollisionObject2D:
			excludes.append(player.get_rid())
	var space := get_world_2d().direct_space_state
	var wall := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, destination, 1, excludes))
	if not wall.is_empty():
		destination = wall.position
	var length := global_position.distance_to(destination)
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	query.shape = shape
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var origin := global_position
	var steps := maxi(1, ceili(length / 5.0))
	for i in range(steps + 1):
		global_position = origin.lerp(destination, float(i) / steps)
		query.transform = Transform2D(0, global_position)
		for result in space.intersect_shape(query, 12):
			var box := result.collider as HurtboxComponent
			if not box or not box.hurtbox_owner or not box.hurtbox_owner.is_in_group("player"):
				continue
			var data := DamageData.new()
			data.amount = EnemyScaling.scale_damage(damage_amount)
			data.source = self
			data.hit_position = global_position
			data.knockback = velocity.normalized() * 170
			data.hitstun = .15
			data.hit_pause = .025
			if box.receive_hit(data):
				_spend()
				return
	global_position = destination
	rotation = velocity.angle()
	if not wall.is_empty():
		_spend()
	queue_redraw()

func _spend() -> void:
	_spent = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, .08)
	fade.tween_callback(queue_free)

func _draw() -> void:
	draw_line(Vector2(-31, 0), Vector2(9, 0), Color(.1, .3, .45), 3, true)
	draw_colored_polygon(PackedVector2Array([Vector2(20, 0), Vector2(6, -2.5), Vector2(6, 2.5)]), Color(.83, .86, .79))
	for x in range(-18, 5, 4):
		draw_line(Vector2(x, -2), Vector2(x + 2, 2), Color(.65, .50, .31), 1.0, true)
	draw_polyline(PackedVector2Array([Vector2(-28,0), Vector2(-36, -3), Vector2(-43, 2)]), Color(.35, .7, .86, .65), 1.2, true)
