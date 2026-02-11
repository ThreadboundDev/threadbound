shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0; // Tune: 1.5-3.0 for subtle

void fragment() {
    vec2 ps = SCREEN_PIXEL_SIZE;
    vec4 color = vec4(0.0);
    
    // Simple 5-tap Gaussian blur
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-ps.x, -ps.y) * blur_amount) * 0.25;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2( ps.x, -ps.y) * blur_amount) * 0.25;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-ps.x,  ps.y) * blur_amount) * 0.25;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2( ps.x,  ps.y) * blur_amount) * 0.25;
    
    COLOR = color;
}