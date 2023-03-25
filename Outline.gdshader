shader_type spatial;
render_mode unshaded, cull_back;

uniform float outline_thickness = 0.05; // how thick is the outline?
uniform vec4 color: source_color = vec4(0.0); // which color does the outline have?

void vertex() {
	VERTEX += NORMAL*outline_thickness; // apply the outlines thickness	
}

void fragment() {
	ALBEDO = color.rgb; // apply the outlines color
}