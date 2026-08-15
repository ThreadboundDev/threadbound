extends Area2D
class_name DemoThreadPickup

const MESSAGE_BOX_SCENE := preload("res://Src/UI/demo_message_box.tscn")

@export var thread_id: StringName = &""
@export var display_name := "Thread"
@export_multiline var collect_message := ""
@export var bob_height := 5.0
@export var bob_speed := 2.6
@export var spin_degrees_per_second := 0.0
@export var collect_fade_time := 0.18

@onready var sprite: Sprite2D = $Sprite2D as Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D

var _base_sprite_position := Vector2.ZERO
var _age := 0.0
var _collected := false

func _ready() -> void:
	add_to_group("demo_thread_pickups")
	body_entered.connect(_on_body_entered)
	if sprite:
		_base_sprite_position = sprite.position
	if DemoProgress.has_thread(thread_id):
		queue_free()

func _process(delta: float) -> void:
	if _collected or not sprite:
		return

	_age += delta
	sprite.position.y = _base_sprite_position.y + sin(_age * bob_speed) * bob_height
	if spin_degrees_per_second != 0.0:
		sprite.rotation_degrees += spin_degrees_per_second * delta

func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return

	_collect()

func _collect() -> void:
	_collected = true
	var is_first_thread := DemoProgress.claimed_count([&"power", &"balance", &"essence"]) == 0
	DemoProgress.claim_thread(thread_id)
	AudioManager.play_ui(&"loot_special_item")
	_show_collect_message(is_first_thread)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if not sprite:
		queue_free()
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, collect_fade_time)
	tween.tween_property(sprite, "scale", sprite.scale * 1.18, collect_fade_time)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _show_collect_message(is_first_thread := false) -> void:
	var message := collect_message
	if message.is_empty():
		message = "%s claimed." % display_name
	var hud := get_tree().get_first_node_in_group("combat_hud")
	if hud and hud.has_method("show_thread_reward"):
		hud.show_thread_reward(display_name)
	if is_first_thread and not DemoProgress.has_completed_world_event(&"tutorial.first_thread_guidance"):
		DemoProgress.complete_world_event(&"tutorial.first_thread_guidance")
		var input_family := InteractionPromptFormatter.get_active_input_family()
		var hot_swap := InputGlyphFormatter.get_action_display_bbcode(
			&"open_menu", "TAB", input_family, 30
		)
		var inventory := InputGlyphFormatter.get_action_display_bbcode(
			&"open_inventory", "I", input_family, 30
		)
		message += "\n\n[b]A NEW WAY OF WEAVING[/b]\nHold %s to open Hot Swap. Select the new gloves or return to Base at any time. Open Inventory with %s to inspect and equip your unlocked gear." % [hot_swap, inventory]

	var box := get_tree().get_first_node_in_group("demo_message_box")
	if not box:
		box = MESSAGE_BOX_SCENE.instantiate()
		get_tree().root.add_child(box)
	if is_first_thread and box.has_method("configure_layout"):
		box.configure_layout({
			"panel_rect": Rect2(-640.0, -250.0, 1280.0, 220.0),
			"text_margins": Vector4(38.0, 24.0, 38.0, 24.0),
			"display_time": 9.0,
			"fade_time": 0.2,
		})

	if box.has_method("show_message"):
		box.show_message(message, is_first_thread)
