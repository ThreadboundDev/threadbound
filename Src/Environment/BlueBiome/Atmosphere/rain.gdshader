shader_type canvas_item;
render_mode unshaded;

uniform sampler2D shelter : repeat_disable, filter_nearest;
uniform float mask_left = -6000.0;
uniform float mask_width = 12000.0;
uniform float sky_y = -4600.0;
uniform float mask_depth = 8000.0;
uniform float slope = 0.12;
uniform float amount = 0.0;
uniform float clock = 0.0;
uniform vec4 dry_room_bounds = vec4(0.0);
uniform vec4 rain_color : source_color = vec4(0.64, 0.79, 0.89, 1.0);
varying vec2 world;

float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	float ray_x = world.x - slope * (world.y - sky_y);
	float u = (ray_x - mask_left) / mask_width;
	float stop_y = sky_y + texture(shelter, vec2(clamp(u, 0.0, 1.0), 0.5)).r * mask_depth;
	float visibility = 1.0 - smoothstep(stop_y - 3.0, stop_y, world.y);
	if (dry_room_bounds.z > dry_room_bounds.x) {
		vec2 room_edge = min(world - dry_room_bounds.xy, dry_room_bounds.zw - world);
		visibility *= 1.0 - smoothstep(-6.0, 3.0, min(room_edge.x, room_edge.y));
	}
	float streaks = 0.0;
	for (int i = 0; i < 2; i++) {
		float scale = i == 0 ? 1.0 : 0.67;
		vec2 p = vec2(ray_x, world.y) * scale;
		float cell = floor(p.x / 18.0);
		float seed = hash(cell + float(i) * 91.0);
		float x = mod(p.x, 18.0) - (3.0 + seed * 12.0);
		float y = mod(p.y - clock * (780.0 + seed * 260.0) * scale + seed * 650.0, 180.0);
		float line = (1.0 - smoothstep(0.25, 1.15, abs(x))) * (1.0 - smoothstep(18.0, 42.0, y));
		streaks += line * step(seed, amount) * (i == 0 ? 0.36 : 0.18);
	}
	COLOR = vec4(rain_color.rgb, streaks * visibility * amount);
}
