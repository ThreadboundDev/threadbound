shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 outline_color : source_color = vec4(0.015, 0.012, 0.012, 1.0);
uniform float outline_source_pixels = 6.0;
uniform bool fine_hat_detail = false;

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 projected = PROJECTION_MATRIX * view_position;
	// The outline-only mesh carries welded silhouette normals. Keep their
	// projected length so face-on tips do not split into sideways spikes.
	vec3 view_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
	float units_per_pixel = 2.0 * abs(projected.w) / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);
	// Expand a real 3D shell, including depth. A screen-only displacement can
	// move a back face over a nearer fold without moving that back face away.
	float detail_scale = fine_hat_detail ? mix(1.0, 0.25, smoothstep(1.68, 1.75, VERTEX.y)) : 1.0;
	view_position.xyz += view_normal * (units_per_pixel * outline_source_pixels * detail_scale);
	// Keep the hull behind the source surface at folds and thin accessories.
	// Its lateral expansion still supplies the edge where no source face covers it.
	view_position.z -= units_per_pixel * outline_source_pixels * detail_scale * 2.0;
	projected = PROJECTION_MATRIX * view_position;
	if (CURRENT_RENDERER == RENDERER_COMPATIBILITY) {
		projected.z += 0.000001 * projected.w;
	} else {
		projected.z -= 0.000001 * projected.w;
	}
	POSITION = projected;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
