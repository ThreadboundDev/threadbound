shader_type canvas_item;

uniform vec4 depth_tint : source_color = vec4(0.72, 0.80, 0.76, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.25;
uniform float saturation : hint_range(0.0, 1.4) = 0.75;
uniform float contrast : hint_range(0.4, 1.4) = 0.82;
uniform float lift : hint_range(-0.25, 0.35) = 0.06;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;
uniform float top_light_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec2 top_light_origin = vec2(0.5, -0.12);
uniform float top_light_radius : hint_range(0.1, 2.0) = 0.9;
uniform vec4 top_light_color : source_color = vec4(1.0, 0.92, 0.74, 1.0);
uniform float vertical_fade : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(vec3(luma), tex.rgb, saturation);
	vec3 graded = (desaturated - vec3(0.5)) * contrast + vec3(0.5);
	graded += vec3(lift);
	graded = mix(graded, depth_tint.rgb, tint_strength);

	float light_distance = distance(UV, top_light_origin);
	float light_mask = 1.0 - smoothstep(0.0, top_light_radius, light_distance);
	light_mask *= 1.0 - smoothstep(0.0, 1.0, UV.y) * vertical_fade;
	graded = mix(graded, top_light_color.rgb, light_mask * top_light_strength);

	COLOR = vec4(clamp(graded, 0.0, 1.0), tex.a * alpha_multiplier);
}
