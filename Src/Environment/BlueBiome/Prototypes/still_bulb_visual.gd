extends AnimatedSprite2D
## Presentation only: gameplay continues to own activation and regeneration.
var bulb: GreyboxBumper2D
var elapsed := -1.0

func setup(target: GreyboxBumper2D) -> void:
	bulb = target
	sprite_frames = load("res://Assets/BlueBiome/StillVillage/Bulb/bulb_frames.tres")
	centered = false
	offset = Vector2(-196.0, -311.4667)
	scale = Vector2.ONE * (bulb.size.x / 202.6667)
	position = bulb.position
	z_index = 30
	bulb.broken.connect(_on_broken)
	bulb.regenerated.connect(_on_regenerated)
	speed_scale = 0.4
	play(&"rush")

func _on_broken() -> void:
	elapsed = 0.0
	speed_scale = 4.0
	play(&"pop")
	_emit_release()

func _emit_release() -> void:
	var spray := CPUParticles2D.new()
	spray.name = "ReleasedCurrent"
	get_parent().add_child(spray)
	spray.global_position = global_position
	spray.z_index = z_index + 1
	spray.amount = 32
	spray.lifetime = 0.32
	spray.one_shot = true
	spray.explosiveness = 1.0
	spray.local_coords = false
	spray.direction = bulb.release_direction if bulb.release_direction != Vector2.ZERO else Vector2.UP
	spray.spread = 18.0 if bulb.release_direction != Vector2.ZERO else 180.0
	spray.initial_velocity_min = 650.0 if bulb.release_direction != Vector2.ZERO else 110.0
	spray.initial_velocity_max = 1150.0 if bulb.release_direction != Vector2.ZERO else 250.0
	spray.gravity = Vector2(0, 260)
	spray.scale_amount_min = 0.6
	spray.scale_amount_max = 1.5
	var droplet := GradientTexture2D.new()
	droplet.width = 20
	droplet.height = 8
	droplet.fill = GradientTexture2D.FILL_RADIAL
	droplet.fill_from = Vector2(0.5, 0.5)
	droplet.fill_to = Vector2(1, 0.5)
	var edge := Gradient.new()
	edge.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	droplet.gradient = edge
	spray.texture = droplet
	spray.angle_min = rad_to_deg(spray.direction.angle())
	spray.angle_max = spray.angle_min
	spray.color = Color(0.45, 0.9, 1.0, 0.85)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.65, 0.95, 1, 0.95), Color(0.3, 0.8, 1, 0)])
	spray.color_ramp = gradient
	spray.emitting = true
	spray.finished.connect(spray.queue_free)

func _on_regenerated() -> void:
	elapsed = -1.0
	speed_scale = 0.4
	play(&"rush")

func _process(delta: float) -> void:
	if elapsed < 0.0 or not is_instance_valid(bulb):
		return
	elapsed += delta
	var refill_start := maxf(0.5, bulb.regeneration_delay - 1.25)
	if bulb.regeneration_delay > 0.5 and elapsed >= refill_start:
		if animation != &"refill":
			speed_scale = 1.25 / maxf(bulb.regeneration_delay - refill_start, 0.05)
			play(&"refill")
	elif elapsed >= 0.125 and animation == &"pop":
		speed_scale = 1.0
		play(&"spent")
