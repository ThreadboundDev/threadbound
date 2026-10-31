@tool
extends "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/walkway_stamp_2d.gd"
## Reusable art with explicit flotation/anchorage. WalkPlane remains y=0;
## existing room collision owns gameplay. No bobbing or moving-platform logic.
enum Structure { PONTOON, BRACED }
@export var structure: Structure = Structure.PONTOON:
	set(value):
		structure = value
		queue_redraw()
@export var waterline_offset := 27.0:
	set(value):
		waterline_offset = value
		queue_redraw()
@export var support_anchor := Vector2(-50,240):
	set(value):
		support_anchor = value
		queue_redraw()
const TIMBER := preload("res://Assets/BlueBiome/Art/WalkwayStamps/B04_Simple_Plank_Crossing.png")
const GRAIN := Rect2(300,151,240,38)
const EDGE := Color(0.10,0.085,0.065,0.95)
const IRON := Color(0.17,0.24,0.26)
const FLAX := Color(0.69,0.59,0.40)
@export var rock_inset_left := 0.0:
	set(value):
		rock_inset_left = maxf(0,value)
		queue_redraw()
@export var rock_inset_right := 0.0:
	set(value):
		rock_inset_right = maxf(0,value)
		queue_redraw()
var _front_rail: Node2D

func _ready() -> void:
	# The asset owns both art passes; the level keeps its original collision.
	_front_rail = Node2D.new()
	_front_rail.name = "NearRailArtwork"
	_front_rail.z_as_relative = false
	_front_rail.z_index = 4
	add_child(_front_rail)
	_front_rail.draw.connect(func(): _draw_rail(_front_rail,true))

func exposed_span() -> Vector2:
	return Vector2(minf(rock_inset_left,span_width),maxf(rock_inset_left,span_width-rock_inset_right))

func _draw() -> void:
	if structure == Structure.PONTOON:
		_draw_pontoon(Rect2(-6,waterline_offset-19,span_width+12,33),Color(0.67,0.72,0.73))
		_draw_pontoon(Rect2(-15,waterline_offset-10,span_width+30,40),Color.WHITE)
		for x in [span_width*0.13,span_width*0.5,span_width*0.87]:
			_beam(Vector2(x,9),Vector2(x,waterline_offset-8),12.0,Color(0.85,0.85,0.80))
	else:
		# Two triangles make the load path explicit, meeting an authored rock
		# anchor. The level places that anchor inside actual solid scenery.
		_beam(Vector2(span_width*0.13,12),support_anchor,18.0,Color(0.78,0.80,0.78))
		_beam(Vector2(span_width*0.87,12),support_anchor,21.0,Color.WHITE)
		var wall_top := Vector2(0 if support_anchor.x < span_width*0.5 else span_width,12)
		_beam(wall_top,support_anchor,21.0,Color(0.88,0.87,0.81))
		_socket(support_anchor)
	# Reuse approved deck art, excluding the old short, disconnected piles.
	for section: Dictionary in get_draw_sections():
		var source: Rect2 = section.source
		var target: Rect2 = section.target
		var unit := target.size.y/source.size.y
		# Keep the original floor boards; replace the tiny baked rails with
		# character-scale rails on separate rear/foreground art passes.
		var top: float = maxf(source.position.y,float(PROFILES[stamp].walk_y)-28.0)
		target.position.y += (top-source.position.y)*unit
		source.size.y -= top-source.position.y
		source.position.y = top
		source.size.y = minf(source.size.y,float(PROFILES[stamp].walk_y)+80.0-top)
		target.size.y = source.size.y*unit
		var exposed := exposed_span()
		var start := maxf(target.position.x,exposed.x)
		var end := minf(target.end.x,exposed.y)
		if end <= start: continue
		source.position.x += (start-target.position.x)/unit
		source.size.x = (end-start)/unit
		target.position.x = start
		target.size.x = end-start
		draw_texture_rect_region(source_texture(),target,source)
	_draw_rail(self,false)
	if is_instance_valid(_front_rail): _front_rail.queue_redraw()
	if structure == Structure.PONTOON:
		for x in [span_width*0.13,span_width*0.5,span_width*0.87]:
			for offset in [-2.0,2.0]:
				draw_line(Vector2(x+offset,12),Vector2(x+offset,waterline_offset+16),FLAX,1.3,true)

func _wood(points: PackedVector2Array, tint: Color) -> void:
	_wood_on(self,points,tint)

func _wood_on(canvas: Node2D, points: PackedVector2Array, tint: Color) -> void:
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	var uvs := PackedVector2Array()
	for point in points:
		var uv := (point-bounds.position)/bounds.size.max(Vector2(0.01,0.01))
		uvs.append((GRAIN.position+uv*GRAIN.size)/TIMBER.get_size())
	canvas.draw_polygon(points,PackedColorArray([tint]),uvs,TIMBER)
	var edge := points.duplicate()
	edge.append(points[0])
	canvas.draw_polyline(edge,EDGE,2.0,true)

func _draw_rail(canvas: Node2D, front: bool) -> void:
	var span := exposed_span()
	var width := span.y-span.x
	if width < 80: return
	var intervals := [Vector2(span.x+5,span.y-5)]
	if front:
		intervals = [Vector2(span.x+5,span.x+width*.24),Vector2(span.y-width*.24,span.y-5)]
	for interval: Vector2 in intervals:
		var height := 68.0 if front else 88.0
		var tint := Color(1.10,1.05,0.94) if front else Color(1.40,1.33,1.18)
		var count := maxi(1,ceili((interval.y-interval.x)/150.0))
		for i in count+1:
			var x := lerpf(interval.x,interval.y,float(i)/count)
			_wood_on(canvas,PackedVector2Array([Vector2(x-5,8),Vector2(x-5,-height-8),Vector2(x+5,-height-8),Vector2(x+5,8)]),tint)
			canvas.draw_line(Vector2(x-3,-height-5),Vector2(x-3,4),Color(0.65,0.57,0.42,0.65),1.3,true)
			for binding in 3:
				canvas.draw_line(Vector2(x-6,-height+8+binding*3),Vector2(x+6,-height+8+binding*3),FLAX,1.6,true)
		for y in [-height,-height*.37]:
			_wood_on(canvas,PackedVector2Array([Vector2(interval.x-6,y-4),Vector2(interval.y+6,y-4),Vector2(interval.y+6,y+4),Vector2(interval.x-6,y+4)]),tint)
			canvas.draw_line(Vector2(interval.x-4,y-3),Vector2(interval.y+4,y-3),Color(0.69,0.61,0.44,0.65),1.4,true)

func _beam(a: Vector2,b: Vector2,width: float,tint: Color) -> void:
	if a.distance_to(b)<0.5: return
	var normal := (b-a).normalized().orthogonal()*width*0.5
	_wood(PackedVector2Array([a+normal,b+normal,b-normal,a-normal]),tint)
	for point in [a.lerp(b,0.07),a.lerp(b,0.93)]:
		draw_circle(point,3.3,IRON)
		draw_circle(point+Vector2(-0.5,-0.7),1.0,Color(0.68,0.67,0.55))

func _draw_pontoon(rect: Rect2,tint: Color) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	var points := PackedVector2Array([Vector2(x,y+h*.45),Vector2(x+10,y+4),Vector2(x+26,y),
		Vector2(x+w-26,y),Vector2(x+w-8,y+5),Vector2(x+w,y+h*.48),
		Vector2(x+w-10,y+h-3),Vector2(x+w-28,y+h),Vector2(x+25,y+h),Vector2(x+8,y+h-4)])
	_wood(points,tint)
	draw_line(Vector2(x+23,y+h*.60),Vector2(x+w-22,y+h*.60),Color(0.10,0.08,0.055,0.55),1.5,true)
	for band in [0.14,0.50,0.86]:
		var center: float = x+w*float(band)
		draw_rect(Rect2(center-3,y+1,6,h-2),IRON)
		draw_line(Vector2(center-1,y+3),Vector2(center-1,y+h-4),Color(0.48,0.53,0.50),1.0,true)
		draw_circle(Vector2(center,y+h*.5),1.7,FLAX)

func _socket(point: Vector2) -> void:
	draw_rect(Rect2(point-Vector2(15,11),Vector2(30,22)),IRON)
	draw_rect(Rect2(point-Vector2(15,11),Vector2(30,22)),EDGE,false,2.0)
	for x in [-9.0,9.0]:
		draw_circle(point+Vector2(x,0),2.2,FLAX)

func _get_configuration_warnings() -> PackedStringArray:
	if structure == Structure.BRACED and support_anchor.y <= 15.0:
		return ["Place Support Anchor below the deck, inside the rock/building that carries it."]
	return []
