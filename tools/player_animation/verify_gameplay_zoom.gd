extends SceneTree
## Run without --equipment-art-test to cover normal editor gameplay.

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func wheel(button: MouseButton, factor := 1.0) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.factor = factor
	event.pressed = true
	root.push_input(event)


func run() -> void:
	var camera := Camera2D.new()
	camera.zoom = Vector2(0.83, 0.83)
	root.add_child(camera)
	camera.make_current()
	await process_frame
	var baseline := camera.zoom
	wheel(MOUSE_BUTTON_WHEEL_UP)
	check(camera.zoom.is_equal_approx(baseline * 1.25), "Normal gameplay wheel-up zooms in")
	wheel(MOUSE_BUTTON_WHEEL_DOWN)
	check(camera.zoom.is_equal_approx(baseline), "Wheel-down reverses zoom-in")
	wheel(MOUSE_BUTTON_WHEEL_DOWN)
	check(camera.zoom.is_equal_approx(baseline), "Zoom-out stops at the saved gameplay framing")
	wheel(MOUSE_BUTTON_WHEEL_UP, 2.0)
	check(camera.zoom.is_equal_approx(baseline * 1.5625), "Multi-tick wheel input is respected")
	for tick in 30:
		wheel(MOUSE_BUTTON_WHEEL_UP)
	check(camera.zoom.is_equal_approx(baseline * 16.0), "Close-up zoom stops at 16x")
	var reset := InputEventKey.new()
	reset.keycode = KEY_BACKSLASH
	reset.pressed = true
	paused = true
	root.push_input(reset)
	check(camera.zoom.is_equal_approx(baseline * 16.0), "Paused menus do not reset gameplay zoom")
	paused = false
	root.push_input(reset)
	check(camera.zoom.is_equal_approx(baseline), "Backslash restores saved framing")
	paused = true
	wheel(MOUSE_BUTTON_WHEEL_UP)
	check(camera.zoom.is_equal_approx(baseline), "Paused menus do not zoom gameplay")
	paused = false
	camera.queue_free()
	await process_frame
	wheel(MOUSE_BUTTON_WHEEL_UP)
	root.push_input(reset)
	check(root.get_camera_2d() == null, "Zoom input tolerates scenes without a camera")
	print("Gameplay zoom: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
