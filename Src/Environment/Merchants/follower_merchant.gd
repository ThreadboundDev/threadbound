extends Area2D
class_name FollowerMerchant

const MERCHANT_MENU_SCENE := preload("res://Src/UI/MerchantMenu/merchant_menu.tscn")
const REQUIRED_THREADS: Array[StringName] = [&"power", &"balance", &"essence"]
const PROGRESSION_DIALOGUE := [
	{
		"id": &"guidance",
		"thread": &"",
		"text": "Three threads bind the way ahead: Power, Balance, Essence. Each wing asks a different question. None will tell you what your answer means."
	},
	{
		"id": &"power",
		"thread": &"power",
		"text": "Power answers you. Strength opens many paths. It is less gifted at choosing among them."
	},
	{
		"id": &"balance",
		"thread": &"balance",
		"text": "Balance answers you. Do not mistake stillness for mastery. Even a poised thread may be waiting to snap."
	},
	{
		"id": &"essence",
		"thread": &"essence",
		"text": "Essence answers you. Clever hands loosen knots. Clever minds sometimes pull them tighter."
	},
	{
		"id": &"three_threads",
		"requires_all": true,
		"text": "Three threads gathered, and still you remain unfinished. Good. Finished things have so few choices left."
	},
	{
		"id": &"proto_weaver",
		"requires_all": true,
		"text": "Something beyond that door has very firm ideas about where loose threads belong."
	},
]
const REPEAT_DIALOGUE := [
	"You are not lost. Lost things had somewhere they were meant to be.",
	"Every knot is a choice that has forgotten it was made.",
	"I sell what can be counted. The costly things are rarely so simple.",
]

@export var prompt_action_text := "Talk"
@export var idle_sheet: Texture2D
@export_range(1, 24, 1) var idle_sheet_columns := 6
@export_range(1, 24, 1) var idle_sheet_rows := 4
@export_range(1, 256, 1) var idle_frame_count := 24
@export_range(1.0, 24.0, 0.5) var idle_animation_speed := 8.0
@export var idle_ping_pong := true
@export var art_faces_right := true
@export var default_faces_left := true
@export var purchased_one_time_items: Dictionary = {}

@onready var follower_sprite: AnimatedSprite2D = $FollowerSprite as AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel as Label

var _player: Node
var _menu: Node
var _repeat_dialogue_index := 0

func _ready() -> void:
	add_to_group("merchants")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var input_manager := get_node_or_null("/root/InputBindingManager")
	if input_manager and input_manager.has_signal("bindings_changed"):
		input_manager.bindings_changed.connect(_refresh_prompt_label)
	_build_idle_animation()
	_apply_default_facing()
	_refresh_prompt_label()
	if prompt_label:
		prompt_label.visible = false

func _process(_delta: float) -> void:
	_face_player()

func interact(interacting_player: Node) -> void:
	if interacting_player != _player or _menu:
		return

	_open_merchant_menu(interacting_player)

func try_purchase(item_id: StringName, player: Node, cost: int, one_time := false) -> bool:
	if not player:
		return false
	if one_time and purchased_one_time_items.get(item_id, false):
		return false
	if not _can_afford(player, cost):
		return false

	var applied := _apply_purchase_effect(item_id, player, cost)
	if not applied:
		return false

	if item_id != &"vitality_thread":
		_spend_thread_knots(player, cost)
	if one_time:
		purchased_one_time_items[item_id] = true
	return true

func has_purchased(item_id: StringName) -> bool:
	if item_id == &"merchant_knot_pattern" and EquipManager:
		return EquipManager.owns_pattern(&"merchant_knot")
	return purchased_one_time_items.get(item_id, false)

func get_opening_line() -> String:
	return "Ah. A loose thread with somewhere to be. That is new."

func get_next_dialogue_line() -> String:
	for entry in PROGRESSION_DIALOGUE:
		var dialogue_id := StringName(entry.get("id", &""))
		if DemoProgress.has_heard_follower_dialogue(dialogue_id):
			continue
		if not _dialogue_entry_is_available(entry):
			continue
		DemoProgress.mark_follower_dialogue_heard(dialogue_id)
		return String(entry.get("text", ""))

	var line := String(REPEAT_DIALOGUE[_repeat_dialogue_index % REPEAT_DIALOGUE.size()])
	_repeat_dialogue_index += 1
	return line

func get_farewell_line() -> String:
	if DemoProgress.claimed_count(REQUIRED_THREADS) == REQUIRED_THREADS.size():
		return "Go on, then. Something beyond that door is listening for loose ends."
	return "Go on, then. I would hate to make your choices for you."

func can_purchase_item(item_id: StringName, player: Node) -> bool:
	if item_id != &"small_heal":
		return true
	var health_component := player.get_node_or_null("HealthComponent") as HealthComponent if player else null
	return health_component != null and health_component.current_health < health_component.max_health

func get_purchase_block_reason(item_id: StringName, player: Node) -> String:
	if item_id == &"small_heal" and not can_purchase_item(item_id, player):
		return "Your thread needs no mending."
	return "The Follower cannot offer this yet."

func _open_merchant_menu(player: Node) -> void:
	_menu = MERCHANT_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(_menu)
	if _menu.has_method("set_context"):
		_menu.set_context(self, player)
	if _menu.has_signal("closed"):
		_menu.closed.connect(_on_menu_closed)
	if prompt_label:
		prompt_label.visible = false

func _dialogue_entry_is_available(entry: Dictionary) -> bool:
	if bool(entry.get("requires_all", false)):
		return DemoProgress.claimed_count(REQUIRED_THREADS) == REQUIRED_THREADS.size()
	var required_thread := StringName(entry.get("thread", &""))
	return String(required_thread).is_empty() or DemoProgress.has_thread(required_thread)

func _on_menu_closed() -> void:
	_menu = null
	if _player and prompt_label:
		_refresh_prompt_label()
		prompt_label.visible = true

func _apply_purchase_effect(item_id: StringName, player: Node, cost: int) -> bool:
	match item_id:
		&"small_heal":
			var health_component := player.get_node_or_null("HealthComponent") as HealthComponent
			if not health_component or health_component.current_health >= health_component.max_health:
				return false
			health_component.heal(35)
			AudioManager.play_ui(&"loot_special_item")
			return true
		&"ap_refresh":
			if not player.has_method("restore_action_points"):
				return false
			player.restore_action_points(2)
			AudioManager.play_ui(&"loot_special_item")
			return true
		&"momentum_boost":
			if player.get("momentum") == null or not player.has_method("set_momentum"):
				return false
			player.set_momentum(minf(100.0, float(player.momentum) + 35.0))
			AudioManager.play_ui(&"loot_special_item")
			return true
		&"vitality_thread":
			if not player.has_method("weave_stat_upgrade"):
				return false
			return player.weave_stat_upgrade(&"health", cost)
		&"merchant_knot_pattern":
			if not EquipManager:
				return false
			var unlocked := EquipManager.unlock_pattern(&"merchant_knot")
			if unlocked:
				AudioManager.play_ui(&"loot_special_item")
			return unlocked
	return false

func _can_afford(player: Node, cost: int) -> bool:
	if player.has_method("can_weave_stat_upgrade"):
		return player.can_weave_stat_upgrade(cost)
	var thread_knots = player.get("thread_knot_count")
	return thread_knots != null and int(thread_knots) >= cost

func _spend_thread_knots(player: Node, cost: int) -> void:
	if cost <= 0 or player.get("thread_knot_count") == null:
		return
	player.thread_knot_count = maxi(0, int(player.thread_knot_count) - cost)

func _build_idle_animation() -> void:
	if not follower_sprite or not idle_sheet:
		return

	var frame_width := idle_sheet.get_width() / idle_sheet_columns
	var frame_height := idle_sheet.get_height() / idle_sheet_rows
	var max_frames := idle_sheet_columns * idle_sheet_rows
	var used_frames := clampi(idle_frame_count, 1, max_frames)
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(&"idle")
	sprite_frames.set_animation_loop(&"idle", true)
	sprite_frames.set_animation_speed(&"idle", idle_animation_speed)

	var frame_order: Array[int] = []
	for frame_index in used_frames:
		frame_order.append(frame_index)
	if idle_ping_pong and used_frames > 1:
		for frame_index in range(used_frames - 2, 0, -1):
			frame_order.append(frame_index)

	for frame_index in frame_order:
		sprite_frames.add_frame(&"idle", _make_idle_atlas_frame(frame_index, frame_width, frame_height))

	follower_sprite.sprite_frames = sprite_frames
	follower_sprite.play(&"idle")

func _make_idle_atlas_frame(frame_index: int, frame_width: int, frame_height: int) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = idle_sheet
	atlas_texture.region = Rect2(
		(frame_index % idle_sheet_columns) * frame_width,
		(frame_index / idle_sheet_columns) * frame_height,
		frame_width,
		frame_height
	)
	return atlas_texture

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	if prompt_label:
		_refresh_prompt_label()
		prompt_label.visible = true
	if body.has_method("_on_interactable_entered"):
		body._on_interactable_entered(self)
	_face_player()

func _on_body_exited(body: Node) -> void:
	if body != _player:
		return

	if prompt_label:
		prompt_label.visible = false
	if body.has_method("_on_interactable_exited"):
		body._on_interactable_exited(self)
	_player = null
	_apply_default_facing()

func _refresh_prompt_label() -> void:
	if not prompt_label:
		return

	var action_text := InteractionPromptFormatter.prompt_action_from_text(prompt_action_text, "Talk")
	prompt_label.text = InteractionPromptFormatter.format_interact_prompt(action_text)

func _face_player() -> void:
	if not follower_sprite or not _player or not (_player is Node2D):
		return

	var player_node := _player as Node2D
	var player_is_left := player_node.global_position.x < global_position.x
	follower_sprite.flip_h = player_is_left if art_faces_right else not player_is_left

func _apply_default_facing() -> void:
	if not follower_sprite:
		return

	follower_sprite.flip_h = default_faces_left if art_faces_right else not default_faces_left
