extends RefCounted
## Original sprite frames and the separately rendered OG movement study.

static func make_legacy(folder: String) -> Sprite2D:
	var path := folder.path_join("frames.json")
	if not FileAccess.file_exists(path):
		return null
	var clips = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not clips is Dictionary or not clips.has("Idle"):
		return null
	var sprite := Sprite2D.new()
	sprite.name = "Original2DComparison"
	sprite.position = Vector2(4, -2)
	sprite.scale = Vector2(0.7, 0.7)
	sprite.light_mask = 2
	sprite.hide()
	sprite.set_meta("sprite_folder", folder)
	sprite.set_meta("sprite_clips", clips)
	sprite.set_meta("sprite_sheets", {})
	sprite.set_meta("sprite_frames", {})
	return sprite


static func sync_legacy(sprite: Sprite2D, clock: Node, facing_left: bool) -> void:
	sprite.flip_h = facing_left
	var clips: Dictionary = sprite.get_meta("sprite_clips")
	var animation: String = String(clock.animation)
	var frames: Array = clips.get(animation, clips["Idle"])
	var frame_index := clampi(clock.frame, 0, frames.size() - 1)
	var cache_key := "%s:%d" % [animation, frame_index]
	var textures: Dictionary = sprite.get_meta("sprite_frames")
	if not textures.has(cache_key):
		var frame: Array = frames[frame_index]
		var sheets: Dictionary = sprite.get_meta("sprite_sheets")
		var filename: String = frame[0]
		if not sheets.has(filename):
			var folder: String = sprite.get_meta("sprite_folder")
			sheets[filename] = load_image(folder.path_join(filename))
		var sheet: Texture2D = sheets[filename]
		var region: Array = frame[1]
		textures[cache_key] = sheet if region.is_empty() else atlas_region(sheet, region)
	sprite.texture = textures[cache_key]


static func make_baked(folder: String) -> AnimatedSprite2D:
	var path := folder.path_join("og_baked_manifest.json")
	if not FileAccess.file_exists(path):
		return null
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not manifest is Dictionary or not manifest.has("frames"):
		return null
	var library := SpriteFrames.new()
	library.remove_animation(&"default")
	for clip in [&"idle", &"run", &"jump"]:
		var sheet := load_image(folder.path_join("OG_%s_atlas.png" % clip))
		if not sheet:
			return null
		library.add_animation(clip)
		library.set_animation_speed(clip, 12.0)
		library.set_animation_loop(clip, clip != &"jump")
		for frame in manifest.frames:
			if frame.clip == String(clip):
				library.add_frame(clip, atlas_region(sheet, frame.region), frame.duration_ms * 0.012)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "BakedOGComparison"
	sprite.sprite_frames = library
	sprite.scale = Vector2.ONE * float(manifest.game_scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = material
	sprite.set_meta("baked_anchor", Vector2(manifest.offset[0], manifest.offset[1]))
	sprite.hide()
	return sprite


static func sync_baked(sprite: AnimatedSprite2D, player: CharacterBody2D, live: Sprite2D) -> void:
	var anchor: Vector2 = sprite.get_meta("baked_anchor")
	sprite.position = live.position
	sprite.flip_h = live.flip_h
	sprite.offset = Vector2(-anchor.x if sprite.flip_h else anchor.x, anchor.y)
	var clip := &"idle"
	if not player.is_on_floor():
		clip = &"jump"
	elif absf(player.velocity.x) > 20:
		clip = &"run"
	if sprite.animation != clip or not sprite.is_playing() and clip != &"jump":
		sprite.play(clip)


static func atlas_region(sheet: Texture2D, region: Array) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(region[0], region[1], region[2], region[3])
	atlas.filter_clip = true
	return atlas


static func load_image(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image and not image.is_empty() else null
