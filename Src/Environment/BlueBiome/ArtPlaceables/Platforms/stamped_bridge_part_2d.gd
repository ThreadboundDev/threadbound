@tool
extends "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/walkway_stamp_2d.gd"
## Independently placeable art parts. Origin is the left end of the walk plane.
enum Part { DECK, RAIL, PONTOONS, BRACES }
const RAIL_SHADER := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/bridge_rail_cutout.gdshader")
const TIMBER := preload("res://Assets/BlueBiome/Art/WalkwayStamps/B04_Simple_Plank_Crossing.png")
const GRAIN := Rect2(300,151,240,38)
const EDGE := Color(.10,.085,.065,.95)
const IRON := Color(.17,.24,.26)
const FLAX := Color(.69,.59,.40)
@export var part: Part = Part.DECK
@export var rock_inset_left := 0.0
@export var rock_inset_right := 0.0
@export_range(0.0,0.8) var open_center := 0.0
@export var waterline_offset := 27.0
@export var support_anchor := Vector2(-50,240)
var _signature := 0
func _ready() -> void: _refresh()
func _process(_delta: float) -> void: _refresh()
func _refresh() -> void:
	var signature := hash([part,stamp,span_width,detail_scale,rock_inset_left,rock_inset_right,open_center,waterline_offset,support_anchor])
	if signature == _signature: return
	_signature = signature
	if part == Part.RAIL and not material:
		var cutout := ShaderMaterial.new()
		cutout.shader = RAIL_SHADER
		material = cutout
	elif part != Part.RAIL:
		material = null
	queue_redraw()
func exposed_span() -> Vector2:
	return Vector2(minf(rock_inset_left,span_width),maxf(rock_inset_left,span_width-rock_inset_right))
func _draw() -> void:
	match part:
		Part.DECK: _deck()
		Part.RAIL: _rails()
		Part.PONTOONS: _pontoons()
		Part.BRACES: _braces()
func _region(texture: Texture2D, source: Rect2, target: Rect2, start: float, end: float) -> void:
	var left := maxf(target.position.x,start)
	var right := minf(target.end.x,end)
	if right <= left: return
	var unit := target.size.x/source.size.x
	source.position.x += (left-target.position.x)/unit
	source.size.x = (right-left)/unit
	target.position.x = left
	target.size.x = right-left
	draw_texture_rect_region(texture,target,source)
func _deck() -> void:
	var span := exposed_span()
	for section: Dictionary in get_draw_sections():
		var source: Rect2 = section.source
		var target: Rect2 = section.target
		var unit := target.size.y/source.size.y
		var top: float = maxf(source.position.y,float(PROFILES[stamp].walk_y)-28.0)
		target.position.y += (top-source.position.y)*unit
		source.size.y -= top-source.position.y
		source.position.y = top
		source.size.y = minf(source.size.y,float(PROFILES[stamp].walk_y)+80.0-top)
		target.size.y = source.size.y*unit
		_region(source_texture(),source,target,span.x,span.y)
func _rails() -> void:
	var span := exposed_span()
	var width := span.y-span.x
	if width < 72: return
	var intervals := [span]
	if open_center > 0.0:
		var side := width*(1.0-open_center)*.5
		intervals = [Vector2(span.x,span.x+side),Vector2(span.y-side,span.y)]
	for interval: Vector2 in intervals:
		for section: Dictionary in get_draw_sections_for(interval.y-interval.x,Stamp.RAILED_VERANDA,detail_scale):
			var source: Rect2 = section.source
			var target: Rect2 = section.target
			var unit := target.size.y/source.size.y
			source.size.y = 228.0
			target.position = Vector2(target.position.x+interval.x,-228.0*unit)
			target.size.y = 228.0*unit
			draw_texture_rect_region(PROFILES[Stamp.RAILED_VERANDA].texture,target,source)
func _wood(points: PackedVector2Array, tint: Color) -> void:
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	var uvs := PackedVector2Array()
	for point in points:
		var uv := (point-bounds.position)/bounds.size.max(Vector2(.01,.01))
		uvs.append((GRAIN.position+uv*GRAIN.size)/TIMBER.get_size())
	draw_polygon(points,PackedColorArray([tint]),uvs,TIMBER)
	var edge := points.duplicate()
	edge.append(points[0])
	draw_polyline(edge,EDGE,2.0,true)
func _beam(a: Vector2,b: Vector2,width: float,tint: Color) -> void:
	if a.distance_to(b)<.5: return
	var normal := (b-a).normalized().orthogonal()*width*.5
	_wood(PackedVector2Array([a+normal,b+normal,b-normal,a-normal]),tint)
	for point in [a.lerp(b,.07),a.lerp(b,.93)]:
		draw_circle(point,3.3,IRON)
		draw_circle(point+Vector2(-.5,-.7),1.0,Color(.68,.67,.55))
func _pontoons() -> void:
	_float_body(Rect2(-6,waterline_offset-19,span_width+12,33),Color(.67,.72,.73))
	_float_body(Rect2(-15,waterline_offset-10,span_width+30,40),Color.WHITE)
	for x in [span_width*.13,span_width*.5,span_width*.87]:
		_beam(Vector2(x,9),Vector2(x,waterline_offset-8),12,Color(.85,.85,.8))
		for offset in [-2.0,2.0]:
			draw_line(Vector2(x+offset,12),Vector2(x+offset,waterline_offset+16),FLAX,1.3,true)
func _float_body(rect: Rect2,tint: Color) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	_wood(PackedVector2Array([Vector2(x,y+h*.45),Vector2(x+10,y+4),Vector2(x+26,y),Vector2(x+w-26,y),Vector2(x+w-8,y+5),Vector2(x+w,y+h*.48),Vector2(x+w-10,y+h-3),Vector2(x+w-28,y+h),Vector2(x+25,y+h),Vector2(x+8,y+h-4)]),tint)
	draw_line(Vector2(x+23,y+h*.60),Vector2(x+w-22,y+h*.60),Color(.10,.08,.055,.55),1.5,true)
	for band in [.14,.5,.86]:
		var center: float = x+w*float(band)
		draw_rect(Rect2(center-3,y+1,6,h-2),IRON)
		draw_line(Vector2(center-1,y+3),Vector2(center-1,y+h-4),Color(.48,.53,.50),1,true)
		draw_circle(Vector2(center,y+h*.5),1.7,FLAX)
func _braces() -> void:
	_beam(Vector2(span_width*.13,12),support_anchor,18,Color(.78,.80,.78))
	_beam(Vector2(span_width*.87,12),support_anchor,21,Color.WHITE)
	_beam(Vector2(0 if support_anchor.x<span_width*.5 else span_width,12),support_anchor,21,Color(.88,.87,.81))
	draw_rect(Rect2(support_anchor-Vector2(15,11),Vector2(30,22)),IRON)
	draw_rect(Rect2(support_anchor-Vector2(15,11),Vector2(30,22)),EDGE,false,2)
	for x in [-9.0,9.0]: draw_circle(support_anchor+Vector2(x,0),2.2,FLAX)
