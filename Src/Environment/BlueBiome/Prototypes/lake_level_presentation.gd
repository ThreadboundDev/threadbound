@tool
extends Node2D
## Disposable art only. Rebuilds from the user's terrain without editing it.
@export var show_terrain_art := false
var _terrain: TileMapLayer
var _ground: TileMapLayer
var _far: Sprite2D
var _near: Sprite2D
var _refresh_timer := 0.0
var _decks: Node2D
var _cell_hash := 0
var _clouds: Node2D
var _depth_material: ShaderMaterial

func _ready() -> void:
	_build_lake_lighting()
	_terrain = get_parent().get_node_or_null("Geometry/GreyboxTerrain")
	_far = _background("FarCliffs", "far_sky_cliffs", Vector2(1900,-450), 4.5, -95)
	_near = _background("LakeVillage", "near_lake_village", Vector2(1900,212), 3.0, -90)
	var distance := ShaderMaterial.new()
	distance.shader = load("res://Assets/BlueBiome/StillVillage/Backgrounds/still_village_distance.gdshader")
	_near.material = distance
	_clouds = Node2D.new()
	_clouds.name = "OpenAirClouds"
	_clouds.z_index = -92
	add_child(_clouds)
	var kinds := ["broad", "wisp", "soft_bank", "small", "streak"]
	for i in 12:
		var cloud := load("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_"+kinds[i % kinds.size()]+".tscn").instantiate() as Sprite2D
		cloud.position = Vector2(-1800+i*650, -280-(i%3)*420)
		cloud.scale = Vector2.ONE*(0.85+(i%3)*0.2)
		cloud.modulate.a = 0.65
		cloud.set("wrap_min_x", -2600.0)
		cloud.set("wrap_max_x", 7000.0)
		cloud.set("motion_phase", float(i)*0.51)
		_clouds.add_child(cloud)
		cloud.material = cloud.material.duplicate()
		cloud.material.set_shader_parameter("clip_below_water", true)
	var deep := Polygon2D.new()
	deep.name = "UnderwaterDepth"
	deep.polygon = PackedVector2Array([Vector2(-20000,-20000),Vector2(20000,-20000),Vector2(20000,20000),Vector2(-20000,20000)])
	deep.color = Color("163d50")
	var depth_material := ShaderMaterial.new()
	depth_material.shader = load("res://Src/Environment/BlueBiome/Water/lake_depth_backdrop.gdshader")
	deep.material = depth_material
	_depth_material = depth_material
	deep.z_index = -85
	add_child(deep)
	_update_waterline()
	if not show_terrain_art:
		_terrain.self_modulate.a = 1.0
		return
	# Authored artwork is saved in the room and must never be regenerated.
	if get_parent().has_node("Geometry/TerrainArtwork"):
		_terrain.self_modulate.a = 0.0
		return
	_ground = TileMapLayer.new()
	_ground.name = "TerrainArtwork"
	_ground.collision_enabled = false
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(128,128)
	var source := TileSetAtlasSource.new()
	source.texture = load("res://Assets/BlueBiome/Art/Ground/blue_lake_slate_terrain_v2.png")
	source.texture_region_size = Vector2i(128,128)
	for y in 3:
		for x in 3:
			source.create_tile(Vector2i(x,y))
	tiles.add_source(source,0)
	_ground.tile_set = tiles
	_ground.z_index = 5
	add_child(_ground)
	_decks = Node2D.new()
	_decks.name = "DeckArtwork"
	_decks.z_index = 6
	add_child(_decks)
	_rebuild_ground()

func _background(label: String, id: String, at: Vector2, sizing: float, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = label
	sprite.texture = load("res://Assets/BlueBiome/StillVillage/Backgrounds/"+id+".png")
	sprite.position = at
	sprite.scale = Vector2.ONE*sizing
	sprite.z_index = depth
	add_child(sprite)
	return sprite

func _process(delta: float) -> void:
	_refresh_timer += delta
	if Engine.is_editor_hint() and _refresh_timer >= .5:
		_refresh_timer = 0.0
		_rebuild_ground()
		_update_waterline()
	if not Engine.is_editor_hint() and is_instance_valid(_far):
		var camera := get_viewport().get_camera_2d()
		if camera:
			var center := camera.get_screen_center_position()
			_far.position.x = 1900 + (center.x-1900)*.12
			_near.position.x = 1900 + (center.x-1900)*.04
			_clouds.position.x = (center.x-1900)*.18

func _update_waterline() -> void:
	var lake := get_parent().get_node_or_null("Volumes/Lake")
	if not lake:
		return
	var surface := INF
	for point in lake.points:
		surface = minf(surface, lake.to_global(point).y)
	if not is_finite(surface):
		return
	_depth_material.set_shader_parameter("water_surface_y", surface)
	for cloud in _clouds.get_children():
		cloud.material.set_shader_parameter("water_surface_y", surface)

func _rebuild_ground() -> void:
	if not is_instance_valid(_terrain) or not is_instance_valid(_ground):
		return
	_ground.position = _terrain.position
	_decks.position = _terrain.position
	var cells := _terrain.get_used_cells()
	var signature := hash(cells)
	for cell in cells:
		signature = hash([signature,_terrain.get_cell_atlas_coords(cell)])
	if signature == _cell_hash:
		return
	_cell_hash = signature
	_ground.clear()
	for child in _decks.get_children():
		child.free()
	for cell in cells:
		if _terrain.get_cell_atlas_coords(cell).x == 1:
			if _terrain.get_cell_atlas_coords(cell+Vector2i.LEFT).x == 1:
				continue
			var length := 1
			while _terrain.get_cell_atlas_coords(cell+Vector2i(length,0)).x == 1:
				length += 1
			var sprite := Sprite2D.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = load("res://Assets/BlueBiome/Prototype/Placeables/Platforms/village_platform_kit_keyed.png")
			atlas.region = Rect2(300,0,500,420)
			sprite.texture = atlas
			sprite.material = load("res://Assets/BlueBiome/Prototype/CodexPass/blue_chroma_key_material.tres")
			sprite.scale = Vector2(length*128.0/420.0,.65)
			sprite.position = Vector2(cell.x*128+length*64,cell.y*128+36*.65)
			_decks.add_child(sprite)
			continue
		var x := 0 if not _solid(cell+Vector2i.LEFT) else (2 if not _solid(cell+Vector2i.RIGHT) else 1)
		var y := 0 if not _solid(cell+Vector2i.UP) else (2 if not _solid(cell+Vector2i.DOWN) else 1)
		if y == 0:
			# The painted atlas has a 16px transparent top margin. Stretch the
			# visible stone to the authored surface without moving its collision.
			var cap := Sprite2D.new()
			var cap_texture := AtlasTexture.new()
			cap_texture.atlas = _ground.tile_set.get_source(0).texture
			cap_texture.region = Rect2(x*128,16,128,112)
			cap.texture = cap_texture
			cap.scale.y = 128.0/112.0
			cap.position = Vector2(cell)*128.0+Vector2(64,64)
			_decks.add_child(cap)
			continue
		_ground.set_cell(cell,0,Vector2i(x,y))
	_terrain.self_modulate.a = 0.0

func _build_lake_lighting() -> void:
	# A mild cool ambient base leaves room for warm daylight and localized
	# submerged fill. Lights are presentation-only and add no collision.
	var ambient := CanvasModulate.new()
	ambient.name = "LakeAmbient"
	ambient.color = Color(0.82, 0.89, 0.97)
	add_child(ambient)
	var sun := DirectionalLight2D.new()
	sun.name = "LakeDaylight"
	sun.range_item_cull_mask = 3
	sun.color = Color(1.0, 0.94, 0.83)
	sun.energy = 0.20
	sun.rotation_degrees = -25.0
	add_child(sun)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1.0,0.5)
	var fill := PointLight2D.new()
	fill.name = "ShallowWaterBounce"
	fill.range_item_cull_mask = 3
	fill.texture = texture
	fill.texture_scale = 3.0
	fill.position = Vector2(640,900)
	fill.color = Color(0.60,0.86,1.0)
	fill.energy = 0.24
	add_child(fill)


func _solid(cell: Vector2i) -> bool:
	return _terrain.get_cell_source_id(cell) >= 0 and _terrain.get_cell_atlas_coords(cell).x == 0

func _exit_tree() -> void:
	if is_instance_valid(_terrain):
		_terrain.self_modulate.a = 1.0
