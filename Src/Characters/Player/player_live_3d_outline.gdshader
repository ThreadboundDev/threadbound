shader_type canvas_item;
// Receive the level's 2D lighting on top of the viewport's 3D surface shading.

uniform float exposure = 1.05;
uniform float contrast = 1.0;
uniform float saturation = 1.06;

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
}
