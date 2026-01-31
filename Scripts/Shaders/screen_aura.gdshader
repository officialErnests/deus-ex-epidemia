shader_type canvas_item;
uniform float fromTop = .2f;
void fragment() {
	float red_intensity = 1.0f;
	float red_intensity2 = 1.0f;
	float red_intensity3 = 1.0f;
	float red_combined = 1.0f;
	red_intensity =  modf(sin(TIME + UV.x * 10.0f) + cos(TIME * 0.1f + UV.x * 10.0f),red_intensity);
	red_intensity2 = modf(sin(TIME * -1.2f + UV.x * 10.0f) + cos(TIME * 0.1f + UV.x * 1.0f),red_intensity2);
	red_intensity3 = modf(sin(TIME * -1.6f + UV.x * 20.0f) + sin(TIME * 1.0f + UV.x * 5.0f),red_intensity3);
	red_combined = modf(red_intensity + red_intensity2 + red_intensity3,red_combined);
	//red_combined = red_intensity;
	//red_combined = red_intensity2;
	//red_combined = red_intensity3;
	//red_combined = red_intensity + red_intensity2 + red_intensity3;
	COLOR = vec4(COLOR.r, COLOR.g, COLOR.b, (red_combined * UV.y + (pow(abs(UV.x * 2.f - 1.f), 4)) - fromTop - (1.f-abs(.5f - UV.x)) * .5f) * COLOR.a);
	//COLOR = vec4(0, 0,UV.y + (pow(abs(UV.x * 2.f - 1.f), 4)) - .7f, 1);
	//red_combined *  UV.y + 4
}