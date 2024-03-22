shader_type canvas_item;

uniform float edge_threshold : hint_range(0, 1) = 0.2; // edge detection threshold
uniform float line_thickness : hint_range(0, 1) = 0.01; // line thickness

void fragment() {
    vec2 resolution = vec2(textureSize(TEXTURE, 0));
    vec2 uv = UV;
    vec3 tex = texture(TEXTURE, uv).rgb;
    vec3 tex_left = texture(TEXTURE, uv + vec2(-line_thickness, 0.0) / resolution).rgb;
    vec3 tex_right = texture(TEXTURE, uv + vec2(line_thickness, 0.0) / resolution).rgb;
    vec3 tex_up = texture(TEXTURE, uv + vec2(0.0, -line_thickness) / resolution).rgb;
    vec3 tex_down = texture(TEXTURE, uv + vec2(0.0, line_thickness) / resolution).rgb;
    float edge = length(tex - tex_left) + length(tex - tex_right) + length(tex - tex_up) + length(tex - tex_down);
    if (edge > edge_threshold) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // black outline
    } else {
        COLOR = vec4(tex, 1.0); // original color
    }
}