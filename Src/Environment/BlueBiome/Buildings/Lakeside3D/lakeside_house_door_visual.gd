extends Node2D
## Reusable opening panels and an unobtrusive interior exit cue.
const WOOD := preload("res://Assets/BlueBiome/Art/Lakeside3D/Textures/walnut_BaseColor_4K.png")
var opening := 0.0
var indoors := false
var threshold := 0.0
var time := 0.0

func _ready() -> void:
	z_as_relative = false
	z_index = -8
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var base := Vector2(0,threshold)
	var doorway := Rect2(base+Vector2(-77,-218),Vector2(154,218))
	if opening > 0.001:
		draw_rect(doorway,Color(.025,.035,.045,opening))
		var width := 77.0*cos(opening*PI*.48)
		for side in [-1,1]:
			var panel := Rect2(Vector2(doorway.position.x if side<0 else doorway.end.x-width,doorway.position.y),Vector2(width,doorway.size.y))
			draw_texture_rect_region(WOOD,panel,Rect2(600 if side<0 else 1400,400,800,2400),Color(.75,.63,.47,opening))
			draw_rect(panel,Color(.12,.08,.045,opening),false,3)
	if indoors or opening > 0.001:
		var glow := Color(.95,.65,.25,.10+.025*sin(time*1.7))
		draw_colored_polygon(PackedVector2Array([base+Vector2(-64,0),base+Vector2(64,0),base+Vector2(96,15),base+Vector2(-96,15)]),glow)
		draw_rect(doorway,Color(.95,.68,.32,.36 if indoors else .22),false,2)
		draw_line(base+Vector2(-58,-2),base+Vector2(58,-2),Color(1,.77,.42,.6),3,true)
		draw_circle(base+Vector2(54,-105),3.5,Color(1,.77,.42,.7))
