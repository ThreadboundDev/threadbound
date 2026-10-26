extends Node
## One occupied house frames its interior; cleanly restores the user's camera.
const SHADER := preload("res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_house_focus.gdshader")
var house: Node2D
var player: CharacterBody2D
var camera: Camera2D
var saved := {}
var weight := 0.0
var occupied := false
var overlay: CanvasLayer
var effect: ColorRect
var capture: BackBufferCopy

func _ready() -> void:
	process_priority = 110
	house = get_parent()
	overlay = CanvasLayer.new()
	overlay.name = "InteriorFocusOverlay"
	overlay.layer = 5
	add_child(overlay)
	capture = BackBufferCopy.new()
	capture.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	overlay.add_child(capture)
	effect = ColorRect.new()
	effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	effect.material = material
	overlay.add_child(effect)
	overlay.visible = false
	capture.copy_mode = BackBufferCopy.COPY_MODE_DISABLED

func enter(actor: CharacterBody2D) -> void:
	if occupied:
		return
	player = actor
	camera = player.get_node_or_null("Camera2D") as Camera2D
	if not is_instance_valid(camera):
		return
	if saved.is_empty():
		saved = {"position":camera.position,"zoom":camera.zoom,"left":camera.limit_left,"top":camera.limit_top,"right":camera.limit_right,"bottom":camera.limit_bottom}
		camera.set_meta("lakeside_focus_owner",self)
	occupied = true

func leave(immediate := false) -> void:
	occupied = false
	if immediate:
		weight = 0.0
		_restore()

func _process(delta: float) -> void:
	if saved.is_empty():
		return
	if not is_instance_valid(camera) or not is_instance_valid(player):
		_restore()
		return
	weight = move_toward(weight,1.0 if occupied else 0.0,delta/0.42)
	var blend := smoothstep(0.0,1.0,weight)
	var bounds: Rect2 = house.global_transform * house.entry_rect
	bounds = bounds.grow(24)
	var screen := house.get_viewport_rect().size
	# Fit the entire room with a modest zoom. Small rooms hold a fixed center;
	# the exterior outside their bounds is visually de-emphasized by the mask.
	var zoom := minf(screen.x/(bounds.size.x+80),screen.y/(bounds.size.y+80))
	zoom = clampf(zoom,saved.zoom.x,saved.zoom.x*1.65)
	camera.zoom = saved.zoom.lerp(Vector2.ONE*zoom,blend)
	camera.position = saved.position.lerp(bounds.get_center()-player.global_position,blend)
	var half := screen/(zoom*2.0)
	var limits := Rect2(bounds.get_center()-half,half*2.0).merge(bounds)
	camera.limit_left = roundi(lerpf(saved.left,limits.position.x,blend))
	camera.limit_top = roundi(lerpf(saved.top,limits.position.y,blend))
	camera.limit_right = roundi(lerpf(saved.right,limits.end.x,blend))
	camera.limit_bottom = roundi(lerpf(saved.bottom,limits.end.y,blend))
	overlay.visible = weight > 0.0
	capture.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if weight > 0.0 else BackBufferCopy.COPY_MODE_DISABLED
	var canvas := house.get_viewport().get_canvas_transform()
	var a := canvas * bounds.position
	var b := canvas * bounds.end
	effect.material.set_shader_parameter("room_screen_rect",Vector4(a.x,a.y,b.x,b.y))
	effect.material.set_shader_parameter("focus_strength",blend)
	if not occupied and weight == 0.0:
		_restore()

func _restore() -> void:
	if not saved.is_empty() and is_instance_valid(camera) and camera.has_meta("lakeside_focus_owner") and camera.get_meta("lakeside_focus_owner") == self:
		camera.position = saved.position
		camera.zoom = saved.zoom
		camera.limit_left = saved.left
		camera.limit_top = saved.top
		camera.limit_right = saved.right
		camera.limit_bottom = saved.bottom
		camera.remove_meta("lakeside_focus_owner")
	saved.clear()
	if is_instance_valid(overlay):
		overlay.visible = false
		capture.copy_mode = BackBufferCopy.COPY_MODE_DISABLED

func _exit_tree() -> void:
	_restore()
