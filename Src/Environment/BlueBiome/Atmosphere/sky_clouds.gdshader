shader_type canvas_item;
render_mode unshaded;

uniform float coverage = 0.0;
uniform float clock = 0.0;
uniform float flash = 0.0;
uniform vec4 cloud_color : source_color = vec4(0.44, 0.53, 0.64, 1.0);
varying vec2 world;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	vec2 p = world * vec2(0.0009, 0.0023) + vec2(-clock * 0.008, 0.0);
	float n = noise(p) * 0.6 + noise(p * 2.13) * 0.28 + noise(p * 4.1) * 0.12;
	float cloud = smoothstep(0.64 - coverage * 0.34, 0.86 - coverage * 0.32, n);
	float alpha = cloud * mix(0.20, 0.87, coverage) + coverage * 0.12;
	float rolling_flash = flash * smoothstep(0.25, 0.78, noise(p * 1.8 + vec2(clock * 0.3, 7.0)));
	vec3 color = cloud_color.rgb + vec3(0.65, 0.73, 0.85) * rolling_flash;
	COLOR = vec4(color, clamp(alpha + rolling_flash * 0.15, 0.0, 0.95));
}
