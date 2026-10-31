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
		source.size.y = minf(source.size.y,float(PROFILES[stamp].walk_y)+80.0)
		target.size.y = source.size.y*unit
		draw_texture_rect_region(source_texture(),target,source)
	if structure == Structure.PONTOON:
		for x in [span_width*0.13,span_width*0.5,span_width*0.87]:
			for offset in [-2.0,2.0]:
				draw_line(Vector2(x+offset,12),Vector2(x+offset,waterline_offset+16),FLAX,1.3,true)

func _wood(points: PackedVector2Array, tint: Color) -> void:
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	var uvs := PackedVector2Array()
	for point in points:
		var uv := (point-bounds.position)/bounds.size.max(Vector2(0.01,0.01))
		uvs.append((GRAIN.position+uv*GRAIN.size)/TIMBER.get_size())
	draw_polygon(points,PackedColorArray([tint]),uvs,TIMBER)
	var edge := points.duplicate()
	edge.append(points[0])
	draw_polyline(edge,EDGE,2.0,true)

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
