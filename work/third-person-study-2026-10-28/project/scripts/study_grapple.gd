extends Node3D
## Collision hookshot: terrain, buildings and enemies all receive the needle.
const MAX_RANGE := 25.0
var actor
var world
var candidate
var candidate_point := Vector3.ZERO
var candidate_normal := Vector3.UP
var target
var local_point := Vector3.ZERO
var local_normal := Vector3.UP
var active := false
var connected := false
var launch_time := 0.0
var elapsed := 0.0
var stall_time := 0.0
var last_distance := 0.0
var cooldown := 0.0
var origin_position := Vector3.ZERO
var rope: Array[MeshInstance3D] = []
var locked_enemy := false
var mode := "zip"
var rope_length := 0.0
var connections := 0
var strikes := 0
var tip_position := Vector3.ZERO
var needle: MeshInstance3D

func _ready() -> void:
	actor = get_parent()
	world = actor.get_parent()
	needle = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = 0.035
	mesh.height = 0.2
	mesh.radial_segments = 6
	needle.mesh = mesh
	needle.material_override = world.fx.glow(Color("c1d3d1"))
	needle.visible = false
	world.add_child(needle)
	for i in range(3):
		var strand := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.009
		cylinder.bottom_radius = 0.009
		cylinder.radial_segments = 5
		strand.mesh = cylinder
		strand.material_override = world.fx.glow(Color("c5b28b") if i < 2 else Color("7baeb3"))
		strand.visible = false
		world.add_child(strand)
		rope.append(strand)

func ray(a: Vector3, b: Vector3) -> Dictionary:
	return actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 5, [actor.get_rid()]))

func attach_position(node) -> Vector3:
	return node.global_position + Vector3.UP * node.target_height if node.is_in_group("study_enemies") else node.to_global(local_point)

func update_candidate() -> void:
	candidate = null
	if actor.combat.dead: return
	var origin: Vector3 = actor.camera.global_position
	var direction: Vector3 = -actor.camera.global_basis.z
	# Skip the camera-to-character segment: over-the-shoulder aim starts at the hero.
	origin += direction*maxf(0,(actor.global_position+Vector3.UP*1.4-origin).dot(direction))
	var hit := ray(origin, origin + direction * (MAX_RANGE + actor.distance))
	if hit.is_empty(): return
	var point: Vector3 = hit.position
	if actor.grapple_origin().distance_to(point) > MAX_RANGE or actor.grapple_origin().distance_to(point) < 0.7: return
	var hand_hit := ray(actor.grapple_origin(), point - hit.normal * 0.04)
	if not hand_hit.is_empty() and hand_hit.collider != hit.collider: return
	if hit.collider.is_in_group("study_enemies") and hit.collider.dead: return
	candidate = hit.collider
	candidate_point = point
	candidate_normal = hit.normal

func select_hit(node: Node3D, point: Vector3, normal: Vector3) -> void:
	target = node
	local_point = node.to_local(point)
	local_normal = node.global_basis.inverse() * normal
	locked_enemy = node.is_in_group("study_enemies")

func fire() -> bool:
	if active or cooldown > 0 or actor.combat.dead: return false
	if actor.combat.action!="" and not (actor.combat.action=="recover" and actor.combat.recovery_time<=.08): return false
	update_candidate()
	if not is_instance_valid(candidate):
		world.notice("Aim at a solid surface or enemy within 25 metres")
		return false
	if actor.swimming or not actor.combat.spend_ap(1): return false
	mode="swing" if Input.is_action_pressed("sprint") and not candidate.is_in_group("study_enemies") else "zip"
	select_hit(candidate, candidate_point, candidate_normal)
	origin_position = actor.grapple_origin()
	tip_position = origin_position
	last_distance = origin_position.distance_to(candidate_point)
	rope_length=last_distance
	launch_time = last_distance / 35.0
	elapsed = 0
	stall_time = 0
	connected = false
	active = true
	actor.combat.action = ""
	actor.combat.guarding = false
	actor.play_clip("casting_1", true)
	actor.animation.speed_scale = 3
	world.audio.play("grapple_throw", actor.global_position, -9)
	return true

func detach() -> void:
	if active: cooldown = 0.24
	active = false
	connected = false
	target = null
	for line in rope: line.visible = false
	needle.visible = false
	if is_instance_valid(actor) and actor.animation: actor.animation.speed_scale = 1

func jump_release() -> void:
	detach()
	actor.velocity.y = maxf(actor.velocity.y, 7.6)
	if actor.has_method("report_momentum"): actor.report_momentum("jump")

func arrival_position() -> Vector3:
	var point := attach_position(target)
	if locked_enemy:
		var away: Vector3 = actor.global_position - target.global_position
		away.y = 0
		return target.global_position + away.normalized() * (target.body_radius + 0.75)
	var normal: Vector3 = (target.global_basis * local_normal).normalized()
	# Capsule support distance along the normal prevents wall/ceiling penetration.
	return point + normal * (0.37 + 0.66 * absf(normal.y)) - Vector3.UP * 0.95

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
	elapsed += delta
	if not connected:
		var next := tip_position.move_toward(point, 35 * delta)
		var hit := ray(tip_position, next + (point-tip_position).normalized() * 0.04)
		if not hit.is_empty():
			select_hit(hit.collider, hit.position, hit.normal)
			point = attach_position(target)
			connected = true
		elif next.distance_to(point) < 0.06: connected = true
		if connected:
			if mode=="swing": rope_length=swing_origin().distance_to(point)
			connections += 1
			last_distance = actor.global_position.distance_to(arrival_position())
			world.audio.play("grapple_connect", point, -12)
			world.fx.burst(point, Color("cdbb91"))
			if actor.has_method("report_momentum"): actor.report_momentum("grapple")
		tip_position = point if connected else next
	else:
		var obstruction := ray(hand, point)
		if not obstruction.is_empty() and obstruction.collider != target:
			detach()
			return
		tip_position = point
		if mode=="swing":
			swing_tick(delta,point)
			draw_rope(hand)
			return
		actor.play_clip("grapple_swinging_1")
		actor.animation.speed_scale = 1.2
		var difference: Vector3 = arrival_position() - actor.global_position
		var distance := difference.length()
		if distance < (0.5 if locked_enemy else 0.16):
			if locked_enemy:
				var direction: Vector3 = (target.global_position-actor.global_position).normalized()
				var range_bonus := lerpf(1.0, 1.25, clampf((origin_position.distance_to(point)/MAX_RANGE-0.35)/0.65, 0, 1))
				target.receive_hit(roundi(30*range_bonus), direction * 3, false)
				strikes += 1
				actor.velocity = -direction * 4 + Vector3.UP * 2.75
				world.fx.burst(point, Color("d9c49a"), true)
			else:
				actor.velocity *= 0.25
				if actor.has_method("try_mantle"): actor.try_mantle()
			detach()
			return
		stall_time = stall_time + delta if distance > last_distance-0.005 else 0.0
		last_distance = distance
		if stall_time > 0.2 or elapsed > 4.0:
			if actor.has_method("try_mantle"): actor.try_mantle()
			detach()
			return
		var multiplier: float = actor.momentum_multiplier("grapple_pull") if actor.has_method("momentum_multiplier") else 1.0
		actor.velocity = difference.normalized() * minf((16.0 if locked_enemy else 12.0)*multiplier, distance/maxf(delta, 0.001))
		var horizontal := Vector3(difference.x, 0, difference.z)
		if horizontal.length() > 0.1: actor.visual.rotation.y = atan2(horizontal.x, horizontal.z)
	draw_rope(hand)

func draw_rope(hand: Vector3) -> void:
	needle.visible = true
	needle.position = tip_position
	if hand.distance_to(tip_position) > 0.001: needle.quaternion = Quaternion(Vector3.UP, (tip_position-hand).normalized())
	for i in range(rope.size()):
		var offset := Vector3(cos(elapsed*12+i*TAU/3), sin(elapsed*12+i*TAU/3), 0) * 0.012
		var a := hand+offset
		var b := tip_position+offset
		rope[i].visible = true
		rope[i].position = (a+b)*0.5
		rope[i].mesh.height = maxf(0.01, a.distance_to(b))
		if a.distance_to(b) > 0.001: rope[i].quaternion = Quaternion(Vector3.UP, (b-a).normalized())

func swing_origin() -> Vector3:
	# Animation must not inject energy into the pendulum. The visible rope still
	# launches from hand.L; physical tension acts at a stable capsule attachment.
	return actor.global_position+Vector3.UP*1.35

func swing_tick(delta: float, anchor: Vector3) -> void:
	actor.play_clip("grapple_swinging_1")
	var radial: Vector3=(swing_origin()-anchor).normalized()
	var pending:=Vector3.DOWN*19*delta if not actor.is_on_floor() and not actor.swimming else Vector3.ZERO
	var v: Vector3=actor.velocity+pending
	var pump: Vector3=actor.input_direction-radial*actor.input_direction.dot(radial)
	v+=pump*delta*14
	var distance: float=swing_origin().distance_to(anchor)
	if distance>=rope_length-.12:
		var outward: float=v.dot(radial)
		if outward>0: v-=radial*outward
		v-=radial*maxf(0,distance-rope_length)*10
	actor.velocity=v.limit_length(18)-pending
	if actor.input_direction.length()>.1: actor.visual.rotation.y=atan2(actor.input_direction.x,actor.input_direction.z)
