shader_type spatial;
uniform sampler2D dirt_detail: source_color, repeat_enable, filter_linear_mipmap;
varying vec3 world_point;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 a=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);
}
void vertex() { world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_point.xz;
 float n=noise(p*0.7)*0.7+noise(p*5.0)*0.3;
 float path_a=abs(p.x-sin(p.y*0.23)*0.5);
 float path_b=abs(p.y+8.0);
 float village=1.0-smoothstep(1.15,1.9,path_a+(noise(p*2.0)-0.5)*0.4);
 village*=1.0-smoothstep(9.0,17.0,abs(p.y));
 float bridge_path=(1.0-smoothstep(1.0,1.8,path_b))*(1.0-smoothstep(15.0,19.0,abs(p.x-7.0)));
 float worn=max(village,bridge_path);
 vec3 grass=mix(vec3(0.18,0.25,0.20),vec3(0.28,0.35,0.25),n);
 vec3 dirt=mix(vec3(0.29,0.25,0.18),vec3(0.42,0.36,0.25),n);
 ALBEDO=mix(grass,dirt,worn*0.85);
 vec3 detail=texture(dirt_detail,p*.33).rgb;
 ALBEDO*=mix(vec3(1.0),detail*1.3+vec3(.4),.24);
 ROUGHNESS=0.95;
}
