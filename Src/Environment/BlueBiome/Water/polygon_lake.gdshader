shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 air_points[256];
uniform int air_counts[16];
uniform int pocket_count = 0;
uniform float surface_y = 450.0;
uniform bool submerged = false;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
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
	float wave=sin(world_position.y*.045+world_position.x*.004+TIME*.55)*.65
		+sin(world_position.y*.11-world_position.x*.009-TIME*.38)*.25;
	vec2 pixel=SCREEN_PIXEL_SIZE;
	float pixels_below=depth/max(abs(dFdy(world_position.y)),.001);
	vec2 reflected=SCREEN_UV-vec2(0.0,2.0*pixels_below*pixel.y);
	float valid=step(.001,reflected.y)*step(reflected.y,.999);
	reflected.x+=wave*pixel.x*3.0;
	vec3 reflection=texture(screen_texture,clamp(reflected,vec2(.001),vec2(.999))).rgb*.4;
	reflection+=texture(screen_texture,clamp(reflected+vec2(pixel.x*5.0,0),vec2(.001),vec2(.999))).rgb*.3;
	reflection+=texture(screen_texture,clamp(reflected-vec2(pixel.x*5.0,0),vec2(.001),vec2(.999))).rgb*.3;
	vec3 shallow=vec3(.12,.48,.59);
	vec3 deep=vec3(.018,.10,.18);
	vec3 water=mix(shallow,deep,smoothstep(0.0,1800.0,depth));
	float bands=.7+.3*sin(depth*.085+wave+TIME*.3);
	float strength=(submerged?.10:.40)*valid*(1.0-smoothstep(0.0,650.0,depth))*bands;
	water=mix(water,reflection*vec3(.65,.85,.9),strength);
	float rim=(1.0-smoothstep(0.0,8.0,depth))*(.6+.4*sin(world_position.x*.025-TIME*.65));
	water=mix(water,vec3(.65,.9,.91),rim*.6);
	float caustic=pow(max(0.0,sin(world_position.x*.013+world_position.y*.02+TIME*.4)*sin(world_position.x*.018-world_position.y*.01-TIME*.3)),12.0);
	water+=vec3(.06,.12,.10)*caustic*.3;
	COLOR=vec4(water,submerged?.23:.58);
}
