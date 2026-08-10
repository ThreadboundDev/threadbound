shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float time_seconds = 0.0;
uniform float aura_visibility : hint_range(0.0, 1.0) = 0.0;
uniform float outline_distance_px : hint_range(1.0, 32.0) = 21.0;
uniform float outline_feather_px : hint_range(1.0, 16.0) = 9.0;
uniform float flame_height_px : hint_range(0.0, 48.0) = 27.0;
uniform float jaggedness_px : hint_range(0.0, 16.0) = 6.5;
uniform vec2 source_texture_size = vec2(1405.0);
uniform sampler2D silhouette_texture : source_color, filter_linear, repeat_disable;
uniform vec4 source_uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 ivory_color : source_color = vec4(1.0, 0.965, 0.82, 1.0);
uniform float ivory_mix_strength : hint_range(0.0, 1.0) = 0.72;
uniform vec4 channel_1 : source_color = vec4(0.94, 0.2, 0.17, 1.0);
uniform vec4 channel_2 : source_color = vec4(0.94, 0.2, 0.17, 1.0);
uniform vec4 channel_3 : source_color = vec4(0.94, 0.2, 0.17, 1.0);
uniform vec3 channel_weights = vec3(1.0, 0.0, 0.0);
uniform float energy : hint_range(0.0, 3.0) = 1.0;


void vertex() {
	float margin = max(
		outline_distance_px + outline_feather_px + jaggedness_px + 3.0,
		flame_height_px + outline_feather_px + 3.0
	);
	vec2 local_uv = (UV - source_uv_rect.xy) / max(source_uv_rect.zw, vec2(0.000001));
	VERTEX += (local_uv * 2.0 - vec2(1.0)) * margin;
}


float source_alpha(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	vec2 atlas_uv = source_uv_rect.xy + uv * source_uv_rect.zw;
	vec4 sample_color = texture(silhouette_texture, atlas_uv);
	bool legacy_pink = (
		sample_color.r > 0.58
		&& sample_color.b > 0.35
		&& sample_color.g < sample_color.r * 0.82
	);
	return legacy_pink ? 0.0 : sample_color.a;
}


float dilation_alpha(vec2 uv, float radius_px) {
	vec2 pixel = vec2(1.0) / max(source_texture_size, vec2(1.0));
	float result = source_alpha(uv);
	for (int index = 0; index < 20; index++) {
		float angle = float(index) * 0.314159265;
		vec2 direction = vec2(cos(angle), sin(angle));
		result = max(result, source_alpha(uv + direction * pixel * radius_px));
	}
	return result;
}


float upward_flame_alpha(vec2 uv, float reach_px) {
	vec2 pixel = vec2(1.0) / max(source_texture_size, vec2(1.0));
	float result = 0.0;
	for (int index = 1; index <= 10; index++) {
		float progress = float(index) / 10.0;
		float torn_wave = (
			sin(uv.y * 57.0 + progress * 11.0 - time_seconds * 7.2)
			+ sin(uv.x * 73.0 - progress * 8.0 + time_seconds * 4.6)
		) * 0.5;
		vec2 offset = vec2(
			torn_wave * reach_px * 0.31 * progress,
			reach_px * progress
		) * pixel;
		result = max(result, source_alpha(uv + offset) * (1.0 - progress * 0.74));
	}
	return result;
}


vec3 selected_channel(float selector) {
	vec3 weights = max(channel_weights, vec3(0.0));
	float total = max(weights.x + weights.y + weights.z, 0.0001);
	float first_edge = weights.x / total;
	float second_edge = (weights.x + weights.y) / total;
	if (selector < first_edge) {
		return channel_1.rgb;
	}
	if (selector < second_edge) {
		return channel_2.rgb;
	}
	return channel_3.rgb;
}


void fragment() {
	float margin = max(
		outline_distance_px + outline_feather_px + jaggedness_px + 3.0,
		flame_height_px + outline_feather_px + 3.0
	);
	vec2 expanded_size = source_texture_size + vec2(margin * 2.0);
	vec2 local_uv = (UV - source_uv_rect.xy) / max(source_uv_rect.zw, vec2(0.000001));
	vec2 source_uv = (local_uv * expanded_size - vec2(margin)) / max(source_texture_size, vec2(1.0));

	float angular_teeth = (
		sin(source_uv.y * 71.0 - time_seconds * 8.1)
		+ sin((source_uv.x - source_uv.y) * 93.0 + time_seconds * 5.7)
		+ sin(source_uv.x * 131.0 - time_seconds * 3.9)
	) / 3.0;
	float radius = max(1.0, outline_distance_px + angular_teeth * jaggedness_px);
	float inner = dilation_alpha(source_uv, max(1.0, radius - 4.0));
	float outer = dilation_alpha(source_uv, radius);
	float halo = dilation_alpha(source_uv, radius + outline_feather_px);
	float body = dilation_alpha(source_uv, 1.25);
	float shell = clamp(outer - inner, 0.0, 1.0);
	float energy_field = clamp(outer - body, 0.0, 1.0);
	float soft_halo = clamp(halo - outer, 0.0, 1.0);
	float flame = clamp(upward_flame_alpha(source_uv, flame_height_px) - outer * 0.38, 0.0, 1.0);

	float broken_thread = smoothstep(
		0.18,
		0.82,
		0.5 + 0.5 * sin(source_uv.y * 79.0 + source_uv.x * 47.0 - time_seconds * 10.0)
	);
	float bright_filaments = shell * mix(0.35, 1.0, broken_thread);
	float selector = fract(
		source_uv.y * 2.4 + source_uv.x * 1.2 + sin(time_seconds + source_uv.y * 8.0) * 0.09
	);
	vec3 identity = selected_channel(selector);
	vec3 filament_color = mix(identity, ivory_color.rgb, bright_filaments * ivory_mix_strength);
	float flicker = 0.72 + 0.28 * sin(source_uv.y * 34.0 - time_seconds * 5.4);
	float alpha = (
		energy_field * 0.24 * flicker
		+ bright_filaments * 0.82
		+ soft_halo * 0.2
		+ flame * 0.48
	) * aura_visibility;
	vec3 emission = filament_color * (
		energy_field * 0.5 * flicker
		+ bright_filaments * 1.5
		+ soft_halo * 0.34
		+ flame * 1.08
	) * aura_visibility * energy;
	COLOR = vec4(emission, alpha);
}
