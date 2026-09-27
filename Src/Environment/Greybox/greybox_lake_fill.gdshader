shader_type canvas_item;
render_mode unshaded;
uniform vec2 air_points[256];
uniform int air_counts[16];
uniform int pocket_count = 0;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	int start = 0;
	for (int pocket = 0; pocket < pocket_count; pocket++) {
		int count = air_counts[pocket];
		bool inside = false;
		for (int i = 0; i < count; i++) {
			vec2 a = air_points[start+i];
			vec2 b = air_points[start+(i+count-1)%count];
			if ((a.y > world_position.y) != (b.y > world_position.y)) {
				float edge_x = (b.x-a.x)*(world_position.y-a.y)/(b.y-a.y)+a.x;
				if (world_position.x < edge_x) { inside = !inside; }
			}
		}
		if (inside) { discard; }
		start += count;
	}
}
