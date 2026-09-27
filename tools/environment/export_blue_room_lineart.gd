@tool
extends SceneTree

const SOURCE_SCENE := "res://Src/Environment/BlueBiome/Production/blue_chamber_exit_production.tscn"
const OUTPUT_DIR := "res://ArtSource/BlueBiome/ChamberExitRooftops/LineArtGuide"
const TILE_SIZE := 128
const PADDING := 128


func _initialize() -> void:
	var packed := load(SOURCE_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load %s" % SOURCE_SCENE)
		quit(1)
		return

	var room := packed.instantiate()
	root.add_child(room)
	var terrain := room.get_node_or_null("Geometry/GreyboxTerrain") as TileMapLayer
	if terrain == null:
		push_error("GreyboxTerrain was not found")
		quit(1)
		return

	var cells := terrain.get_used_cells()
	if cells.is_empty():
		push_error("GreyboxTerrain contains no cells")
		quit(1)
		return

	var min_cell := cells[0]
	var max_cell := cells[0]
	var occupied := {}
	for cell in cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
		occupied[cell] = true

	var world_min := Vector2(min_cell * TILE_SIZE) - Vector2(PADDING, PADDING)
	var world_max := Vector2((max_cell + Vector2i.ONE) * TILE_SIZE) + Vector2(PADDING, PADDING)
	var canvas_size := Vector2i(world_max - world_min)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	_write_svg("%s/01_collision_mass_and_contour.svg" % OUTPUT_DIR, _build_collision_svg(cells, occupied, world_min, canvas_size))
	_write_svg("%s/02_water_guide.svg" % OUTPUT_DIR, _build_water_svg(room, world_min, canvas_size))
	_write_svg("%s/03_markers_and_scale.svg" % OUTPUT_DIR, _build_marker_svg(room, world_min, canvas_size))
	_write_svg("%s/04_room_master_guide.svg" % OUTPUT_DIR, _build_master_svg(room, cells, occupied, world_min, canvas_size))
	_render_png("%s/01_collision_mass_and_contour.svg" % OUTPUT_DIR, "%s/01_collision_mass_and_contour.png" % OUTPUT_DIR, canvas_size)
	_render_png("%s/02_water_guide.svg" % OUTPUT_DIR, "%s/02_water_guide.png" % OUTPUT_DIR, canvas_size)
	_render_png("%s/03_markers_and_scale.svg" % OUTPUT_DIR, "%s/03_markers_and_scale.png" % OUTPUT_DIR, canvas_size)
	_render_png("%s/04_room_master_guide.svg" % OUTPUT_DIR, "%s/04_room_master_guide.png" % OUTPUT_DIR, canvas_size)
	var background := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	background.fill(Color("f5f1e8"))
	background.save_png("%s/00_painting_background.png" % OUTPUT_DIR)
	print("LINEART_EXPORT_OK size=%sx%s origin=(%s,%s) cells=%s" % [canvas_size.x, canvas_size.y, world_min.x, world_min.y, cells.size()])
	quit()


func _svg_header(size: Vector2i, background := "none") -> String:
	var backdrop := ""
	if background != "none":
		backdrop = '<rect width="100%%" height="100%%" fill="%s"/>\n' % background
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">\n%s' % [size.x, size.y, size.x, size.y, backdrop]


func _build_collision_svg(cells: Array[Vector2i], occupied: Dictionary, origin: Vector2, size: Vector2i) -> String:
	var svg := _svg_header(size)
	svg += '<g id="terrain-mass" fill="#101820" fill-opacity="0.42" stroke="none">\n'
	for cell in cells:
		var p := Vector2(cell * TILE_SIZE) - origin
		svg += '<rect x="%s" y="%s" width="%s" height="%s"/>\n' % [p.x, p.y, TILE_SIZE, TILE_SIZE]
	svg += '</g>\n<g id="gameplay-contour" fill="none" stroke="#101820" stroke-width="12" stroke-linecap="round" stroke-linejoin="round">\n'
	for cell in cells:
		var p := Vector2(cell * TILE_SIZE) - origin
		if not occupied.has(cell + Vector2i.UP):
			svg += _wavy_edge(p, p + Vector2(TILE_SIZE, 0), cell, true)
		if not occupied.has(cell + Vector2i.DOWN):
			svg += _wavy_edge(p + Vector2(0, TILE_SIZE), p + Vector2(TILE_SIZE, TILE_SIZE), cell, true)
		if not occupied.has(cell + Vector2i.LEFT):
			svg += _wavy_edge(p, p + Vector2(0, TILE_SIZE), cell, false)
		if not occupied.has(cell + Vector2i.RIGHT):
			svg += _wavy_edge(p + Vector2(TILE_SIZE, 0), p + Vector2(TILE_SIZE, TILE_SIZE), cell, false)
	svg += '</g>\n</svg>\n'
	return svg


func _wavy_edge(a: Vector2, b: Vector2, cell: Vector2i, horizontal: bool) -> String:
	var seed_value: int = absi(cell.x * 73856093 ^ cell.y * 19349663 ^ (1 if horizontal else 2))
	var points := PackedVector2Array()
	for index in range(5):
		var t := float(index) / 4.0
		var point := a.lerp(b, t)
		if index > 0 and index < 4:
			var jitter := float((seed_value >> (index * 3)) % 13) - 6.0
			if horizontal:
				point.y += jitter
			else:
				point.x += jitter
		points.append(point)
	var data := "M %s %s" % [points[0].x, points[0].y]
	for index in range(1, points.size()):
		data += " L %s %s" % [points[index].x, points[index].y]
	return '<path d="%s"/>\n' % data


func _build_water_svg(room: Node, origin: Vector2, size: Vector2i) -> String:
	var svg := _svg_header(size)
	svg += '<g id="water-guide" fill="#32c8ef" fill-opacity="0.22" stroke="#00a8d6" stroke-width="8">\n'
	var water_root := room.get_node_or_null("WaterVolumes")
	if water_root:
		for water in water_root.get_children():
			var water_size: Vector2 = water.get("size") if water.get("size") != null else Vector2(512, 256)
			var scaled_size: Vector2 = water_size * (water as Node2D).scale.abs()
			var top_left: Vector2 = (water as Node2D).position - scaled_size * 0.5 - origin
			svg += '<rect x="%s" y="%s" width="%s" height="%s"/>\n' % [top_left.x, top_left.y, scaled_size.x, scaled_size.y]
	svg += '</g>\n</svg>\n'
	return svg


func _build_marker_svg(room: Node, origin: Vector2, size: Vector2i) -> String:
	var svg := _svg_header(size)
	svg += '<g id="scale-guides" fill="none" stroke="#ff3aa7" stroke-width="6">\n'
	var player := room.get_node_or_null("Player")
	if player:
		var p: Vector2 = (player as Node2D).position - origin
		svg += '<rect x="%s" y="%s" width="96" height="192"/>\n' % [p.x - 48, p.y - 192]
		svg += '<text x="%s" y="%s" fill="#ff3aa7" stroke="none" font-family="sans-serif" font-size="38">PLAYER SCALE</text>\n' % [p.x + 64, p.y - 80]
	var markers := room.get_node_or_null("Markers")
	if markers:
		for marker in markers.get_children():
			if marker is Marker2D:
				var m: Vector2 = (marker as Marker2D).position - origin
				svg += '<circle cx="%s" cy="%s" r="24"/>\n' % [m.x, m.y]
				svg += '<text x="%s" y="%s" fill="#ff3aa7" stroke="none" font-family="sans-serif" font-size="34">%s</text>\n' % [m.x + 36, m.y + 10, marker.name]
	svg += '</g>\n</svg>\n'
	return svg


func _build_master_svg(room: Node, cells: Array[Vector2i], occupied: Dictionary, origin: Vector2, size: Vector2i) -> String:
	var collision := _strip_svg(_build_collision_svg(cells, occupied, origin, size))
	var water := _strip_svg(_build_water_svg(room, origin, size))
	var markers := _strip_svg(_build_marker_svg(room, origin, size))
	return _svg_header(size, "#f5f1e8") + collision + water + markers + '</svg>\n'


func _strip_svg(source: String) -> String:
	var start := source.find(">\n") + 2
	var finish := source.rfind("</svg>")
	return source.substr(start, finish - start)


func _write_svg(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % path)
		return
	file.store_string(content)


func _render_png(svg_path: String, png_path: String, size: Vector2i) -> void:
	var svg_text := FileAccess.get_file_as_string(svg_path)
	var image := Image.new()
	var error := image.load_svg_from_string(svg_text, 1.0)
	if error != OK:
		push_error("Could not render SVG: %s" % error)
		return
	image.save_png(png_path)
