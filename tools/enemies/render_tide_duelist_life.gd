extends Node2D
## GPU contact sheet: original still, living hover, streamlined dash tail-beat.
const VISUAL = preload("res://Src/Enemies/TideDuelist/tide_duelist_visual.gd")

func _ready() -> void:
	call_deferred("render_review")

func render_review() -> void:
	var visual := Node2D.new()
	visual.set_script(VISUAL)
	add_child(visual)
	visual.set_process(false)
	visual._phase_offset = 0.0
	var viewport := visual.get_node("FishRender") as SubViewport
	var sheet := Image.create(2048, 960, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.035, 0.10, 0.16))
	var clips := [&"still", &"life/hover", &"life/dash_glide"]
	for row in 3:
		var clip: StringName = clips[row]
		visual.animator.play(clip, 0.0)
		visual.animator.pause()
		var duration: float = visual.animator.get_animation(clip).length
		for sample in 4:
			var time := float(sample) / 4.0 * duration
			visual.animator.seek(time, true)
			visual._life_clock = time
			visual._hover_weight = 1.0 if row == 1 else 0.0
			visual._apply_hover_pose()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var frame := viewport.get_texture().get_image()
			frame.convert(Image.FORMAT_RGBA8)
			sheet.blend_rect(frame, Rect2i(0, 0, 512, 320), Vector2i(sample * 512, row * 320))
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "user://tide_duelist_life_review.png"
	assert(sheet.save_png(output) == OK)
	print("TIDE_LIFE_RENDER_PASS ", output)
	get_tree().quit()
