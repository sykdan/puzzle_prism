shader_type spatial;

uniform float bar_size;

void fragment() {
	int a = int((UV.x + UV.y) * 14.0);
	if (a % 2 == 0) {
		ALBEDO *= 0.05;
	} else {
		ALBEDO *= 0.2;
	}
}
