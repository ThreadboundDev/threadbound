extends Node

const ENEMY_BASE_SCENE := preload("res://Src/Enemies/EnemyBase/enemy_base.tscn")
const DAMAGE_TEXTURE := preload("res://Assets/VFX/V2/enemy_damage_fray_v2.png")
const DEATH_TEXTURE := preload("res://Assets/VFX/V2/enemy_death_unravel_v2.png")

var _failures := PackedStringArray()

func _ready() -> void:
	_verify_true_alpha_sheet(DAMAGE_TEXTURE, "damage fray")
	_verify_true_alpha_sheet(DEATH_TEXTURE, "death unravel")
	_verify_enemy_sprite_setup()
	_finish()

func _verify_true_alpha_sheet(texture: Texture2D, label: String) -> void:
	_expect(texture != null, "%s texture loads." % label)
	if texture == null:
		return
	var image := texture.get_image()
	_expect(image != null and not image.is_empty(), "%s image data is available." % label)
	if image == null or image.is_empty():
		return
	_expect(
		image.get_width() % 2 == 0 and image.get_height() % 2 == 0,
		"%s remains an even 2x2 sheet." % label
	)

	var cell_size := Vector2i(image.get_width() / 2, image.get_height() / 2)
	for frame_index in 4:
		var origin := Vector2i(
			(frame_index % 2) * cell_size.x,
			(frame_index / 2) * cell_size.y
		)
		var visible_pixels := 0
		var total_pixels := cell_size.x * cell_size.y
		for y in cell_size.y:
			for x in cell_size.x:
				if image.get_pixel(origin.x + x, origin.y + y).a > 0.03:
					visible_pixels += 1
		var coverage := float(visible_pixels) / float(maxi(1, total_pixels))
		_expect(coverage > 0.001, "%s frame %d is not empty." % [label, frame_index])
		_expect(
			coverage < 0.12,
			"%s frame %d has %.1f%% coverage; a rectangular background may remain." %
			[label, frame_index, coverage * 100.0]
		)

		for corner in [
			Vector2i(0, 0),
			Vector2i(cell_size.x - 1, 0),
			Vector2i(0, cell_size.y - 1),
			Vector2i(cell_size.x - 1, cell_size.y - 1),
		]:
			_expect(
				image.get_pixel(origin.x + corner.x, origin.y + corner.y).a <= 0.01,
				"%s frame %d retains an opaque atlas corner." % [label, frame_index]
			)

func _verify_enemy_sprite_setup() -> void:
	var enemy := ENEMY_BASE_SCENE.instantiate() as EnemyBase
	_expect(enemy != null, "Enemy base scene instantiates.")
	if enemy == null:
		return
	var sprite := enemy.call("_make_one_shot_vfx_sprite", DAMAGE_TEXTURE, 0.1) as Sprite2D
	_expect(sprite != null, "Enemy hit VFX creates a sprite.")
	if sprite:
		_expect(sprite.hframes == 2 and sprite.vframes == 2, "Enemy hit VFX slices the 2x2 sheet.")
		_expect(sprite.frame == 0, "Enemy hit VFX starts on frame zero.")
		_expect(sprite.material == null, "True-alpha hit VFX does not use the retired keying shader.")
	enemy.free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Combat VFX verification: " + message)

func _finish() -> void:
	if _failures.is_empty():
		print("Combat VFX verification passed.")
		get_tree().quit(0)
		return
	print("Combat VFX verification failed with %d issue(s)." % _failures.size())
	get_tree().quit(1)
