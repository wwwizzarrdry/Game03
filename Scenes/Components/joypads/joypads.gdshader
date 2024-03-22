shader_type canvas_item;

uniform vec3 base_darkness_color : source_color = vec3(0.2, 0.2, 0.2); // base color
uniform float lower_limit : hint_range(0, 1) = 0.6; // lower limit of brightness range
uniform float upper_limit : hint_range(0, 1) = 0.8; // upper limit of brightness range
uniform float fade_speed : hint_range(0, 10) = 1.0; // speed of the fade effect
uniform float darken_factor : hint_range(0, 1) = 0.5; // factor to darken the whole image

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float brightness = dot(tex.rgb, vec3(0.299, 0.587, 0.114)); // calculate brightness
    float fade_r = 0.5 * (1.0 + sin(TIME * fade_speed)) + base_darkness_color.r; // calculate fade effect for red channel
    float fade_g = 0.5 * (1.0 + sin(TIME * fade_speed + PI/3.0)) + base_darkness_color.g; // calculate fade effect for green channel
    float fade_b = 0.5 * (1.0 + sin(TIME * fade_speed + 2.0*PI/3.0)) + base_darkness_color.b; // calculate fade effect for blue channel
    if (brightness > lower_limit && brightness < upper_limit) {
        tex.rgb.r *= fade_r; // apply fade effect to red channel
        tex.rgb.g *= fade_g; // apply fade effect to green channel
        tex.rgb.b *= fade_b; // apply fade effect to blue channel
    } else {
        tex.rgb *= darken_factor; // darken the whole image
    }
    COLOR = tex;
}