shader_type canvas_item;
// Exact painted rail/post pixels, excluding the deck plane of approved J03.
void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	bool post = (pixel.x >= 45.0 && pixel.x <= 145.0)
		|| (pixel.x >= 697.0 && pixel.x <= 801.0)
		|| (pixel.x >= 1274.0 && pixel.x <= 1388.0)
		|| (pixel.x >= 1940.0 && pixel.x <= 2043.0);
	if (pixel.y > 198.0 && !post) COLOR.a = 0.0;
}
