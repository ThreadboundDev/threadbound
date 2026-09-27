shader_type canvas_item;

uniform float sway_strength : hint_range(0.0, 18.0) = 4.0;
uniform float sway_speed : hint_range(0.05, 2.0) = 0.34;
uniform float gust_strength : hint_range(0.0, 30.0) = 9.0;
uniform float gust_frequency : hint_range(0.02, 0.5) = 0.08;
uniform float phase_offset : hint_range(0.0, 20.0) = 0.0;
uniform float canopy_start : hint_range(0.1, 0.9) = 0.46;

void vertex() {
	float height_from_root = clamp(1.0 - UV.y, 0.0, 1.0);
	float canopy_mask = smoothstep(canopy_start, 0.94, height_from_root);
	float side_distance = abs(UV.x - 0.5) * 2.0;
	float outer_crown = smoothstep(0.18, 0.9, side_distance);
	float motion_mask = canopy_mask * mix(0.16, 1.0, outer_crown);

	float broad = sin(TIME * sway_speed + phase_offset + UV.x * 3.6);
	float branch_variation = sin(TIME * sway_speed * 1.63 + phase_offset * 0.7 + UV.x * 12.0) * 0.28;
	float gust_cycle = pow(max(sin(TIME * gust_frequency + phase_offset), 0.0), 10.0);
	float gust_ripple = 0.7 + sin(UV.x * 8.0 + TIME * 1.4) * 0.3;

	VERTEX.x += motion_mask * (
		(broad + branch_variation) * sway_strength
		+ gust_cycle * gust_ripple * gust_strength
	);
	VERTEX.y += motion_mask * abs(branch_variation) * 0.8;
}

