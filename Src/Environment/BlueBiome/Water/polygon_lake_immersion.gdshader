shader_type canvas_item;
render_mode unshaded;
uniform vec2 air_points[256];
uniform int air_counts[16];
uniform float air_feathers[16];
uniform int pocket_count = 0;
uniform float surface_y = 411.0;
uniform float immersion_opacity : hint_range(0.0,1.0) = .22;
uniform vec4 shallow_color : source_color = vec4(.12,.48,.59,1.0);
uniform vec4 deep_color : source_color = vec4(.018,.10,.18,1.0);
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	int start = 0;
	float water_visibility = 1.0;
	for (int pocket=0; pocket<pocket_count; pocket++) {
		int count=air_counts[pocket];
		bool inside=false;
		float nearest = 1e20;
		for (int i=0; i<count; i++) {
			vec2 a=air_points[start+i];
			vec2 b=air_points[start+(i+count-1)%count];
			if (air_feathers[pocket] > 0.0) {
				vec2 edge=b-a;
				vec2 delta=world_position-a-edge*clamp(dot(world_position-a,edge)/max(dot(edge,edge),.001),0.0,1.0);
				nearest=min(nearest,dot(delta,delta));
			}
			if ((a.y>world_position.y)!=(b.y>world_position.y)) {
				if (world_position.x<(b.x-a.x)*(world_position.y-a.y)/(b.y-a.y)+a.x) { inside=!inside; }
			}
		}
		if (air_feathers[pocket] > 0.0) {
			float distance=sqrt(nearest)*(inside ? -1.0 : 1.0);
			water_visibility=min(water_visibility,smoothstep(-air_feathers[pocket],air_feathers[pocket],distance));
		} else if (inside) { discard; }
		start+=count;
	}
	float depth=max(0.0,world_position.y-surface_y);
	vec3 tint=mix(shallow_color.rgb,deep_color.rgb,smoothstep(0.0,1800.0,depth));
	// World-space movement and depth keep the swimmer inside the water without
	// fading the entire environment whenever the observer crosses the surface.
	float current=sin(world_position.x*.035+world_position.y*.022+TIME*.7)
		*sin(world_position.x*.018-world_position.y*.031-TIME*.45);
	float light=pow(max(0.0,current),8.0);
	tint+=vec3(.10,.17,.16)*light;
	float coverage=clamp(immersion_opacity*(1.0+smoothstep(0.0,900.0,depth)*.4),0.0,1.0);
	COLOR=vec4(tint,coverage*water_visibility);
}
