shader_type canvas_item;
render_mode unshaded;

// White luminance matte; identity accent lines were removed after visual review.
uniform float effect_fade = 1.0;
varying vec4 item_tint;
void vertex() { item_tint = COLOR; }
void fragment() {
    vec3 source = texture(TEXTURE, UV).rgb;
    float coverage = smoothstep(0.055, 0.92, max(source.r, max(source.g, source.b)));
    COLOR = vec4(item_tint.rgb, coverage * effect_fade * item_tint.a);
}
