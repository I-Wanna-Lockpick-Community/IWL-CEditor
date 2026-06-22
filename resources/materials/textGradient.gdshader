shader_type canvas_item;
instance uniform vec4 colorBottom:source_color;
instance uniform vec2 size;
varying vec2 vert;

vec4 lerpColor(vec4 color1, vec4 color2, float t) {
	return color1 * (1.0-t) + color2 * t;
}

void vertex() {
	vert = VERTEX;
}

void fragment() {
	vec4 color = lerpColor(COLOR,colorBottom,vert.y/size.y);
	COLOR.rgb = color.rgb;
	COLOR.a *= color.a;
}
