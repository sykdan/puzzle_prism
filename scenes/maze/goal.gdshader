shader_type spatial;

void fragment() {
	ALBEDO = vec3(0.2, 1.0, 0.2);
	ALPHA = sin(TIME) * sin(TIME) * 0.6 + 0.1;
}