shader_type canvas_item;

void fragment() {
	float red_intensity = 1.0f;
	red_intensity = modf(sin(TIME),red_intensity);
	COLOR = vec4(red_intensity, 0, 0, 1);
}