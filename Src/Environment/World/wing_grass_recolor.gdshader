shader_type canvas_item;
render_mode world_vertex_coords;

uniform sampler2D grass_mask : repeat_disable, filter_nearest;
uniform vec3 red_luminance_basis = vec3(1.0);
uniform vec3 blue_luminance_basis = vec3(1.0);
uniform vec3 yellow_luminance_basis = vec3(1.0);
uniform vec3 boss_luminance_basis = vec3(1.0);
uniform vec4 red_bounds = vec4(0.0);
uniform vec4 blue_bounds = vec4(0.0);
uniform vec4 yellow_bounds = vec4(0.0);
uniform vec4 boss_bounds = vec4(0.0);
uniform vec4 wing_strengths = vec4(0.0);
uniform vec2 world_tile_size = vec2(256.0);

varying vec2 world_position;

bool is_inside_bounds(vec2 position, vec4 bounds) {
	return (
		position.x >= bounds.x
		&& position.y >= bounds.y
		&& position.x <= bounds.z
		&& position.y <= bounds.w
	);
}

vec2 tile_center_for_position(vec2 position) {
	vec2 safe_tile_size = max(world_tile_size, vec2(1.0));
	return (
		floor(position / safe_tile_size) * safe_tile_size
		+ safe_tile_size * 0.5
	);
}

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	vec4 base = COLOR;
	float region_strength = 0.0;
	vec3 region_luminance_basis = vec3(1.0);
	vec2 region_sample_position = tile_center_for_position(world_position);

	// Match the controller's overlap priority. A wing with zero strength is
	// skipped, so entering one wing cannot recolor grass in another wing.
	// Sample bounds at the tile center so a room edge cannot split one tile
	// between recolored and original pixels.
	if (
		wing_strengths.w > 0.001
		&& is_inside_bounds(region_sample_position, boss_bounds)
	) {
		region_strength = wing_strengths.w;
		region_luminance_basis = boss_luminance_basis;
	} else if (
		wing_strengths.z > 0.001
		&& is_inside_bounds(region_sample_position, yellow_bounds)
	) {
		region_strength = wing_strengths.z;
		region_luminance_basis = yellow_luminance_basis;
	} else if (
		wing_strengths.y > 0.001
		&& is_inside_bounds(region_sample_position, blue_bounds)
	) {
		region_strength = wing_strengths.y;
		region_luminance_basis = blue_luminance_basis;
	} else if (
		wing_strengths.x > 0.001
		&& is_inside_bounds(region_sample_position, red_bounds)
	) {
		region_strength = wing_strengths.x;
		region_luminance_basis = red_luminance_basis;
	}

	if (region_strength > 0.001) {
		float mask_amount = texture(grass_mask, UV).r;
		if (mask_amount > 0.001) {
			float blend_amount = clamp(
				mask_amount * region_strength,
				0.0,
				1.0
			);
			float base_luminance = dot(
				base.rgb,
				vec3(0.2126, 0.7152, 0.0722)
			);
			vec3 recolored = clamp(
				region_luminance_basis * base_luminance,
				vec3(0.0),
				vec3(1.0)
			);
			base.rgb = mix(base.rgb, recolored, blend_amount);
		}
	}

	COLOR = base;
}
