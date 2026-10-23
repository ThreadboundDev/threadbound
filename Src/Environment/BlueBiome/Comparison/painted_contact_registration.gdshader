shader_type canvas_item;
// Inverse lookup of an authored contact grid. This fits the illustration to
// physical floors without changing the PNG, collision, or overall envelope.
uniform vec4 atlas_region;
uniform vec2 atlas_size;
uniform int row_count = 2;
uniform vec2 rows[24]; // destination Y, source Y (region-normalized)
uniform vec2 columns[192]; // eight destination/source X knots per row
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

float source_x(int row, float x) {
	int base = row * 8;
	for (int i = 1; i < 8; i++) {
		vec2 a = columns[base + i - 1];
		vec2 b = columns[base + i];
		if (x <= b.x) {
			return mix(a.y, b.y, clamp((x-a.x)/max(b.x-a.x,0.00001),0.0,1.0));
		}
	}
	return 1.0;
}

void fragment() {
	vec2 local_uv = (UV * atlas_size - atlas_region.xy) / atlas_region.zw;
	vec2 source_uv = local_uv;
	for (int i = 1; i < 24; i++) {
		if (i >= row_count) { break; }
		if (local_uv.y <= rows[i].x) {
			vec2 a = rows[i-1];
			vec2 b = rows[i];
			float t = clamp((local_uv.y-a.x)/max(b.x-a.x,0.00001),0.0,1.0);
			source_uv.y = mix(a.y,b.y,t);
			source_uv.x = mix(source_x(i-1,local_uv.x),source_x(i,local_uv.x),t);
			break;
		}
	}
	vec2 sample_uv = (atlas_region.xy + source_uv * atlas_region.zw) / atlas_size;
	vec2 half_pixel = vec2(0.5)/atlas_size;
	sample_uv = clamp(sample_uv,atlas_region.xy/atlas_size+half_pixel,
		(atlas_region.xy+atlas_region.zw)/atlas_size-half_pixel);
	COLOR = texture(TEXTURE,sample_uv)*tint;
}
