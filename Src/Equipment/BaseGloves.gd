class_name BaseGloves
extends BaseEquipment

# =============================================
# TUNABLES
# =============================================
@export_group("Thrown Grapple")
@export var throw_speed: float = 1800.0          # How fast the spike is thrown
@export var throw_gravity: float = 1200.0        # Arc strength
@export var max_rope_length: float = 520.0       # HARD maximum rope length

@export_group("Rope Visuals")
@export var rope_width: float = 4.0
@export var rope_color: Color = Color(0.95, 0.95, 1.0, 0.9)

@export_group("Climbing")
@export var climb_force: float = 2100.0
@export var climb_speed_cap: float = 720.0

@export_group("Cooldown")
@export var cooldown: float = 1.0

# Jump break while grappled
@export_group("Grapple Break Jump")
@export var grapple_break_jump_force: float = 420.0   # Short hop feel
@export var grapple_break_lateral_mult: float = 0.8

# State
var cooldown_timer: float = 0.0
var is_attached: bool = false
var is_flying: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var rope_line: Line2D = null
var aim_preview: Line2D = null

var grapple_velocity: Vector2 = Vector2.ZERO

func _init(_player = null):
	super(_player)
	slot_name = "Gloves"

	# Rope line for visuals
	rope_line = Line2D.new()
	rope_line.width = rope_width
	rope_line.default_color = rope_color
	rope_line.visible = false
	if player:
		player.add_child(rope_line)

	# Aim preview line (shows where grapple will fire)
	aim_preview = Line2D.new()
	aim_preview.width = 2.5
	aim_preview.default_color = rope_color
	aim_preview.default_color.a = 0.35
	aim_preview.visible = false
	if player:
		player.add_child(aim_preview)

func thread_mechanic(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# Jump to break grapple (short hop + detach) - feels much better than spamming Traversal
	if is_attached and Input.is_action_just_pressed("Jump"):
		_break_grapple_with_jump()
		return

	# Throw or detach normally
	if Input.is_action_just_pressed("Traversal"):
		if is_attached:
			_detach_rope()
		elif not is_flying and cooldown_timer <= 0.0:
			_throw_grapple()

	# Update flying grapple
	if is_flying:
		_update_flying_grapple(delta)

	# Climb using move_up
	if is_attached and Input.is_action_pressed("move_up"):
		_handle_climbing(delta)

	# Enforce max rope length (prevents stretching)
	if is_attached:
		_enforce_max_rope_length()

	# Visuals
	if is_attached or is_flying:
		_update_rope_visual()
	else:
		_update_aim_preview()

func _throw_grapple() -> void:
	var aim_dir: Vector2 = get_aim_direction()
	
	grapple_velocity = aim_dir * throw_speed
	is_flying = true
	rope_line.visible = true
	grapple_point = player.global_position
	
	print("Base Gloves: Throwing grapple toward ", aim_dir)

func _break_grapple_with_jump() -> void:
	# Short lateral hop - great for repositioning or pulling over edges
	var lateral = Input.get_axis("move_left", "move_right") * grapple_break_lateral_mult
	player.velocity.x += lateral * 380.0
	player.velocity.y = -grapple_break_jump_force
	
	_detach_rope()
	print("Base Gloves: Broke grapple with short hop")

func _update_flying_grapple(delta: float) -> void:
	grapple_velocity.y += throw_gravity * delta
	grapple_point += grapple_velocity * delta
	
	var space = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(player.global_position, grapple_point)
	var result = space.intersect_ray(query)
	
	if result:
		grapple_point = result.position
		is_flying = false
		is_attached = true
		cooldown_timer = cooldown
		print("Base Gloves: Grapple attached!")
	elif (grapple_point - player.global_position).length() > max_rope_length:
		_detach_rope()

func _handle_climbing(delta: float) -> void:
	var to_anchor = grapple_point - player.global_position
	var distance = to_anchor.length()
	
	if distance < 35.0:
		_detach_rope()
		return
	
	var dir = to_anchor.normalized()
	
	# Climb upward
	player.velocity += dir * climb_force * delta
	if player.velocity.y < -climb_speed_cap:
		player.velocity.y = -climb_speed_cap

	# Allow sideways movement while climbing
	var side = Input.get_axis("move_left", "move_right")
	player.velocity.x += side * 500.0 * delta

func _enforce_max_rope_length() -> void:
	var current_dist = (grapple_point - player.global_position).length()
	
	if current_dist > max_rope_length:
		var pull_dir = (grapple_point - player.global_position).normalized()
		player.global_position = grapple_point - pull_dir * max_rope_length
		
		# Add tension feel
		player.velocity = player.velocity.slide(pull_dir) * 0.92

func _detach_rope() -> void:
	is_attached = false
	is_flying = false
	if rope_line:
		rope_line.visible = false
		rope_line.clear_points()
	if aim_preview:
		aim_preview.visible = false
	print("Base Gloves: Rope detached")

func _update_rope_visual() -> void:
	if not rope_line: return
	rope_line.clear_points()
	rope_line.add_point(rope_line.to_local(player.global_position))
	rope_line.add_point(rope_line.to_local(grapple_point))

func _update_aim_preview() -> void:
	if not aim_preview: return
	if is_attached or is_flying:
		aim_preview.visible = false
		return
	
	var dir: Vector2 = get_aim_direction()
	aim_preview.clear_points()
	aim_preview.add_point(aim_preview.to_local(player.global_position))
	aim_preview.add_point(aim_preview.to_local(player.global_position + dir * 160.0))
	aim_preview.visible = true

func on_unequipped() -> void:
	if rope_line:
		rope_line.queue_free()
	if aim_preview:
		aim_preview.queue_free()
