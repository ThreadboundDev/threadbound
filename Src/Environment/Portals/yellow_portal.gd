extends Area2D
class_name YellowPortal

static var _teleport_locks: Dictionary = {}

@export var portal_id := 1
@export var sequence_index := 0
@export var required_thread: StringName = &""
@export var teleport_cooldown := 0.45
@export var arrival_velocity_multiplier := 1.0
@export var animation_speed := 8.0

@onready var portal_sprite: AnimatedSprite2D = $PortalSprite as AnimatedSprite2D
@onready var exit_point: Marker2D = $ExitPoint as Marker2D

func _ready() -> void:
	add_to_group("yellow_portals")
	body_entered.connect(_on_body_entered)
	if not DemoProgress.threads_changed.is_connected(_update_lock_state):
		DemoProgress.threads_changed.connect(_update_lock_state)
	if portal_sprite:
		portal_sprite.speed_scale = animation_speed
		portal_sprite.play(&"idle")
	_update_lock_state()

func get_exit_global_position() -> Vector2:
	return exit_point.global_position if exit_point else global_position

func _on_body_entered(body: Node) -> void:
	if not _is_unlocked() or not body.is_in_group("player") or _is_body_locked(body):
		return

	var destination := _find_destination_portal()
	if not destination:
		return

	_lock_body(body)
	_teleport_body(body, destination)

func _find_destination_portal() -> YellowPortal:
	var matching_portals: Array[YellowPortal] = []
	for node in get_tree().get_nodes_in_group("yellow_portals"):
		var portal := node as YellowPortal
		if portal and portal.portal_id == portal_id and portal._is_unlocked():
			matching_portals.append(portal)

	if matching_portals.size() <= 1:
		return null

	matching_portals.sort_custom(_sort_portals)
	var current_index := matching_portals.find(self)
	if current_index < 0:
		return null

	return matching_portals[(current_index + 1) % matching_portals.size()]

func _sort_portals(a: YellowPortal, b: YellowPortal) -> bool:
	if a.sequence_index == b.sequence_index:
		return a.get_index() < b.get_index()

	return a.sequence_index < b.sequence_index

func _teleport_body(body: Node, destination: YellowPortal) -> void:
	var body_2d := body as Node2D
	if not body_2d:
		return

	var character_body := body as CharacterBody2D
	var body_velocity := character_body.velocity if character_body else Vector2.ZERO
	body_2d.global_position = destination.get_exit_global_position()
	if character_body:
		body.set("velocity", body_velocity * arrival_velocity_multiplier)

func _is_body_locked(body: Node) -> bool:
	var body_id := body.get_instance_id()
	var unlock_time_msec := int(_teleport_locks.get(body_id, 0))
	if Time.get_ticks_msec() < unlock_time_msec:
		return true

	_teleport_locks.erase(body_id)
	return false

func _lock_body(body: Node) -> void:
	var lock_msec := int(maxf(0.0, teleport_cooldown) * 1000.0)
	_teleport_locks[body.get_instance_id()] = Time.get_ticks_msec() + lock_msec

func _is_unlocked() -> bool:
	return String(required_thread).is_empty() or DemoProgress.has_thread(required_thread)

func _update_lock_state() -> void:
	var unlocked := _is_unlocked()
	visible = unlocked
	monitoring = unlocked
	monitorable = unlocked
