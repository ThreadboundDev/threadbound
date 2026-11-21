@tool
extends AnimatedSprite2D
## Art-only frame-by-frame Eave Runner. No AI, collision, damage or 3D viewport.

const ASSET_ROOT := "res://Assets/BlueBiome/Enemies/EaveRunner/SpriteStudy/"
var study_definition: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	centered = true
	offset = Vector2(0, -224)
	if not _load_study_frames():
		return
	if not animation_finished.is_connected(_on_animation_finished):
		animation_finished.connect(_on_animation_finished)
	play(&"idle")

func _load_study_frames() -> bool:
	var manifest_file := FileAccess.open(ASSET_ROOT + "study_manifest.json", FileAccess.READ)
	if manifest_file == null:
		push_error("Eave Runner sprite study: missing manifest")
		return false
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		push_error("Eave Runner sprite study: invalid manifest")
		return false
	study_definition = parsed
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for clip_name: String in study_definition["clips"]:
		var clip: Dictionary = study_definition["clips"][clip_name]
		var image := Image.load_from_file(ASSET_ROOT + str(clip["sheet"]))
		if image == null or image.is_empty():
			push_error("Eave Runner sprite study: missing sheet " + clip_name)
			return false
		var sheet := ImageTexture.create_from_image(image)
		frames.add_animation(clip_name)
		frames.set_animation_loop(clip_name, bool(clip["loop"]))
		frames.set_animation_speed(clip_name, 10.0)
		for index in int(clip["frame_count"]):
			var texture := AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2((index % 4) * 512, (index / 4) * 512, 512, 512)
			texture.filter_clip = true
			frames.add_frame(clip_name, texture, float(clip["durations_ms"][index]) / 100.0)
	sprite_frames = frames
	return true

func play_study_clip(clip_name: StringName, restart := false) -> void:
	if not sprite_frames or not sprite_frames.has_animation(clip_name):
		return
	if restart or animation != clip_name:
		play(clip_name)
		if restart:
			set_frame_and_progress(0, 0.0)
	elif not is_playing():
		play()

func set_facing(direction: float) -> void:
	if not is_zero_approx(direction):
		flip_h = direction < 0.0

func _on_animation_finished() -> void:
	if animation == &"slash" and not Engine.is_editor_hint():
		play(&"idle")
