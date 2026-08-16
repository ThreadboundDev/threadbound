extends Node

const AimHelperScript := preload("res://Src/Global/aim_helper.gd")

func _ready() -> void:
	var raw := Vector2.RIGHT
	var near_target := Vector2.RIGHT.rotated(deg_to_rad(6.0))
	var far_target := Vector2.RIGHT.rotated(deg_to_rad(10.0))
	var outside_target := Vector2.RIGHT.rotated(deg_to_rad(18.0))

	var assisted := AimHelperScript.apply_directional_assist(
		raw,
		[far_target, near_target],
		deg_to_rad(12.0),
		0.32
	)
	assert(assisted.angle() > 0.0, "Assist should gently move toward a valid target")
	assert(assisted.angle() < near_target.angle(), "Assist must not hard-snap to the target")

	var unchanged := AimHelperScript.apply_directional_assist(
		raw,
		[outside_target],
		deg_to_rad(12.0),
		0.32
	)
	assert(unchanged.is_equal_approx(raw), "Targets outside the cone must not alter aim")

	var closest := AimHelperScript.apply_directional_assist(
		raw,
		[far_target, near_target],
		deg_to_rad(12.0),
		1.0
	)
	assert(
		absf(closest.angle_to(near_target)) < absf(closest.angle_to(far_target)),
		"Angularly closest target should win"
	)

	print("Controller grapple aim-assist verification passed.")
	get_tree().quit(0)
