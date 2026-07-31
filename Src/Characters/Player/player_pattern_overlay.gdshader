shader_type canvas_item;
render_mode unshaded;

uniform sampler2D pattern_texture : repeat_enable, filter_linear_mipmap;
uniform float pattern_source_pixel_size : hint_range(48.0, 320.0, 1.0) = 180.0;
uniform float overlay_strength : hint_range(0.0, 1.0, 0.01) = 0.88;
uniform vec4 pattern_black : source_color = vec4(0.10, 0.065, 0.025, 1.0);
uniform vec4 pattern_gold : source_color = vec4(0.69, 0.48, 0.19, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float luminance = dot(base.rgb, vec3(0.299, 0.587, 0.114));

	// The normalized player wears cool charcoal cloth. Darkness finds the
	// garment while the blue/red balance rejects warm skin, bronze wraps,
	// boots, and the weapon much more reliably than saturation alone.
	float dark_cloth = 1.0 - smoothstep(0.22, 0.46, luminance);
	float blue_red_balance = base.b / max(base.r, 0.001);
	float non_bronze = smoothstep(0.48, 0.74, blue_red_balance);
	float garment_mask = base.a * dark_cloth * non_bronze;

	vec2 source_pixels = UV / TEXTURE_PIXEL_SIZE;
	vec4 pattern = texture(pattern_texture, source_pixels / pattern_source_pixel_size);
	float thread_luminance = dot(pattern.rgb, vec3(0.299, 0.587, 0.114));
	float thread_mask = smoothstep(0.13, 0.55, thread_luminance);
	vec3 woven_color = mix(pattern_black.rgb, pattern_gold.rgb, thread_mask);
	float woven_opacity = mix(0.28, 1.0, thread_mask);
	COLOR = vec4(woven_color, garment_mask * woven_opacity * overlay_strength);
}
