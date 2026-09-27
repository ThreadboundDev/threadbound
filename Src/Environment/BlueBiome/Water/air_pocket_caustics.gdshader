shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 boundary[256];
uniform int boundary_count = 0;
uniform float pocket_top = 0.0;
uniform float pocket_bottom = 1000.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.22;
varying vec2 local_position;
varying vec2 world_position;

void vertex() {
	local_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float edge_distance = 100000.0;
	for (int i = 0; i < boundary_count; i++) {
		vec2 a = boundary[i];
		vec2 b = boundary[(i + 1) % boundary_count];
		vec2 segment = b - a;
		float along = clamp(dot(local_position-a, segment) / max(dot(segment,segment), 0.001), 0.0, 1.0);
		edge_distance = min(edge_distance, length(local_position-a-segment*along));
	}
	vec2 p = world_position * vec2(0.023, 0.035);
	float time = TIME * 0.32;
	p += vec2(sin(p.y*0.65+time), cos(p.x*0.48-time*0.7))*0.65;
	float field = sin(p.x+time) * cos(p.y-time*0.6) + sin(p.x*0.7+p.y*0.9-time*0.8)*0.55;
	float caustic = pow(1.0-smoothstep(0.025,0.25,abs(field)), 2.0);
	float depth = clamp((local_position.y-pocket_top)/max(pocket_bottom-pocket_top,1.0),0.0,1.0);
	float rim = exp(-edge_distance/12.0)*(0.7+0.3*sin(time*1.4+p.x*0.35));
	// Concentrate refracted light near the lower boundary, leaving the air clear.
	float floor_light = smoothstep(0.35,0.9,depth)*exp(-edge_distance/160.0);
	float glow = intensity*(rim*0.65+caustic*(0.08+floor_light*0.9));
	COLOR = vec4(vec3(0.48,0.86,1.0),glow);
}
