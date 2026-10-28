shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color:source_color=vec4(0.14,0.23,0.25,1.0);
varying vec3 local_point;
void vertex(){ local_point=VERTEX; }
void fragment(){
 vec2 p=local_point.xz*110.0+local_point.xy*70.0;
 float a=sin(p.x*6.283),b=sin(p.y*6.283);
 float weave=0.88+0.08*a+0.04*b;
 ALBEDO=cloth_color.rgb*weave;
 ROUGHNESS=0.94;
}
