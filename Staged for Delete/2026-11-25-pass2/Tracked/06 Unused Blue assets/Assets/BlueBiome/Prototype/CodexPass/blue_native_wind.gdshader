shader_type canvas_item;

uniform float sway_strength : hint_range(0.0, 24.0) = 5.0;
uniform float sway_speed : hint_range(0.1, 4.0) = 1.15;
uniform float gust_strength : hint_range(0.0, 48.0) = 18.0;
uniform float gust_frequency : hint_range(0.05, 1.0) = 0.22;
uniform float phase_offset : hint_range(0.0, 20.0) = 0.0;

void vertex() {
	// Keep roots planted while allowing the upper silhouette to bend.
	float height_mask = pow(clamp(1.0 - UV.y, 0.0, 1.0), 1.55);
	float broad_sway = sin(TIME * sway_speed + phase_offset + UV.x * 4.7);
	float fine_sway = sin(TIME * (sway_speed * 1.71) + phase_offset * 0.63 + UV.x * 11.3) * 0.32;

	// A narrow, irregular envelope creates occasional gusts rather than a
	// constant mechanical pendulum. UV phase prevents the whole strip from
	// leaning as one rigid card.
	float gust_cycle = max(sin(TIME * gust_frequency + phase_offset), 0.0);
	float gust_envelope = pow(gust_cycle, 9.0);
	float gust_ripple = 0.72 + sin(TIME * 2.15 + UV.x * 7.0) * 0.28;

	VERTEX.x += height_mask * (
		(broad_sway + fine_sway) * sway_strength
		+ gust_envelope * gust_ripple * gust_strength
	);
	VERTEX.y += height_mask * abs(broad_sway) * 1.4;
}
