extends RefCounted
## Shared button theme. Each screen supplies its own biome accent.

const FONT := preload("res://Assets/UI/Fonts/Almendra/Almendra-Regular.ttf")
const PLATE := preload("res://Assets/UI/menu_button_plate.svg")
const FOCUS := preload("res://Assets/UI/menu_button_focus.svg")
const SLICE := 8.0

const CHAMBER := Color("#e6c78f")
const BLUE := Color("#98ceef")
const RED := Color("#f3a79a")
const YELLOW := Color("#f2d681")

const TEXT := Color("#e8e0cf")
const ACTIVE_TEXT := Color("#fff6e5")
const DISABLED_TEXT := Color("#a7a8a6")


static func create(accent: Color = CHAMBER, font_size: int = 38) -> Theme:
	var theme := Theme.new()
	theme.set_font(&"font", &"Button", FONT)
	theme.set_font_size(&"font_size", &"Button", font_size)
	theme.set_color(&"font_color", &"Button", TEXT)
	theme.set_color(&"font_hover_color", &"Button", ACTIVE_TEXT)
	theme.set_color(&"font_pressed_color", &"Button", ACTIVE_TEXT)
	theme.set_color(&"font_focus_color", &"Button", ACTIVE_TEXT)
	theme.set_color(&"font_disabled_color", &"Button", DISABLED_TEXT)
	theme.set_stylebox(&"normal", &"Button", _nine_slice(PLATE, Color.WHITE))
	theme.set_stylebox(&"hover", &"Button", _nine_slice(PLATE, accent * Color(1.55, 1.55, 1.55)))
	theme.set_stylebox(&"pressed", &"Button", _nine_slice(PLATE, accent * Color(1.22, 1.22, 1.22)))
	theme.set_stylebox(&"disabled", &"Button", _nine_slice(PLATE, Color(0.72, 0.74, 0.77, 0.96)))
	theme.set_stylebox(&"focus", &"Button", _nine_slice(FOCUS, accent))
	return theme


static func _nine_slice(texture: Texture2D, tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, SLICE)
	style.set_content_margin(SIDE_LEFT, 22.0)
	style.set_content_margin(SIDE_RIGHT, 22.0)
	style.set_content_margin(SIDE_TOP, 8.0)
	style.set_content_margin(SIDE_BOTTOM, 8.0)
	return style
