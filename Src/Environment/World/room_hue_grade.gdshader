shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 hue_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float hue_strength : hint_range(0.0, 1.0) = 0.0;
uniform float brightness_multiplier : hint_range(0.5, 1.25) = 1.0;

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 graded = mix(screen.rgb, hue_color.rgb, hue_strength * hue_color.a);
	graded *= brightness_multiplier;
	COLOR = vec4(graded, screen.a);
}
