extends SceneTree
## Explicit authoring tool, never runs in-game or overwrites manual edits on load.
## Input is the exported solid-rock mask, with supports/backdrop excluded.
const MASK := "res://work/krita-map-import/rock_mask.png"
const OUT := "res://Src/Environment/BlueBiome/Prototypes/Rooms/lakeside_rock_collision.tscn"
const SECTION_SIZE := 1024
var sections: Array[Dictionary] = []
var rejected: Array[Dictionary] = []

func smooth_short_edges(input: PackedVector2Array, size: Vector2i) -> PackedVector2Array:
	# Marching squares can retain 1px vertical connectors after RDP. A single
	# such connector presents a wall normal to a rectangular player collider.
	# Collapse short edges into the neighboring ramp. Preserve section anchors
	# so adjacent pieces still meet exactly along their shared clipping line.
	var points: Array[Vector2] = []
	for point in input:
		points.append(point)
	var changed := true
	while changed and points.size() > 3:
		changed = false
		for i in points.size():
			var j := (i+1)%points.size()
			var a := points[i]
			var b := points[j]
			if a.distance_squared_to(b) > 36.0:
				continue
			var anchor_a := a.x == 0 or a.y == 0 or a.x == size.x or a.y == size.y
			var anchor_b := b.x == 0 or b.y == 0 or b.x == size.x or b.y == size.y
			if anchor_a and anchor_b:
				continue
			var merged := a if anchor_a else (b if anchor_b else (a+b)*0.5)
			if j == 0:
				points[0] = merged
				points.remove_at(i)
			else:
				points[i] = merged
				points.remove_at(j)
			changed = true
			break
	return PackedVector2Array(points)

func _initialize() -> void:
	var source := Image.load_from_file(MASK)
	if source == null:
		push_error("Prepare rock_mask.png from the saved Krita rock layers first")
		quit(1)
		return
	var body := StaticBody2D.new()
	body.name = "RockCollision"
	body.position = Vector2(-1408,-2560)
	body.collision_layer = 1
	body.collision_mask = 0
	body.editor_description = "Editable rock outlines: rounded over an 8px radius, inset 4px, simplified by 5px. Select an Outline child and edit its polygon points. Rear timber and the recessed cave face do not collide. The original TileMap collision is disabled. Regeneration is an explicit authoring operation."
	# Small sections avoid filling caves/tunnels as interior holes in an outline.
	for y in range(0,source.get_height(),SECTION_SIZE):
		for x in range(0,source.get_width(),SECTION_SIZE):
			var rect := Rect2i(x,y,mini(SECTION_SIZE,source.get_width()-x),mini(SECTION_SIZE,source.get_height()-y))
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(source.get_region(rect),0.5)
			for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,rect.size),5.0):
				polygon = smooth_short_edges(polygon,rect.size)
				var area := 0.0
				for i in polygon.size():
					area += polygon[i].cross(polygon[(i+1)%polygon.size()])
				if absf(area)*0.5 < 100.0:
					continue
				if Geometry2D.triangulate_polygon(polygon).is_empty():
					rejected.append({"section":str(rect),"points":polygon.size()})
					continue
				var outline := CollisionPolygon2D.new()
				outline.name = "Outline_%02d_%02d_%02d" % [x/SECTION_SIZE,y/SECTION_SIZE,sections.size()]
				outline.position = Vector2(rect.position)
				outline.polygon = polygon
				body.add_child(outline)
				outline.owner = body
				var points := []
				for point in polygon:
					points.append([point.x+rect.position.x,point.y+rect.position.y])
				sections.append({"name":str(outline.name),"points":points})
	var packed := PackedScene.new()
	var code := packed.pack(body)
	if code == OK and rejected.is_empty():
		code = ResourceSaver.save(packed,OUT)
	FileAccess.open("res://work/krita-map-import/rock_contours.json",FileAccess.WRITE).store_string(JSON.stringify({"sections":sections,"rejected":rejected},"\t"))
	print("ROCK_COLLISION_POLYGONS ",sections.size()," rejected=",rejected.size()," save=",code)
	body.free()
	quit(0 if code==OK and rejected.is_empty() else 1)
