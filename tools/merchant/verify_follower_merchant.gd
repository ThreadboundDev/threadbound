extends Node

const MERCHANT_SCENE := preload("res://Src/Environment/Merchants/follower_merchant.tscn")
const MENU_SCENE := preload("res://Src/UI/MerchantMenu/merchant_menu.tscn")
const DECOR_ATLAS := preload("res://Assets/chamber_of_first_weave/Follower/follower_neutral_decor_atlas.png")
const NATURE_ATLAS := preload("res://Assets/chamber_of_first_weave/Follower/follower_neutral_nature_atlas.png")
const WAYFARERS_LOOM := preload("res://Assets/chamber_of_first_weave/Follower/follower_wayfarers_loom.png")
const WAYFARERS_LOOM_IDLE_SHEET := preload("res://Assets/chamber_of_first_weave/Follower/follower_wayfarers_loom_idle_sheet.png")
const WAYFARERS_LOOM_ANIMATED_SCENE := preload("res://Assets/chamber_of_first_weave/Follower/follower_wayfarers_loom_animated.tscn")
const CHAMBER_SCENE := preload("res://Src/Environment/World/Chamber Of The First Weave.tscn")

class FakePlayer:
	extends Node
	var thread_knot_count := 20

	func can_weave_stat_upgrade(cost: int) -> bool:
		return thread_knot_count >= cost

class FakeMerchant:
	extends Node

	func get_opening_line() -> String:
		return "Opening"

	func get_next_dialogue_line() -> String:
		return "Talk"

	func get_farewell_line() -> String:
		return "Farewell"

	func has_purchased(_item_id: StringName) -> bool:
		return false

	func can_purchase_item(_item_id: StringName, _player: Node) -> bool:
		return true

var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_verify")

func _verify() -> void:
	_verify_dialogue_catalog()
	await _verify_menu_layout()
	_verify_decor_atlas()
	_verify_animated_loom()
	_verify_merchant_room()
	_finish()

func _verify_dialogue_catalog() -> void:
	var merchant := MERCHANT_SCENE.instantiate() as FollowerMerchant
	_expect(merchant != null, "Follower merchant scene instantiates.")
	if not merchant:
		return
	_expect(merchant.PROGRESSION_DIALOGUE.size() == 6, "Six banked progression observations are defined.")
	_expect(merchant.REPEAT_DIALOGUE.size() == 3, "Three repeat observations are defined.")
	var ids := {}
	for entry in merchant.PROGRESSION_DIALOGUE:
		ids[StringName(entry.get("id", &""))] = true
	for required_id in [&"guidance", &"power", &"balance", &"essence", &"three_threads", &"proto_weaver"]:
		_expect(ids.has(required_id), "Dialogue catalog contains %s." % required_id)
	merchant.free()

func _verify_menu_layout() -> void:
	var menu := MENU_SCENE.instantiate()
	var merchant := FakeMerchant.new()
	var player := FakePlayer.new()
	add_child(merchant)
	add_child(player)
	add_child(menu)
	menu.set_context(merchant, player)
	await get_tree().process_frame
	_expect(menu._choice_rows.size() == 3, "Interaction hub contains Talk, Buy, and Leave.")
	_expect(menu._shop_rows.size() == 3, "Shop contains the three focused demo offerings.")
	menu._show_talk()
	await get_tree().process_frame
	var footer := menu.get_node("Root/FooterLabel") as RichTextLabel
	_expect("BACK" in footer.text, "Talk view labels the mapped Tab/back action.")
	menu._show_shop()
	await get_tree().process_frame
	var rows := menu.get_node("Root/ShopPanel/Rows") as VBoxContainer
	var description := menu.get_node("Root/ShopPanel/DescriptionPanel") as Control
	_expect(rows.get_global_rect().end.y <= description.get_global_rect().position.y, "Shop rows do not overlap the description panel.")
	_expect(menu.ITEMS.all(func(item: Dictionary) -> bool: return item.get("id") not in [&"ap_refresh", &"momentum_boost"]), "Immediate AP and momentum purchases are removed.")
	menu.queue_free()
	merchant.queue_free()
	player.queue_free()
	await get_tree().process_frame
	get_tree().paused = false

func _verify_decor_atlas() -> void:
	_verify_transparent_atlas(DECOR_ATLAS, "Follower decor")
	_verify_transparent_atlas(NATURE_ATLAS, "Follower nature")
	_verify_transparent_atlas(WAYFARERS_LOOM, "Wayfarer's Loom")
	_verify_transparent_atlas(WAYFARERS_LOOM_IDLE_SHEET, "Wayfarer's Loom idle sheet")

func _verify_animated_loom() -> void:
	var animated_loom := WAYFARERS_LOOM_ANIMATED_SCENE.instantiate()
	add_child(animated_loom)
	var sprite := animated_loom.get_node("LoomSprite") as Sprite2D
	_expect(sprite.texture != null, "Animated loom initializes its first frame.")
	var first_texture := sprite.texture
	var first_position := sprite.position
	animated_loom._process(animated_loom.frame_duration)
	_expect(sprite.texture != first_texture, "Animated loom advances between source frames.")
	_expect(sprite.position != first_position, "Animated loom compensates for generated frame alignment.")
	animated_loom.queue_free()

func _verify_merchant_room() -> void:
	var chamber := CHAMBER_SCENE.instantiate()
	var root := "WorldArt/Rooms/MerchantRoom/"
	for section in ["Lighting", "Decoration", "HeroObject", "Merchant", "Portals", "Pickups", "Doors", "SavePoints"]:
		_expect(chamber.has_node(root + section), "Merchant room exposes its %s section directly in the chamber tree." % section)
	_expect(chamber.has_node(root + "HeroObject/WayfarersLoom"), "Merchant room includes the loom hero object.")
	_expect(chamber.has_node(root + "Merchant/FollowerMerchant"), "Merchant is owned by the merchant room.")
	_expect(chamber.has_node(root + "SavePoints/BlossomOfEryndor"), "Merchant room includes a functional save point.")
	var loom := chamber.get_node(root + "HeroObject/WayfarersLoom") as Sprite2D
	var merchant := chamber.get_node(root + "Merchant/FollowerMerchant") as FollowerMerchant
	var merchant_sprite := merchant.get_node("FollowerSprite") as AnimatedSprite2D
	_expect(loom != null and loom.texture == WAYFARERS_LOOM, "Merchant-room loom uses the stationary artwork.")
	_expect(loom != null and loom.get_script() == null, "Merchant-room loom has no animation controller.")
	_expect(loom.scale.x < 0.0, "Merchant-room loom faces the opposite direction.")
	_expect(merchant_sprite.flip_h, "Follower merchant faces left in the editor preview.")
	chamber.free()

func _verify_transparent_atlas(texture: Texture2D, atlas_name: String) -> void:
	var image := texture.get_image()
	_expect(image != null, "%s atlas loads." % atlas_name)
	if not image:
		return
	_expect(image.get_width() == 1536 and image.get_height() == 1024, "%s atlas keeps its production resolution." % atlas_name)
	_expect(image.detect_alpha() != Image.ALPHA_NONE, "%s atlas includes transparency." % atlas_name)
	for corner in [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		_expect(image.get_pixelv(corner).a <= 0.01, "%s atlas corner is transparent." % atlas_name)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Follower merchant verification failed: %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("Follower merchant verification passed.")
	get_tree().paused = false
	get_tree().quit(_failures.size())
