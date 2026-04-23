class_name BaseGloves
extends BaseEquipment

# =============================================
# TUNABLES
# =============================================
@export_group("Thrown Grapple")
@export var throw_speed: float = 1800.0
@export var throw_gravity: float = 1200.0
@export var max_rope_length: float = 520.0

@export_group("Rope Visuals")
@export var rope_width: float = 4.0
@export var rope_color: Color = Color(0.95, 0.95, 1.0, 0.9)

@export_group("Climbing")
@export var climb_force: float = 2100.0
@export var climb_speed_cap: float = 720.0

@export_group("Cooldown")
@export var cooldown: float = 1.0

# State
var cooldown_timer: float = 0.0
var is_attached: bool = false
var is_flying: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var rope_line: Line2D = null

var grapple_velocity: Vector2 = Vector2.ZERO

func _init(_player = null):
	super(_player)
	slot_name = "Gloves"

	rope_line = Line2D.new()
	rope_line.width = rope_width
	rope_line.default_color = rope_color
	rope_line.visible = false
	if player:
		player.add_child(rope_line)

func thread_mechanic(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta

	if Input.is_action_just_pressed("Traversal"):
		if is_attached:
			_detach_rope()
		elif not is_flying and cooldown_timer <= 0.0:
			_throw_grapple()

	if is_flying:
		_update_flying_grapple(delta)

	if is_attached and Input.is_action_pressed("move_up"):
		_handle_climbing(delta)

	if is_attached:
		_enforce_max_rope_length()

	if is_attached or is_flying:
		_update_rope_visual()

# Improved aim direction with proper controller priority
func get_aim_direction() -> Vector2:
	# Right stick (controller) - priority
	var right_stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	if right_stick.length() > 0.25:   # deadzone - increased slightly for better feel
		return right_stick.normalized()
	
	# Mouse fallback only if stick is not being used
	var mouse_pos = player.get_global_mouse_position()
	return (mouse_pos - player.global_position).normalized()

func _throw_grapple() -> void:
	var direction = get_aim_direction()
	
	grapple_velocity = direction * throw_speed
	is_flying = true
	rope_line.visible = true
	grapple_point = player.global_position
	
	print("Base Gloves: Throwing grapple...")

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
	
	if Input.is_action_pressed("move_up"):
		player.velocity += dir * climb_force * delta
		if player.velocity.y < -climb_speed_cap:
			player.velocity.y = -climb_speed_cap

	var side = Input.get_axis("move_left", "move_right")
	player.velocity.x += side * 500.0 * delta

	# Press Jump to break grapple and jump off
	if Input.is_action_just_pressed("Jump"):
		_detach_rope()
		player.velocity.y = -650.0   # nice base jump-off boost
		return

func _enforce_max_rope_length() -> void:
	var current_dist = (grapple_point - player.global_position).length()
	
	if current_dist > max_rope_length:
		var pull_dir = (grapple_point - player.global_position).normalized()
		player.global_position = grapple_point - pull_dir * max_rope_length
		player.velocity = player.velocity.slide(pull_dir) * 0.92

func _detach_rope() -> void:
	is_attached = false
	is_flying = false
	if rope_line:
		rope_line.visible = false
		rope_line.clear_points()
	print("Base Gloves: Rope detached")

func _update_rope_visual() -> void:
	if not rope_line: return
	rope_line.clear_points()
	rope_line.add_point(rope_line.to_local(player.global_position))
	rope_line.add_point(rope_line.to_local(grapple_point))

func on_unequipped() -> void:
	if rope_line:
		rope_line.queue_free()
