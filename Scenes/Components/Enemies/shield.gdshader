shader_type canvas_item;

uniform sampler2D shield_100_texture;
uniform sampler2D shield_50_texture;
uniform sampler2D shield_25_texture;

uniform float flash_intensity : hint_range(0, 1);
uniform float shield_value : hint_range(0, 1);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
	vec4 shield_tex = shield_value < 0.3 ? texture(shield_25_texture, UV) : (shield_value < 0.75 ? texture(shield_50_texture, UV) : texture(shield_100_texture, UV));

    vec4 flash_color = shield_value == 0.0 ? vec4(1.5, 0.13, 0.1, tex_color.a) : (shield_value < 0.3 ? vec4(1.0, 0.718, 0.141, tex_color.a) : vec4(0.122, 0.71, 1.5, tex_color.a));
    COLOR = shield_value <= 0.0 ? mix(tex_color, flash_color, flash_intensity) : mix(tex_color, flash_color * shield_tex, flash_intensity);
}