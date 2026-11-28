shader_type canvas_item;
// Receive the level's 2D lighting on top of the viewport's 3D surface shading.

uniform float exposure = 1.05;
uniform float contrast = 1.0;
uniform float saturation = 1.06;

uniform bool clip_ground_ink = false;
uniform sampler2D terrain_ink : filter_linear, repeat_disable;
uniform vec2 ink_uv_x;
uniform vec2 ink_uv_y;
uniform vec2 ink_uv_origin;

varying vec2 ink_uv;
varying float ground_offset;

void vertex() {
	if (clip_ground_ink) {
		vec2 world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
		ink_uv = mat2(ink_uv_x, ink_uv_y) * world_position + ink_uv_origin;
		// The composite's land pose registers its origin at the collision sole.
		ground_offset = world_position.y - MODEL_MATRIX[3].y;
	}
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 graded = pow(max(base.rgb, vec3(0.0)), vec3(contrast)) * exposure;
	float luminance = dot(graded, vec3(0.2126, 0.7152, 0.0722));
	graded = mix(vec3(luminance), graded, saturation);
	graded = clamp(graded, vec3(0.0), vec3(1.0));
	// Geometry supplies all outlines before compositing. Preserve source alpha
	// so a sword crossing the body never receives a second silhouette expansion.
	vec3 premultiplied = graded * base.a;
	COLOR = vec4(
		premultiplied / max(base.a, 0.0001),
		base.a
	);
	if (clip_ground_ink && ground_offset > -22.0 &&
			all(greaterThanEqual(ink_uv, vec2(0.0))) && all(lessThan(ink_uv, vec2(1.0)))) {
		// Ease the mask in across the boot so overlapping walls leave the body visible.
		float sole = smoothstep(-22.0, -12.0, ground_offset);
		COLOR.a *= 1.0 - sole * texture(terrain_ink, ink_uv).a;
	}
}
