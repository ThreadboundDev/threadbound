shader_type canvas_item;

// Image generation returned a baked neutral checker field. Remove only bright,
// low-chroma pixels; saturated cyan blades and coral warning edges survive.
uniform float luminance_start : hint_range(0.5, 1.0) = 0.82;
uniform float luminance_end : hint_range(0.5, 1.0) = 0.94;
uniform float chroma_keep : hint_range(0.0, 0.3) = 0.10;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float highest = max(source.r, max(source.g, source.b));
	float lowest = min(source.r, min(source.g, source.b));
	float chroma = highest - lowest;
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	float bright_neutral = smoothstep(luminance_start, luminance_end, luminance);
	float neutral = 1.0 - smoothstep(chroma_keep * 0.45, chroma_keep, chroma);
	float keyed = bright_neutral * neutral;
	COLOR = vec4(source.rgb, source.a * (1.0 - keyed));
}
