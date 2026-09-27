shader_type canvas_item;
render_mode unshaded;

uniform vec4 lake_color : source_color = vec4(0.404, 0.725, 0.812, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 distant = mix(source.rgb, vec3(0.45, 0.70, 0.78), 0.30);
	if (UV.y >= 0.61) {
		// Keep the lake opaque despite the generated plate's soft lower alpha.
		distant = mix(lake_color.rgb, distant, source.a);
		distant = mix(distant, lake_color.rgb, smoothstep(0.78, 1.0, UV.y));
		COLOR = vec4(distant, 1.0);
	} else {
		COLOR = vec4(distant, source.a);
	}
}
