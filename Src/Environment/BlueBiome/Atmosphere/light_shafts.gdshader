shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D shelter : repeat_disable, filter_nearest;
uniform float mask_left = -6000.0;
uniform float mask_width = 12000.0;
uniform float sky_y = -4600.0;
uniform float mask_depth = 8000.0;
uniform float slope = 0.0;
uniform float strength = 0.0;
uniform float clock = 0.0;
uniform vec4 shaft_color : source_color = vec4(1.0, 0.91, 0.73, 1.0);
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	float ray_x = world.x - slope * (world.y - sky_y);
	float u = (ray_x - mask_left) / mask_width;
	float stop_y = sky_y + texture(shelter, vec2(clamp(u, 0.0, 1.0), 0.5)).r * mask_depth;
	float visibility = 1.0 - smoothstep(stop_y - 7.0, stop_y, world.y);
	float bands = pow(max(0.0, sin(ray_x * 0.009 + sin(ray_x * 0.003 + clock * 0.025))), 8.0);
	float fine = pow(max(0.0, sin(ray_x * 0.021 + 1.7)), 12.0);
	COLOR = vec4(shaft_color.rgb, (bands * 0.075 + fine * 0.025) * strength * visibility);
}
