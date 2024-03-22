shader_type canvas_item;

uniform float zoom: hint_range(0.0, 100.0) = 50.0;

vec2 rotate2D(vec2 _st, float _angle){
    _st -= 0.5;
    _st =  mat2(vec2(cos(_angle), sin(_angle)), vec2(-sin(_angle), cos(_angle))) * _st;
    _st += 0.5;
    return _st;
}

vec2 tile(vec2 _st, float _zoom){
    _st *= _zoom;
    return fract(_st);
}

float box(vec2 _st, vec2 _size, float _smoothEdges){
    _size = vec2(0.5)-_size*0.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_st);
    uv *= smoothstep(_size,_size+aa,vec2(1.0)-_st);
    return uv.x*uv.y;
}

void fragment(){
    vec2 st = UV;
    vec3 color = vec3(0.0);

    // Divide the space in 4
    st = tile(st, zoom);

    // Use a matrix to rotate the space 45 degrees
    st = rotate2D(st,PI*0.25);

    // Draw a square
    color = vec3(box(st,vec2(0.7),0.01));

    COLOR = vec4(color,1.0);
}