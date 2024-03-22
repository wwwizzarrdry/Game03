shader_type canvas_item;
render_mode blend_mix;

const float TWO_PI = 6.283185307179586;

uniform float grid_size : hint_range(1.0, 1000.0) = 100.0;
uniform vec4 grid_color : source_color = vec4(0.071, 0.004, 0.0, 1.0);
uniform vec2 player_position_0 = vec2(-10000, -10000);
uniform vec2 player_position_1 = vec2(-10000, -10000);
uniform vec2 player_position_2 = vec2(-10000, -10000);
uniform vec2 player_position_3 = vec2(-10000, -10000);
uniform vec3 player_color_0 : source_color = vec3(1.0, 0.0, 0.0); // Red
uniform vec3 player_color_1 : source_color = vec3(0.0, 0.0, 1.0); // Blue
uniform vec3 player_color_2 : source_color = vec3(0.0, 1.0, 0.0); // Green
uniform vec3 player_color_3 : source_color = vec3(1.0, 1.0, 0.0); // Yellow
uniform float texture_size = 1.0;
uniform float radius : hint_range(0.1, 100.0) = 5.5;

vec2 grid(in vec2 uv, in float size) { 
    return fract(uv * size);
}

vec4 getColor(in vec2 coord, in vec2 tile_coord, in vec2 player_position, in vec3 player_color, in float _radius) {
    vec2 diff = tile_coord - player_position;
    float dist = length(diff);
    if (dist <= _radius / texture_size) {
        float t = smoothstep(0.0, _radius / texture_size, dist);
        vec3 color = mix(player_color, grid_color.rgb, t);
        return vec4(color, grid_color.a * (1.0 - t));
    }
    // Return a transparent color for tiles outside the radius
    return vec4(0.0, 0.0, 0.0, 0.5);
}

void fragment() {
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 frag = (2.0 * FRAGCOORD.xy - res.xy) / res.y;

    frag = grid(UV, grid_size);
    vec2 tile_coord = floor(UV*grid_size);
	
	float animatedRadius = radius - sin(TIME) * radius/8.0;
    vec4 color = getColor(frag, tile_coord, player_position_0, player_color_0, animatedRadius);
    color = max(color, getColor(frag, tile_coord, player_position_1, player_color_1, animatedRadius));
    color = max(color, getColor(frag, tile_coord, player_position_2, player_color_2, animatedRadius));
    color = max(color, getColor(frag, tile_coord, player_position_3, player_color_3, animatedRadius));
 
    vec2 black = smoothstep(1.08, 0.95, cos(frag * TWO_PI));
    color.rgb *= black.x * black.y * smoothstep(1.0, 0.0, length(fract(frag) - 0.5));

    COLOR = vec4(color.rgb, 0.75);
}