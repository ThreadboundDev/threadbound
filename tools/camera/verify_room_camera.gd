extends Node

const CHAMBER_SCENE := preload(
	"res://Src/Environment/World/Chamber Of The First Weave.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	_verify_rectangle_zone()
	_verify_polygon_zone()
	_verify_chamber_wiring()
	_finish()


func _verify_rectangle_zone() -> void:
	var zone := RoomCameraZone2D.new()
	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000.0, 800.0)
	shape_node.shape = rectangle
	zone.add_child(shape_node)
	add_child(zone)

	_expect(zone.has_valid_boundary(), "Rectangle room boundary is valid.")
	_expect(zone.contains_global_point(Vector2.ZERO), "Rectangle contains its center.")
	var clamped := zone.clamp_camera_center(
		Vector2(480.0, 380.0),
		Vector2(100.0, 50.0)
	)
	_expect(
		clamped.is_equal_approx(Vector2(400.0, 350.0)),
		"Rectangle clamp keeps the viewport inside every edge."
	)
	zone.queue_free()


func _verify_polygon_zone() -> void:
	var zone := RoomCameraZone2D.new()
	var polygon_node := CollisionPolygon2D.new()
	polygon_node.polygon = PackedVector2Array([
		Vector2(-500.0, -300.0),
		Vector2(350.0, -300.0),
		Vector2(500.0, 0.0),
		Vector2(350.0, 300.0),
		Vector2(-500.0, 300.0),
	])
	zone.add_child(polygon_node)
	add_child(zone)

	_expect(zone.has_valid_boundary(), "Editable convex polygon boundary is valid.")
	var clamped := zone.clamp_camera_center(
		Vector2(480.0, 0.0),
		Vector2(100.0, 50.0)
	)
	_expect(clamped.x < 400.0, "Polygon edge constrains the camera center.")
	_expect(zone.contains_global_point(Vector2.ZERO), "Polygon contains its center.")
	zone.queue_free()


func _verify_chamber_wiring() -> void:
	var chamber := CHAMBER_SCENE.instantiate()
	var camera := chamber.get_node("Camera2D") as RoomCameraController
	var zone := chamber.get_node(
		"CameraZones/MerchantRoomCameraZone"
	) as RoomCameraZone2D
	_expect(camera != null, "Chamber camera uses the room camera controller.")
	_expect(zone != null, "Chamber exposes an editable merchant camera zone.")
	if camera:
		_expect(
			camera.position_smoothing_enabled,
			"Chamber camera keeps rendered motion smoothing enabled."
		)
		_expect(
			is_equal_approx(camera.position_smoothing_speed, 10.0),
			"Chamber camera uses the tuned smoothing speed."
		)
		_expect(
			camera.horizontal_dead_zone > 0.0,
			"Chamber camera composes movement through a horizontal dead zone."
		)
		_expect(
			camera.look_ahead_distance > 0.0,
			"Chamber camera has directional look-ahead."
		)
		_expect(
			camera.dash_look_ahead_distance > 0.0,
			"Chamber camera adds lead at dash speeds."
		)
		_expect(
			camera.fall_look_ahead_distance > 0.0,
			"Chamber camera has faster downward framing for falls."
		)
	var remote_follow := chamber.get_node(
		"Player/RemoteTransform2D"
	) as RemoteTransform2D
	_expect(remote_follow != null, "Player exposes cinematic camera ownership.")
	if remote_follow:
		remote_follow.update_position = false
		_expect(
			camera.is_follow_suspended(),
			"Disabled RemoteTransform2D suspends normal camera composition."
		)
		remote_follow.update_position = true
	if zone:
		_expect(zone.has_valid_boundary(), "Merchant camera zone has a valid boundary.")
		_expect(
			zone.contains_global_point(Vector2(4100.0, 1594.0)),
			"Merchant activity is inside its camera zone."
		)
		var center := zone.clamp_camera_center(
			Vector2(4100.0, 2200.0),
			Vector2(960.0, 540.0)
		)
		_expect(
			center.y <= 1760.01,
			"Merchant camera cannot expose space below the room boundary."
		)
	chamber.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Room camera verification failed: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Room camera verification passed.")
	get_tree().quit(_failures.size())
