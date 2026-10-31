extends RefCounted
## Shared presentation colors and filled ribbons. No gameplay state.
const FILL := Color(0.61,0.83,0.88)
const CORE := Color(0.95,0.98,0.92)
const EDGE := Color(0.98,1.0,0.96)
const THREAD := Color("dabd82")

static func arc_ribbon(canvas: CanvasItem, radius: float, start: float, finish: float,
	width: float, flatten := Vector2.ONE, strength := 1.0) -> void:
	if radius <= 0.1 or strength <= 0.0: return
	var edge := PackedVector2Array()
	var fiber := PackedVector2Array()
	var previous := []
	for i in 49:
		var t := float(i)/48.0
		var angle := lerpf(start,finish,t)
		var axis := Vector2.from_angle(angle)*flatten
		var thickness := minf(radius*.8,width)*(.18+.82*smoothstep(0.0,.45,t))
		var outer := axis*radius
		var inner := axis*(radius-thickness)
		var cut := inner.lerp(outer,.65)
		if not previous.is_empty():
			canvas.draw_colored_polygon(PackedVector2Array([previous[0],outer,inner,previous[1]]),Color(FILL,strength*(.20+.30*t)))
			canvas.draw_colored_polygon(PackedVector2Array([previous[0],outer,cut,previous[2]]),Color(CORE,strength*(.22+.44*t)))
		previous = [outer,inner,cut]
		edge.append(outer)
		fiber.append(inner.lerp(outer,.38))
	canvas.draw_polyline(edge,Color(EDGE,.86*strength),2.6,true)
	canvas.draw_polyline(fiber,Color(THREAD,.52*strength),1.2,true)
