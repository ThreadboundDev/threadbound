// Opt-in front water: painterly reflections outside, translucent grade inside.
// Reflection reads the explicit pre-actor lake capture, never the actor/VFX.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D facade_reflection_texture : repeat_disable, filter_linear;
uniform bool has_facade_reflection = false;
uniform bool painted_surface = false;
uniform float underwater_view : hint_range(0.0,1.0) = 0.0;
uniform float surface_opacity : hint_range(0.0,1.0) = 0.96;

vec3 painted_reflection_at(vec2 uv) {
	vec3 background=texture(screen_texture,uv).rgb;
	if (has_facade_reflection) {
		vec4 facade=texture(facade_reflection_texture,uv);
		background=mix(background,facade.rgb,facade.a);
	}
	return background;
}

vec4 painted_water(vec2 world, vec2 screen_uv, vec2 pixel, float clock) {
	float depth=max(0.0,world.y-surface_y);
	vec3 tint=mix(shallow_color.rgb,deep_color.rgb,smoothstep(0.0,1800.0,depth));
	float wave=sin(depth*.052+world.x*.003+clock*.55)*.7
		+sin(depth*.13-world.x*.008-clock*.35)*.3;
	float pixels_below=depth/max(abs(dFdy(world.y)),.001);
	vec2 reflected=screen_uv-vec2(0.0,2.0*pixels_below*pixel.y);
	float valid=smoothstep(.001,.065,reflected.y)*(1.0-smoothstep(.935,.999,reflected.y));
	reflected.x+=wave*pixel.x*5.0;
	vec3 reflection=painted_reflection_at(clamp(reflected,vec2(.001),vec2(.999)))*.5;
	reflection+=painted_reflection_at(clamp(reflected+vec2(pixel.x*7.0,0),vec2(.001),vec2(.999)))*.25;
	reflection+=painted_reflection_at(clamp(reflected-vec2(pixel.x*7.0,0),vec2(.001),vec2(.999)))*.25;
	float reflect_amount=.64*valid*(1.0-smoothstep(0.0,760.0,depth));
	vec3 surface=mix(tint*vec3(.92,1.10,1.04),reflection*vec3(.70,.93,.97),reflect_amount);
	// Broken horizontal brush strokes, with staggered lengths and gentle wind.
	float row=floor((depth+wave*3.0)/27.0);
	float seed=fract(sin(row*127.1)*43758.5453);
	float cell=fract(world.x/(95.0+seed*170.0)+seed*13.0+clock*.025);
	float stroke=(1.0-smoothstep(.04,.16,abs(fract((depth+wave*3.0)/27.0)-.5)))
		*smoothstep(.1,.25,cell)*(1.0-smoothstep(.53,.78,cell));
	float rim=(1.0-smoothstep(0.0,9.0,depth))*(.78+.22*sin(world.x*.031-clock*.8));
	surface=mix(surface,vec3(.62,.85,.84),stroke*(.10+seed*.10)+rim*.70);
	float current=sin(world.x*.035+world.y*.022+clock*.7)
		*sin(world.x*.018-world.y*.031-clock*.45);
	vec3 underwater=tint+vec3(.10,.17,.16)*pow(max(0.0,current),8.0);
	float wet_coverage=clamp(immersion_opacity*(1.0+smoothstep(0.0,900.0,depth)*.4),0.0,1.0);
	return vec4(mix(surface,underwater,underwater_view),mix(surface_opacity,wet_coverage,underwater_view));
}
