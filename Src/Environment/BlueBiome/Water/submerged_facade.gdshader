shader_type canvas_item;
render_mode unshaded;
uniform vec2 lake_points[256];
uniform int lake_count = 0;
uniform float surface_y = 411.0;
uniform float water_opacity = .34;
uniform vec4 shallow_color : source_color = vec4(.12,.48,.59,1.0);
uniform vec4 deep_color : source_color = vec4(.018,.10,.18,1.0);
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec4 source=texture(TEXTURE,UV);
	bool wet=false;
	for (int i=0; i<lake_count; i++) {
		vec2 a=lake_points[i];
		vec2 b=lake_points[(i+lake_count-1)%lake_count];
		if ((a.y>world_position.y)!=(b.y>world_position.y)) {
			if (world_position.x<(b.x-a.x)*(world_position.y-a.y)/(b.y-a.y)+a.x) { wet=!wet; }
		}
	}
	if (wet) {
		// This pass contains exterior facades only. Dry room masks apply to
		// the interior behind it; they must never punch a dry hole in the wall.
		float depth=max(0.0,world_position.y-surface_y);
		vec3 tint=mix(shallow_color.rgb,deep_color.rgb,smoothstep(0.0,1800.0,depth));
		source.rgb=mix(source.rgb,tint,water_opacity);
	}
	COLOR=source;
}
