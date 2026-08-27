shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform vec4 surface_color : source_color = vec4(0.36, 0.78, 0.88, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.11, 0.48, 0.68, 1.0);
uniform vec4 deep_color : source_color = vec4(0.025, 0.16, 0.29, 1.0);
uniform vec4 silhouette_color : source_color = vec4(0.035, 0.10, 0.16, 1.0);
uniform vec4 glint_color : source_color = vec4(0.73, 0.94, 0.94, 1.0);

uniform float reflection_strength : hint_range(0.0, 1.0) = 0.62;
uniform float reflection_detail : hint_range(0.0, 1.0) = 0.32;
uniform float horizontal_blur_px : hint_range(0.0, 18.0) = 7.0;
uniform float distortion_px : hint_range(0.0, 18.0) = 5.0;
uniform float motion_speed : hint_range(0.0, 3.0) = 0.34;
uniform float breakup_strength : hint_range(0.0, 1.0) = 0.48;
uniform float surface_glint_strength : hint_range(0.0, 1.0) = 0.72;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 blend = fract(point);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
}

vec3 blurred_reflection(vec2 sample_uv, float blur_px) {
	vec2 screen_pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	vec2 step_uv = vec2(screen_pixel_size.x * blur_px, 0.0);
	vec3 color = texture(screen_texture, sample_uv).rgb * 0.28;
	color += texture(screen_texture, sample_uv - step_uv).rgb * 0.20;
	color += texture(screen_texture, sample_uv + step_uv).rgb * 0.20;
	color += texture(screen_texture, sample_uv - step_uv * 2.0).rgb * 0.12;
	color += texture(screen_texture, sample_uv + step_uv * 2.0).rgb * 0.12;
	color += texture(screen_texture, sample_uv - step_uv * 3.0).rgb * 0.04;
	color += texture(screen_texture, sample_uv + step_uv * 3.0).rgb * 0.04;
	return color;
}

void fragment() {
	float time = TIME * motion_speed;
	vec2 screen_pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	float screen_height = abs(dFdy(SCREEN_UV.y) / max(abs(dFdy(UV.y)), 0.000001));

	// Mirror the already-rendered scene around this rectangle's top edge.
	vec2 reflected_uv = SCREEN_UV;
	reflected_uv.y -= UV.y * screen_height * 2.0;

	float broad_wave = sin(UV.y * 43.0 + UV.x * 9.0 + time * 3.1);
	float fine_wave = sin(UV.y * 91.0 - UV.x * 17.0 - time * 4.7);
	float broken_wave = value_noise(vec2(UV.x * 15.0 - time, UV.y * 34.0 + time * 0.45));
	float distortion = (broad_wave * 0.62 + fine_wave * 0.23 + (broken_wave - 0.5) * 0.5);
	reflected_uv.x += distortion * distortion_px * screen_pixel_size.x;
	reflected_uv = clamp(reflected_uv, vec2(0.001), vec2(0.999));

	vec3 source = blurred_reflection(reflected_uv, horizontal_blur_px);
	float luminance = dot(source, vec3(0.2126, 0.7152, 0.0722));
	float light_memory = smoothstep(0.38, 0.92, luminance);
	vec3 reflected = mix(silhouette_color.rgb, source, reflection_detail);
	reflected += source * light_memory * 0.22;

	vec3 gradient = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.0, 1.0, UV.y));
	gradient = mix(surface_color.rgb, gradient, smoothstep(0.0, 0.18, UV.y));

	// Fragment both the outline impression and the reflection interior.
	float horizontal_bands = smoothstep(0.28, 0.72, sin(UV.y * 118.0 + time * 5.0 + distortion * 2.4) * 0.5 + 0.5);
	float coarse_breakup = smoothstep(0.32, 0.76, broken_wave);
	float breakup = mix(1.0, horizontal_bands * 0.58 + coarse_breakup * 0.42, breakup_strength);
	float depth_fade = 1.0 - smoothstep(0.58, 1.0, UV.y);
	// Let the painted shallow color meet the air cleanly. Reflections fade in
	// below the surface instead of compressing into a dark outline at UV.y = 0.
	float surface_reflection_fade = smoothstep(0.035, 0.13, UV.y);
	float reflection_mix = (
		reflection_strength
		* depth_fade
		* surface_reflection_fade
		* mix(0.38, 1.0, breakup)
	);
	vec3 water = mix(gradient, reflected, reflection_mix);

	// Broad, broken glints suggest the moving surface without drawing a solid
	// white/cyan contour across the top of every water volume.
	float surface_band = 1.0 - smoothstep(0.015, 0.13, UV.y);
	float glint_flow = sin(UV.x * 37.0 - time * 5.0 + broken_wave * 2.2) * 0.5 + 0.5;
	float broken_glints = smoothstep(0.67, 0.94, glint_flow);
	float soft_glint = surface_band * broken_glints * surface_glint_strength * 0.34;
	water = mix(water, glint_color.rgb, soft_glint);

	COLOR = vec4(water, 1.0);
}
