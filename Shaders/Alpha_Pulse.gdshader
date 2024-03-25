shader_type canvas_item;

uniform bool is_pulsing = true;
uniform float speed = 2.0;

void fragment() {
    float alpha = 1.0;
    if (is_pulsing) {
        alpha = (sin(TIME * speed) + 1.0) / 2.0;
    }
    COLOR.a *= alpha;
}
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
