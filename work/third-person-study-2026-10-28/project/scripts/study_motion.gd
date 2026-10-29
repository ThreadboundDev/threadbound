extends RefCounted
## Capsule stepping shared by Ruin and enemies; nav climb is limited to this height.
static func move(body: CharacterBody3D, delta: float, step := 0.26) -> void:
	var horizontal := Vector3(body.velocity.x,0,body.velocity.z)*delta
	if body.is_on_floor() and body.velocity.y<=0 and horizontal.length()>0.001 and body.test_move(body.global_transform,horizontal):
		var raised := body.global_transform
		raised.origin.y += step
		if not body.test_move(body.global_transform,Vector3.UP*step) and not body.test_move(raised,horizontal): body.global_position.y += step
	body.move_and_slide()
