shader_type canvas_item;

uniform float billow_amount : hint_range(0.0, 8.0, 0.1) = 2.0;
uniform float billow_speed : hint_range(0.0, 2.0, 0.01) = 0.32;
uniform float billow_phase : hint_range(0.0, 6.283, 0.01) = 0.0;

void fragment() {
	vec2 shifted_uv = UV;
	shifted_uv.x += sin(TIME * billow_speed + UV.y * 28.0 + billow_phase)
		* billow_amount * TEXTURE_PIXEL_SIZE.x;
	shifted_uv.y += cos(TIME * billow_speed * 0.73 + UV.x * 20.0 + billow_phase)
		* billow_amount * 0.22 * TEXTURE_PIXEL_SIZE.y;
	COLOR = texture(TEXTURE, shifted_uv) * COLOR;
}
