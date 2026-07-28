shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float time_seconds = 0.0;
uniform float aura_visibility : hint_range(0.0, 1.0) = 0.0;
uniform float outline_distance_px : hint_range(1.0, 24.0) = 10.0;
uniform float outline_feather_px : hint_range(1.0, 12.0) = 5.0;
uniform vec2 source_texture_size = vec2(256.0);
uniform sampler2D silhouette_texture : source_color, filter_linear, repeat_disable;
uniform vec4 source_uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 ivory_color : source_color = vec4(1.0, 0.965, 0.82, 1.0);
uniform vec4 channel_1 : source_color = vec4(0.96, 0.67, 0.24, 1.0);
uniform vec4 channel_2 : source_color = vec4(0.96, 0.67, 0.24, 1.0);
uniform vec4 channel_3 : source_color = vec4(0.96, 0.67, 0.24, 1.0);
uniform vec3 channel_weights = vec3(1.0, 0.0, 0.0);
uniform float energy : hint_range(0.0, 3.0) = 1.0;

void vertex() {
	float expanded_extent_px = outline_distance_px + outline_feather_px + 2.0;
	vec2 local_uv = (UV - source_uv_rect.xy) / max(
		source_uv_rect.zw,
		vec2(0.000001)
	);
	VERTEX += (local_uv * 2.0 - vec2(1.0)) * expanded_extent_px;
}

float source_alpha(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	vec2 atlas_uv = source_uv_rect.xy + uv * source_uv_rect.zw;
	return texture(silhouette_texture, atlas_uv).a;
}

float dilation_alpha(vec2 uv, float radius_px) {
	vec2 pixel = vec2(1.0) / max(source_texture_size, vec2(1.0));
	float result = source_alpha(uv);
	for (int index = 0; index < 16; index++) {
		float angle = float(index) * 0.3926990817;
		vec2 direction = vec2(cos(angle), sin(angle));
		result = max(result, source_alpha(uv + direction * pixel * radius_px));
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
	float expanded_extent_px = outline_distance_px + outline_feather_px + 2.0;
	vec2 size_with_margin = source_texture_size + vec2(expanded_extent_px * 2.0);
	vec2 local_uv = (UV - source_uv_rect.xy) / max(
		source_uv_rect.zw,
		vec2(0.000001)
	);
	vec2 source_uv = (
		local_uv * size_with_margin - vec2(expanded_extent_px)
	) / max(source_texture_size, vec2(1.0));

	float spatial_wave = (
		sin(source_uv.y * 31.0 - time_seconds * 4.3)
		+ sin((source_uv.x + source_uv.y) * 22.0 + time_seconds * 3.1)
	) * 0.5;
	float breathing_distance = max(
		1.0,
		outline_distance_px + spatial_wave * 2.2
	);
	float inner_distance = max(1.0, breathing_distance - 3.0);
	float outer_distance = breathing_distance;
	float halo_distance = breathing_distance + outline_feather_px;

	float center = source_alpha(source_uv);
	float inner = max(
		center,
		dilation_alpha(source_uv, inner_distance)
	);
	float outer = max(
		dilation_alpha(source_uv, outer_distance),
		dilation_alpha(source_uv, outer_distance * 0.72)
	);
	float halo = max(
		dilation_alpha(source_uv, halo_distance),
		dilation_alpha(source_uv, halo_distance * 0.84)
	);

	float body_edge = dilation_alpha(source_uv, 1.25);
	float energy_field = clamp(outer - body_edge, 0.0, 1.0);
	float shell = clamp(outer - inner, 0.0, 1.0);
	float soft_halo = clamp(halo - outer, 0.0, 1.0);
	float filament_noise = (
		0.48
		+ 0.3 * sin(source_uv.y * 47.0 + time_seconds * 7.0)
		+ 0.22 * sin(source_uv.x * 63.0 - time_seconds * 5.2)
	);
	float bright_filaments = shell * smoothstep(0.38, 0.76, filament_noise);
	float field_shimmer = 0.68 + 0.32 * sin(
		source_uv.y * 26.0 - time_seconds * 3.8
	);

	float selector = fract(
		source_uv.y * 2.35
		+ source_uv.x * 1.15
		+ sin(time_seconds * 0.8 + source_uv.y * 9.0) * 0.08
	);
	vec3 identity = selected_channel(selector);
	vec3 filament_color = mix(identity, ivory_color.rgb, bright_filaments * 0.7);
	float alpha = (
		energy_field * 0.16 * field_shimmer
		+ bright_filaments * 0.5
		+ soft_halo * 0.1
	) * aura_visibility;
	vec3 emission = filament_color * (
		energy_field * 0.28 * field_shimmer
		+ bright_filaments * 0.96
		+ soft_halo * 0.18
	) * aura_visibility * energy;

	COLOR = vec4(emission, alpha);
}
