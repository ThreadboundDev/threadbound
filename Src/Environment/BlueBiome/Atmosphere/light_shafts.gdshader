shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D shelter : repeat_disable, filter_nearest;
uniform vec2 source_position;
uniform float ray_range = 14000.0;
uniform float strength = 0.0;
uniform float clock = 0.0;
uniform vec4 shaft_color : source_color = vec4(1.0, 0.91, 0.73, 1.0);
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	vec2 from_source = world - source_position;
	float angle = atan(from_source.x, max(from_source.y, 0.001));
	float distance_to_light = length(from_source);
	float u = angle / PI + 0.5;
	float stop_distance = texture(shelter, vec2(u, 0.5)).r * ray_range;
	float visibility = (1.0 - smoothstep(stop_distance - 7.0, stop_distance, distance_to_light));
	float fade = smoothstep(30.0, 145.0, distance_to_light) * smoothstep(0.0, 0.17, cos(angle));
	float bands = pow(max(0.0, sin(angle * 27.0 + sin(angle * 9.0 + clock * 0.025))), 8.0);
	float fine = pow(max(0.0, sin(angle * 62.0 + 1.7)), 12.0);
	COLOR = vec4(shaft_color.rgb, (bands * 0.075 + fine * 0.025) * strength * visibility * fade * step(0.0, from_source.y));
}
