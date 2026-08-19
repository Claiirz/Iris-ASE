shader_type canvas_item;

uniform bool flash = false;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    if (flash) {
        COLOR = vec4(1.0, 1.0, 1.0, texture_color.a); // Replace RGB with white, keep original opacity
    } else {
        COLOR = texture_color;
    }
}