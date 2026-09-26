shader_type canvas_item;
// Receive the level's 2D lighting on top of the viewport's 3D surface shading.

uniform vec4 outline_color : source_color = vec4(0.055, 0.042, 0.042, 1.0);
uniform float outline_source_pixels : hint_range(0.0, 8.0, 0.25) = 3.0;
uniform float exposure = 1.05;
uniform float contrast = 1.0;
uniform float saturation = 1.06;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 step_size = TEXTURE_PIXEL_SIZE * outline_source_pixels;
	float surrounding_alpha = 0.0;
	float coverage = 0.0;
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV + vec2(step_size.x, 0.0)).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV - vec2(step_size.x, 0.0)).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV + vec2(0.0, step_size.y)).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV - vec2(0.0, step_size.y)).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV + step_size).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV - step_size).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV + vec2(step_size.x, -step_size.y)).a);
	surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV + vec2(-step_size.x, step_size.y)).a);
	// Require local coverage: isolated alpha wisps should not become black spikes.
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			coverage += texture(TEXTURE, UV + vec2(float(x), float(y))*step_size).a / 9.0;
		}
	}
	float outline_alpha = surrounding_alpha * (1.0 - base.a) * smoothstep(0.08, 0.38, coverage);
	vec3 graded = pow(max(base.rgb, vec3(0.0)), vec3(contrast)) * exposure;
	float luminance = dot(graded, vec3(0.2126, 0.7152, 0.0722));
	graded = mix(vec3(luminance), graded, saturation);
	graded = clamp(graded, vec3(0.0), vec3(1.0));
	// Compose in premultiplied-alpha space. Mixing straight-alpha RGB allowed
	// transparent white viewport texels to form a pale fringe under the skirt.
	float edge_alpha = outline_alpha * outline_color.a;
	float final_alpha = base.a + edge_alpha * (1.0 - base.a);
	vec3 premultiplied = graded * base.a;
	premultiplied += outline_color.rgb * edge_alpha * (1.0 - base.a);
	COLOR = vec4(
		premultiplied / max(final_alpha, 0.0001),
		final_alpha
	);
}
