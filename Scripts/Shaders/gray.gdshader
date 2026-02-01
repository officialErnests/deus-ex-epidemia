shader_type canvas_item;

void fragment() {
	float total = (COLOR.r + COLOR.g + COLOR.b);
	COLOR = vec4(total, total, total, COLOR.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
