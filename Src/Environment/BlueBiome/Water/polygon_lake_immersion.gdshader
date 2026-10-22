shader_type canvas_item;
render_mode unshaded;
uniform vec2 air_points[256];
uniform int air_counts[16];
uniform int pocket_count = 0;
uniform float surface_y = 411.0;
uniform float water_opacity = .34;
uniform vec4 shallow_color : source_color = vec4(.12,.48,.59,1.0);
uniform vec4 deep_color : source_color = vec4(.018,.10,.18,1.0);
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	int start = 0;
	for (int pocket=0; pocket<pocket_count; pocket++) {
		int count=air_counts[pocket];
		bool inside=false;
		for (int i=0; i<count; i++) {
			vec2 a=air_points[start+i];
			vec2 b=air_points[start+(i+count-1)%count];
			if ((a.y>world_position.y)!=(b.y>world_position.y)) {
				if (world_position.x<(b.x-a.x)*(world_position.y-a.y)/(b.y-a.y)+a.x) { inside=!inside; }
			}
		}
		if (inside) { discard; }
		start+=count;
	}
	float depth=max(0.0,world_position.y-surface_y);
	vec3 tint=mix(shallow_color.rgb,deep_color.rgb,smoothstep(0.0,1800.0,depth));
	COLOR=vec4(tint,min(water_opacity*.45,.12));
}
