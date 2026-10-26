shader_type canvas_item;
// Animate the living water inside the sac; its rim, petals and stem stay fixed.
uniform vec4 atlas_region;
uniform vec2 atlas_size;
uniform float current_time = 0.0;
uniform float idle_energy = 1.0;
varying vec4 tint;
void vertex() { tint=COLOR; }
void fragment() {
	vec2 p=UV*atlas_size-atlas_region.xy;
	vec2 q=(p-vec2(285.0,404.0))/vec2(130.0,134.0);
	float r=length(q);
	float interior=(1.0-smoothstep(.65,.90,r))*smoothstep(326.0,354.0,p.y)*idle_energy;
	float angle=atan(q.y,q.x);
	float flow=sin(angle*3.0-r*8.0+current_time*3.4);
	vec2 tangent=vec2(-q.y,q.x);
	vec2 displacement=tangent*flow*4.0*interior;
	vec4 source=texture(TEXTURE,(atlas_region.xy+p+displacement)/atlas_size);
	float blue=smoothstep(.03,.16,source.b-source.r);
	float current=pow(max(0.0,sin(angle*2.0+r*15.0-current_time*2.8)),10.0);
	float bubbles=0.0;
	for(int i=0;i<5;i++) {
		float seed=float(i);
		vec2 bubble=vec2(sin(seed*2.4+current_time*.65)*.46, .65-fract(current_time*.23+seed*.21)*1.3);
		float distance=length(q-bubble);
		bubbles+=exp(-pow((distance-(.024+seed*.003))/.012,2.0));
	}
	source.rgb+=vec3(.06,.21,.25)*(current*.65+bubbles*.9)*interior*blue;
	COLOR=source*tint;
}
