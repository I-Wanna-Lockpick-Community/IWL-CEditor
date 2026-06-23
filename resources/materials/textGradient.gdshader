shader_type canvas_item;
instance uniform vec4 colorBottom:source_color;
instance uniform vec2 size;
varying vec2 vert;

void vertex() {
	vert = VERTEX;
}

void fragment() {
	vec4 color = mix(COLOR,colorBottom,vert.y/size.y);
	COLOR.rgb = color.rgb;
	COLOR.a *= color.a;
}
