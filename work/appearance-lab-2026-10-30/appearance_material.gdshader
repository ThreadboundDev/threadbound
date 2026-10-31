shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_back;
uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;
uniform bool use_normal = false;
uniform int mode = 0;
uniform int motif = 0;
uniform int mask_style = 0;
uniform bool softer_porcelain = false;
uniform vec4 identity_color : source_color = vec4(0.55,0.62,0.65,1.0);
uniform float identity_strength = 0.0;
void fragment() {
	vec3 rest_position = vec3(0.0,UV2.y,UV2.x);
	vec4 base = texture(base_texture,UV);
	float value = dot(base.rgb,vec3(.2126,.7152,.0722));
	float cool = smoothstep(.70,1.0,base.b/max(base.r,.001));
	float cloth = (1.0-smoothstep(.14,.27,value))*cool
		*smoothstep(.32,.48,rest_position.y)*(1.0-smoothstep(1.48,1.60,rest_position.y));
	vec3 color = mix(base.rgb,identity_color.rgb*clamp(value*2.6+.18,.18,.85),cloth*identity_strength);
	if (mode == 1 || mode == 3) {
		// Rest/UV coordinates move with the skinned surface, never screen space.
		float trim = max(1.0-smoothstep(.025,.075,abs(rest_position.y-.70)),
			1.0-smoothstep(.025,.055,abs(rest_position.y-1.18)));
		vec2 p = vec2(rest_position.z,rest_position.y)*24.0;
		vec2 cell = abs(fract(p)-.5);
		float mark = 1.0-smoothstep(.06,.11,abs(cell.x+cell.y-.38));
		if (motif == 1) mark=1.0-smoothstep(.07,.14,abs(sin((p.x+p.y)*3.14159)));
		if (motif == 2) mark=max(1.0-smoothstep(.05,.10,cell.x),1.0-smoothstep(.05,.10,cell.y));
		color=mix(color,vec3(.20,.11,.035),cloth*trim*mark*.88);
	}
	float face = smoothstep(1.53,1.58,rest_position.y)*smoothstep(.10,.28,value);
	if (mode == 2 || mode == 3) {
		vec2 f=vec2((rest_position.z-.10)*16.0,(rest_position.y-1.69)*14.0);
		float mark=1.0-smoothstep(.06,.12,abs(abs(f.y)*.70-abs(f.x)));
		vec3 ink=vec3(.02,.05,.055);
		if (mask_style == 1) { mark=smoothstep(-.05,.05,f.x); ink=vec3(.015,.03,.035); }
		if (mask_style == 2) { mark=1.0-smoothstep(.12,.20,abs(f.y+f.x*.65)); ink=vec3(.12,.025,.013); }
		color=mix(color,ink,face*mark*.95);
	}
	if (softer_porcelain) color=mix(color,color*.68,face);
	ALBEDO=color;
	ROUGHNESS=mix(.68,.88,softer_porcelain ? face : 0.0);
	SPECULAR=mix(.50,.18,softer_porcelain ? face : 0.0);
	if (use_normal) NORMAL_MAP=texture(normal_texture,UV).rgb;
}
