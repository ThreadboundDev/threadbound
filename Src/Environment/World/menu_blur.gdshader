shader_type canvas_item;
render_mode blend_mix;

// Required for screen texture access in Godot 4
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Controls
uniform float blur_amount : hint_range(0.0, 8.0) = 2.5;      // 1.5–4.0 feels nice
uniform float blur_samples : hint_range(1, 9) = 5;            // more = smoother but slower
uniform float desaturation : hint_range(0.0, 1.0) = 0.65;    // how grey to make it
uniform float blue_tint_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 blue_tint_color : source_color = vec4(0.75, 0.85, 1.0, 1.0); // soft cool blue

void fragment() {
    vec2 ps = SCREEN_PIXEL_SIZE;
    vec4 color = vec4(0.0);
    float total_weight = 0.0;

    // Simple multi-tap Gaussian-like blur
    for (float x = -blur_samples; x <= blur_samples; x += 1.0) {
        for (float y = -blur_samples; y <= blur_samples; y += 1.0) {
            vec2 offset = vec2(x, y) * ps * blur_amount;
            float weight = exp(-(x*x + y*y) / (2.0 * blur_samples * blur_samples));
            color += texture(SCREEN_TEXTURE, SCREEN_UV + offset) * weight;
            total_weight += weight;
        }
    }
    color /= total_weight;

    // Desaturate (grey out the background)
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desat = mix(color.rgb, vec3(lum), desaturation);

    // Apply subtle blue tint
    vec3 tinted = mix(desat, blue_tint_color.rgb, blue_tint_strength * blue_tint_color.a);

    COLOR = vec4(tinted, 1.0);
}