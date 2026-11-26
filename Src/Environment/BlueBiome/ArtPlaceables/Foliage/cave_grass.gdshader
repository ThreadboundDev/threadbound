shader_type canvas_item;

void vertex() {
	float height = 1.0 - UV.y;
	float phase = INSTANCE_CUSTOM.x * TAU;
	float world_x = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).x;
	float wind = sin(TIME * 1.9 + world_x * 0.007) * 0.044;
	wind += sin(TIME * 3.1 + phase) * 0.025;
	float contact = (INSTANCE_CUSTOM.y * 2.0 - 1.0) * 0.30;
	float tip = pow(height, 1.65);
	VERTEX.x += (wind + contact) * tip;
	VERTEX.y += abs(contact) * height * height * 0.48;
}
