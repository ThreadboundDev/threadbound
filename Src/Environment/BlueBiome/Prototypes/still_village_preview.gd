extends Node2D
## Isolated dressing pass. The inherited scene owns every gameplay collider.
const KIT := "res://Src/Environment/BlueBiome/ArtPlaceables/StillVillage/"
const BULB_VISUAL := preload("res://Src/Environment/BlueBiome/Prototypes/still_bulb_visual.gd")
var far_layer: Sprite2D
var near_layer: Sprite2D
var lake_fill: ColorRect
var art: Node2D

func _ready() -> void:
	$Backdrop.hide()
	$Signs.hide()
	_build_background()
	art = Node2D.new()
	art.name = "StillVillageArt"
	add_child(art)
	var ground := Polygon2D.new()
	ground.name = "GroundMass"
	ground.polygon = PackedVector2Array([Vector2(-384, 800), Vector2(4992, 800), Vector2(4992, 1800), Vector2(-384, 1800)])
	ground.color = Color("10263d")
	ground.z_index = -3
	art.add_child(ground)
	for block in $Geometry.get_children():
		block.self_modulate.a = 0.0
		if block.name == &"RecoveryFloor":
			for i in range(10):
				_place("stone_cap_long", Vector2(-256 + i * 512, 800), Vector2.ONE, 2)
			continue
		if "Wall" in str(block.name):
			var wall := Polygon2D.new()
			wall.polygon = PackedVector2Array([Vector2(-64,-896),Vector2(64,-896),Vector2(64,896),Vector2(-64,896)])
			wall.position = block.position
			wall.color = Color("1e3a5a")
			art.add_child(wall)
			continue
		var left: float = block.position.x - block.size.x * 0.5
		var top: float = block.position.y - block.size.y * 0.5
		var wood := block.name in [&"StartDeck", &"RemoteDeck", &"FinishDeck"]
		var asset_id := "timber_deck" if wood else "stone_cap_long"
		if not wood and block.size.x <= 384:
			asset_id = "stone_cap_short"
		var source_width := 256.0 if asset_id == "stone_cap_short" else 512.0
		_place(asset_id, Vector2(left, top), Vector2(block.size.x / source_width, 1.0), 2)
		var post_height: float = maxf(80.0, 800.0 - top - 48.0)
		for x in [left + 40.0, left + block.size.x - 40.0]:
			_place("support_post", Vector2(x, top + 48.0), Vector2(0.8, post_height / 384.0), -6)
		if block.size.x >= 384:
			_place("curved_brace", Vector2(left + 28, top + 45), Vector2(0.8, 0.8), -5)
		_place("grass_clump", Vector2(left + 30, top), Vector2(0.45,0.45), 3)
	for bulb in $Bulbs.get_children():
		bulb.self_modulate.a = 0.0
		var visual := BULB_VISUAL.new()
		visual.name = str(bulb.name) + "Art"
		art.add_child(visual)
		visual.setup(bulb)
		# The bulb render's stem tip is above-left of its water center.
		var bulb_pixels_per_unit: float = bulb.size.x / 1.9
		var stem_tip: Vector2 = bulb.position + Vector2(-1.5, -2.33) * bulb_pixels_per_unit
		var hanger_origin := stem_tip - Vector2(2.02 * 128.0, -0.50 * 128.0)
		_place("bulb_hanger", hanger_origin, Vector2.ONE, -4)
		var support_top := hanger_origin + Vector2(12.8, 134.4)
		_place("support_post", support_top, Vector2(0.75, (800.0 - support_top.y) / 384.0), -6)
	_place("dry_channel", Vector2(3240, 734), Vector2(1.4,1.4), -5)
	_place("stopped_waterwheel", Vector2(3550, 557), Vector2(1.05,1.05), -7)
	_place("cloth_awning", Vector2(335, 586), Vector2(1.0,1.0), -4)
	_place("cloth_awning", Vector2(3750, 555), Vector2(1.0,1.0), -4)
	_place("cherry_cluster", Vector2(-50, 50), Vector2(2.0,2.0), -4)
	_place("cherry_cluster", Vector2(4700, 150), Vector2(2.0,2.0), -4)
	for x in [-190, 2190, 4650]:
		_place("shore_stone", Vector2(x, 908), Vector2(0.75,0.75), 5)
		_place("cherry_cluster", Vector2(x + 80, 862), Vector2(0.55,0.55), 6)
	_update_parallax()

func _place(id: String, at: Vector2, sizing: Vector2, depth: int) -> Node2D:
	var packed := load(KIT + id + ".tscn") as PackedScene
	var piece := packed.instantiate() as Node2D
	piece.position = at
	piece.scale = sizing
	piece.z_index = depth
	art.add_child(piece)
	return piece

func _build_background() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "TwoLayerParallax"
	canvas.layer = -50
	add_child(canvas)
	var fill := ColorRect.new()
	fill.color = Color("74c7ed")
	fill.size = Vector2(1920,1080)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fill)
	far_layer = Sprite2D.new()
	far_layer.name = "FarSkyCliffs"
	far_layer.texture = load("res://Assets/BlueBiome/StillVillage/Backgrounds/far_sky_cliffs.png")
	far_layer.scale = Vector2(2.3,2.3)
	canvas.add_child(far_layer)
	lake_fill = ColorRect.new()
	lake_fill.name = "LakeLowerFill"
	lake_fill.color = Color("67b9cf")
	lake_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lake_fill)
	near_layer = Sprite2D.new()
	near_layer.name = "NearLakeVillage"
	near_layer.texture = load("res://Assets/BlueBiome/StillVillage/Backgrounds/near_lake_village.png")
	near_layer.scale = Vector2(1.3,1.3)
	near_layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	near_layer.region_enabled = true
	near_layer.region_rect = Rect2(Vector2.ZERO, near_layer.texture.get_size() * Vector2(3,1))
	var material := ShaderMaterial.new()
	material.shader = load("res://Assets/BlueBiome/StillVillage/Backgrounds/still_village_distance.gdshader")
	near_layer.material = material
	canvas.add_child(near_layer)

func _process(_delta: float) -> void:
	_update_parallax()

func _update_parallax() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null or far_layer == null:
		return
	var center := camera.get_screen_center_position()
	far_layer.position = Vector2(1100,100) - center * Vector2(0.10,0.04)
	near_layer.position = Vector2(1450,350) - center * Vector2(0.26,0.08)
	var waterline := near_layer.position.y + near_layer.texture.get_height() * 1.3 * 0.11
	lake_fill.position = Vector2(0,waterline)
	lake_fill.size = Vector2(1920,maxf(0.0,1080-waterline))
