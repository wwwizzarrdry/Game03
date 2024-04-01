shader_type canvas_item;

uniform sampler2D noise_tex_normal;
uniform sampler2D noise_tex;
uniform float progress : hint_range(0.0, 1.0);
uniform float strength = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
    vec2 direction = texture(noise_tex_normal, UV).xy;
    direction -= 0.5;
    direction *= 2.0;
    direction = direction * strength * progress;

    vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 uv = floor(UV * tex_size) / (tex_size - 1.0);
    uv = uv - direction;

    vec4 tex = texture(TEXTURE, uv);

    float dissolve = texture(noise_tex, UV).x;
    dissolve = step(progress, dissolve);
    tex.a *= dissolve;

    vec2 border_uv = uv * 2.0 - 1.0;
    border_uv = clamp(abs(border_uv), 0.0, 1.0);
    float border = max(border_uv.x, border_uv.y);
    border = ceil(1.0 - border);
    tex.a *= border;

    COLOR = tex;
}