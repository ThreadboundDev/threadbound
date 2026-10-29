shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ripple_noise: repeat_enable, filter_linear_mipmap;
varying vec3 world_point;
void vertex(){
 world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y+=sin(VERTEX.x*1.8+TIME*.9)*.014+cos(VERTEX.z*1.1-TIME*.7)*.012;
}
void fragment(){
 vec2 p=world_point.xz*.13+vec2(TIME*.018,-TIME*.012);
 float n=texture(ripple_noise,p).r*.6+texture(ripple_noise,p*1.7-vec2(TIME*.01)).r*.4;
 float dx=texture(ripple_noise,p+vec2(.015,0.0)).r-texture(ripple_noise,p-vec2(.015,0.0)).r;
 float dz=texture(ripple_noise,p+vec2(0.0,.015)).r-texture(ripple_noise,p-vec2(0.0,.015)).r;
 NORMAL_MAP=vec3(.5-dx*.18,.5-dz*.18,1.0);
 float shore=1.0-smoothstep(0.0,.32,min(abs(world_point.x-8.0),abs(world_point.x-13.0)));
 float foam=shore*smoothstep(.48,.65,n+sin(world_point.z*4.0+TIME)*.10);
 ALBEDO=mix(vec3(.055,.22,.24)+n*.065,vec3(.69,.82,.76),foam*.65);
 ROUGHNESS=.24;METALLIC=.16;SPECULAR=.55;ALPHA=.84+foam*.12;
}
