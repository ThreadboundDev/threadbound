shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D facade_reflection_texture : repeat_disable, filter_linear;
uniform bool has_facade_reflection = false;
uniform vec2 air_points[256];
uniform int air_counts[16];
uniform float air_feathers[16];
uniform int pocket_count = 0;
uniform float surface_y = 450.0;
uniform float water_opacity : hint_range(0.0, 1.0) = 0.34;
uniform vec4 shallow_color : source_color = vec4(.12,.48,.59,1.0);
uniform vec4 deep_color : source_color = vec4(.018,.10,.18,1.0);
varying vec2 world_position;
vec3 reflection_at(vec2 uv) {
	vec3 background=texture(screen_texture,uv).rgb;
	if (has_facade_reflection) {
		vec4 facade=texture(facade_reflection_texture,uv);
		background=mix(background,facade.rgb,facade.a);
	}
	return background;
}
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
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
	float wave=sin(world_position.y*.045+world_position.x*.004+TIME*.55)*.65
		+sin(world_position.y*.11-world_position.x*.009-TIME*.38)*.25;
	vec2 pixel=SCREEN_PIXEL_SIZE;
	float pixels_below=depth/max(abs(dFdy(world_position.y)),.001);
	vec2 reflected=SCREEN_UV-vec2(0.0,2.0*pixels_below*pixel.y);
	// Reflected samples eventually leave the visible screen as the source moves.
	// Fade that boundary over a small band instead of revealing the viewport as
	// a hard horizontal edge in the water.
	float valid=smoothstep(.001,.065,reflected.y)*(1.0-smoothstep(.935,.999,reflected.y));
	reflected.x+=wave*pixel.x*3.0;
	vec3 reflection=reflection_at(clamp(reflected,vec2(.001),vec2(.999)))*.4;
	reflection+=reflection_at(clamp(reflected+vec2(pixel.x*5.0,0),vec2(.001),vec2(.999)))*.3;
	reflection+=reflection_at(clamp(reflected-vec2(pixel.x*5.0,0),vec2(.001),vec2(.999)))*.3;
	vec3 water=mix(shallow_color.rgb,deep_color.rgb,smoothstep(0.0,1800.0,depth));
	float bands=.85+.15*sin(depth*.085+wave+TIME*.3);
	float strength=.48*valid*(1.0-smoothstep(0.0,650.0,depth))*bands;
	float rim=(1.0-smoothstep(0.0,8.0,depth))*(.6+.4*sin(world_position.x*.025-TIME*.65));
	water=mix(water,vec3(.65,.9,.91),rim*.6);
	float caustic=pow(max(0.0,sin(world_position.x*.013+world_position.y*.02+TIME*.4)*sin(world_position.x*.018-world_position.y*.01-TIME*.3)),12.0);
	water+=vec3(.06,.12,.10)*caustic*.3;
	// Reflection is its own surface coverage. Multiplying it by the already
	// translucent body a second time reduced it to almost nothing underwater.
	float alpha=water_opacity*(1.0-strength)+strength;
	vec3 premultiplied=water*water_opacity*(1.0-strength)
		+reflection*vec3(.78,.92,.98)*strength;
	COLOR=vec4(premultiplied/max(alpha,.0001),alpha*water_visibility);
}
