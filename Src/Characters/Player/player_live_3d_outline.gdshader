shader_type canvas_item;
// Receive the level's 2D lighting on top of the viewport's 3D surface shading.

uniform vec4 outline_color : source_color = vec4(0.015, 0.012, 0.012, 1.0);
uniform float outline_source_pixels : hint_range(0.0, 24.0, 0.25) = 3.0;
uniform float exposure = 1.05;
uniform float contrast = 1.0;
uniform float saturation = 1.06;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 step_size = TEXTURE_PIXEL_SIZE * outline_source_pixels;
	float surrounding_alpha = 0.0;
	// Expand the opaque silhouette with a circular brush. Thresholding the
	// source alpha prevents faint MSAA texels becoming a second shadow edge.
	for (int radius = 1; radius <= 2; radius++) {
		for (int i = 0; i < 16; i++) {
			float angle = float(i) * 6.28318530718 / 16.0;
			vec2 offset = vec2(cos(angle), sin(angle)) * step_size * float(radius) * 0.5;
			surrounding_alpha = max(surrounding_alpha, texture(TEXTURE, UV + offset).a);
		}
	}
	float outline_alpha = step(0.5, surrounding_alpha) * (1.0 - base.a);
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
