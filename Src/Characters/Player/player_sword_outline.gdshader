shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 outline_color : source_color = vec4(0.015, 0.012, 0.012, 1.0);
uniform float outline_source_pixels = 5.0;

void vertex() {
	vec4 position = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
	vec2 direction = view_normal.xy;
	// Preserve the projected normal's length. Normalizing almost face-on
	// surfaces pushed their tip vertices sideways into separate spikes.
	position.xy += direction * (2.0 * outline_source_pixels / VIEWPORT_SIZE) * position.w;
	// Keep the expanded back faces behind the sword's own visible surface.
	if (CURRENT_RENDERER == RENDERER_COMPATIBILITY) {
		position.z += 0.000001 * position.w;
	} else {
		position.z -= 0.000001 * position.w;
	}
	POSITION = position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
