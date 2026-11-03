extends SceneTree
## Compare the texture-free clock with Godot's native sprite clock, using the
## exact captured clip metadata and placeholder textures instead of legacy art.
const Clock := preload("res://Src/Characters/Player/player_animation_clock.gd")
var checks := 0
var failed := 0
var details: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		if details.size()<30: details.append(message)
func run() -> void:
	var clock := Clock.new()
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var texture := PlaceholderTexture2D.new()
	texture.size = Vector2(8,8)
	for name in clock.get_animation_names():
		frames.add_animation(name)
		frames.set_animation_speed(name,clock.get_animation_speed(name))
		frames.set_animation_loop(name,clock.get_animation_loop(name))
		for index in clock.get_frame_count(name):
			frames.add_frame(name,texture,clock.get_frame_duration(name,index))
	sprite.sprite_frames=frames
	root.add_child(sprite);root.add_child(clock)
	await process_frame
	for name in clock.get_animation_names():
		for direction in [1.0,-1.0]:
			for speed in [1.0,1.25]:
				sprite.stop();clock.stop()
				sprite.animation=name;clock.animation=name
				sprite.speed_scale=speed;clock.speed_scale=speed
				sprite.play(name,direction,direction<0);clock.play(name,direction,direction<0)
				for tick in 90:
					await process_frame
					var label := "%s dir=%s speed=%s tick=%d native=%d:%f clock=%d:%f" % [name,direction,speed,tick,sprite.frame,sprite.frame_progress,clock.frame,clock.frame_progress]
					check(sprite.frame==clock.frame,label+" frame")
					check(is_equal_approx(sprite.frame_progress,clock.frame_progress),label+" progress")
					check(sprite.is_playing()==clock.is_playing(),label+" playing")
					if tick==30:
						sprite.pause();clock.pause()
					if tick==35:
						sprite.play(name,direction);clock.play(name,direction)
	var result := {"checks":checks,"failed":failed,"details":details}
	print("ANIMATION_CLOCK_CHECKS ",JSON.stringify(result))
	FileAccess.open("res://tmp/runtime-cleanup-2026-11-02/clock-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	sprite.queue_free();clock.queue_free()
	await process_frame
	quit(0 if failed==0 else 1)
