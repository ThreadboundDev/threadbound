shader_type canvas_item;
// Receive the level's 2D lighting on top of the viewport's 3D surface shading.

uniform float exposure = 1.05;
uniform float contrast = 1.0;
uniform float saturation = 1.06;

uniform bool clip_ground_ink = false;
uniform bool clip_swim_ink = false;
uniform bool clip_swim_terrain = false;
uniform sampler2D terrain_ink : filter_linear, repeat_disable;
uniform vec2 ink_uv_x;
uniform vec2 ink_uv_y;
uniform vec2 ink_uv_origin;
uniform sampler2D terrain_fill : filter_linear, repeat_disable;
uniform vec2 fill_uv_x;
uniform vec2 fill_uv_y;
uniform vec2 fill_uv_origin;

varying vec2 ink_uv;
varying vec2 fill_uv;
varying float ground_offset;

void vertex() {
	if (clip_ground_ink || clip_swim_ink || clip_swim_terrain) {
		vec2 world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
		ink_uv = mat2(ink_uv_x, ink_uv_y) * world_position + ink_uv_origin;
		fill_uv = mat2(fill_uv_x, fill_uv_y) * world_position + fill_uv_origin;
		// The composite's land pose registers its origin at the collision sole.
		ground_offset = world_position.y - MODEL_MATRIX[3].y;
	}
}

bool inside_mask(vec2 uv) {
	return all(greaterThanEqual(uv, vec2(0.0))) && all(lessThan(uv, vec2(1.0)));
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
	if ((clip_swim_ink || (clip_ground_ink && ground_offset > -22.0)) && inside_mask(ink_uv)) {
		// Ease the mask in across the boot so overlapping walls leave the body visible.
		float ink_weight = clip_swim_ink ? 1.0 : smoothstep(-22.0, -12.0, ground_offset);
		COLOR.a *= 1.0 - ink_weight * texture(terrain_ink, ink_uv).a;
	}
	if (clip_swim_terrain && inside_mask(fill_uv)) {
		COLOR.a *= 1.0 - texture(terrain_fill, fill_uv).a;
	}
}
