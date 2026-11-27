shader_type canvas_item;

instance uniform float contact_bend = 0.0;
instance uniform bool flip_horizontal = false;
instance uniform float stamp_width = 100.0;
instance uniform float stamp_height = 44.0;

void vertex() {
	float height = 1.0 - UV.y;
	float world_x = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).x;
	float wind = sin(TIME * 1.9 + world_x * 0.007) * 0.066;
	wind += sin(TIME * 3.1 + world_x * 0.046) * 0.024;
	float contact = contact_bend * 0.32;
	VERTEX.x += (wind + contact) * pow(height, 1.65) * stamp_width;
	VERTEX.y += abs(contact) * height * height * 0.50 * stamp_height;
	if (flip_horizontal) {
		UV.x = 1.0 - UV.x;
	}
}
