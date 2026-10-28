extends Node3D
## Base hookshot translation: aim-assist, line-of-sight, pull, release and enemy strike.
var actor
var world
var candidate
var target
var active := false
var launch_time := 0.0
var elapsed := 0.0
var stall_time := 0.0
var last_distance := 0.0
var cooldown := 0.0
var origin_position := Vector3.ZERO
var rope: Array[MeshInstance3D] = []
var locked_enemy := false
var connections := 0
var strikes := 0
var tip_position := Vector3.ZERO
var needle: MeshInstance3D

func _ready() -> void:
	actor = get_parent()
	world = actor.get_parent()
	needle = MeshInstance3D.new()
	var needle_mesh := CylinderMesh.new()
	needle_mesh.top_radius = 0
	needle_mesh.bottom_radius = 0.035
	needle_mesh.height = 0.2
	needle_mesh.radial_segments = 6
	needle.mesh = needle_mesh
	needle.material_override = world.fx.glow(Color("c1d3d1"))
	needle.visible = false
	world.add_child(needle)
	for i in range(3):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.012
		mesh.bottom_radius = 0.012
		mesh.radial_segments = 5
		var node := MeshInstance3D.new()
		node.mesh = mesh
		node.material_override = world.fx.glow(Color("c5b28b") if i < 2 else Color("7baeb3"))
		node.visible = false
		world.add_child(node)
		rope.append(node)

func attach_position(node) -> Vector3:
	return node.global_position + Vector3.UP * node.target_height if node.is_in_group("study_enemies") else node.global_position

func update_candidate() -> void:
	candidate = null
	if actor.combat.dead: return
	var best := -100.0
	var forward: Vector3 = -actor.camera.global_basis.z
	var origin: Vector3 = actor.camera.global_position
	var choices: Array = get_tree().get_nodes_in_group("study_anchors")
	for enemy in get_tree().get_nodes_in_group("study_enemies"):
		if not enemy.dead: choices.append(enemy)
	for node in choices:
		if node.has_meta("landing") and actor.global_position.distance_to(node.get_meta("landing")) < 1.8:
			continue
		var point := attach_position(node)
		var distance: float = actor.global_position.distance_to(point)
		if distance > 25 or distance < 1.5: continue
		if actor.camera.is_position_behind(point): continue
		var alignment := forward.dot((point-origin).normalized())
		if alignment < 0.72: continue
		if not world.clear_sight(actor.global_position + Vector3.UP * 1.1, point): continue
		var score: float = alignment * 20 - distance * 0.08
		if node == actor.lock_target: score += 10
		if node.is_in_group("study_anchors"): score += 1.5
		if score > best:
			best = score
			candidate = node

func fire() -> bool:
	if active or cooldown > 0 or actor.combat.dead or actor.combat.action != "": return false
	update_candidate()
	if not is_instance_valid(candidate):
		world.notice("Aim toward a thread ring or lock onto an enemy")
		return false
	target = candidate
	locked_enemy = target.is_in_group("study_enemies")
	origin_position = actor.grapple_origin()
	last_distance = origin_position.distance_to(attach_position(target))
	launch_time = clampf(last_distance / 35, 0.1, 0.55)
	elapsed = 0
	stall_time = 0
	active = true
	actor.play_clip("casting_1", true)
	actor.animation.speed_scale = 3
	world.audio.play("grapple_throw", actor.global_position, -9)
	return true

func detach() -> void:
	if active:
		cooldown = 0.24
	active = false
	target = null
	for line in rope: line.visible = false
	needle.visible = false
	if is_instance_valid(actor) and actor.animation: actor.animation.speed_scale = 1

func jump_release() -> void:
	detach()
	actor.velocity.y = maxf(actor.velocity.y, 7.3)

func tick(delta: float) -> void:
	cooldown = maxf(0, cooldown-delta)
	if not active:
		update_candidate()
		return
	if not is_instance_valid(target) or (locked_enemy and target.dead):
		detach()
		return
	var point := attach_position(target)
	var hand: Vector3 = actor.grapple_origin()
	if not world.clear_sight(hand, point):
		detach()
		return
	var previous := elapsed
	elapsed += delta
	if elapsed < launch_time:
		tip_position = origin_position.lerp(point, elapsed / launch_time)
	else:
		if previous < launch_time:
			connections += 1
			world.audio.play("grapple_connect", point, -12)
			world.fx.burst(point, Color("cdbb91"))
		tip_position = point
		actor.play_clip("grapple_swinging_1")
		actor.animation.speed_scale = 1.2
		var arrival: Vector3 = point - Vector3.UP * 0.8
		if not locked_enemy and target.has_meta("landing"):
			arrival = target.get_meta("landing")
		var difference: Vector3 = arrival - actor.global_position
		var distance := difference.length()
		if (locked_enemy and distance < 2.0) or (not locked_enemy and distance < 0.65):
			var release_direction := difference.normalized()
			if locked_enemy:
				target.receive_hit(30, release_direction * 3, false)
				strikes += 1
				actor.velocity = -release_direction * 4 + Vector3.UP * 4.5
				world.fx.burst(point, Color("d9c49a"), true)
			else:
				actor.velocity = release_direction * 2.5 + Vector3.UP * 2.4
			detach()
			return
		if distance > last_distance - 0.015:
			stall_time += delta
		else:
			stall_time = 0
		last_distance = distance
		if stall_time > 0.55 or elapsed > 4.0:
			detach()
			return
		actor.velocity = difference.normalized() * (16.0 if locked_enemy else 12.0)
		var horizontal := Vector3(difference.x, 0, difference.z)
		if horizontal.length() > 0.1:
			actor.visual.rotation.y = atan2(horizontal.x, horizontal.z)
	needle.visible = true
	needle.position = tip_position
	if hand.distance_to(tip_position) > 0.001: needle.quaternion = Quaternion(Vector3.UP, (tip_position-hand).normalized())
	for i in range(rope.size()):
		var offset := Vector3(cos(elapsed*12 + i*TAU/3), sin(elapsed*12+i*TAU/3), 0) * 0.015
		var a := hand + offset
		var b := tip_position + offset
		rope[i].visible = true
		rope[i].position = (a+b)*0.5
		rope[i].mesh.height = maxf(0.01, a.distance_to(b))
		if a.distance_to(b) > 0.001: rope[i].quaternion = Quaternion(Vector3.UP, (b-a).normalized())
