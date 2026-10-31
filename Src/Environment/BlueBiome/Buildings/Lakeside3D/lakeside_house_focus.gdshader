shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_texture: hint_screen_texture, repeat_disable, filter_linear;
uniform vec4 room_screen_rect;
uniform vec2 logical_size = vec2(1920.0,1080.0);
uniform float focus_strength = 0.0;
void fragment() {
	vec3 scene=texture(scene_texture,SCREEN_UV).rgb;
	vec2 edge=min(SCREEN_UV-room_screen_rect.xy,room_screen_rect.zw-SCREEN_UV)*logical_size;
	float outside=1.0-smoothstep(-8.0,12.0,min(edge.x,edge.y));
	float luminance=dot(scene,vec3(.2126,.7152,.0722));
	vec3 quiet=mix(scene,vec3(luminance),.48)*.34;
	COLOR=vec4(mix(scene,quiet,outside*focus_strength),1.0);
}
