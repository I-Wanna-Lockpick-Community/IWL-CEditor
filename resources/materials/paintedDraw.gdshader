shader_type canvas_item;
render_mode blend_add;
uniform vec3 colorTop:source_color;
uniform vec3 colorBottom:source_color;

vec3 lerpColor(vec3 color1, vec3 color2, float t) {
	return color1 * (1.0-t) + color2 * t;
}

void fragment() {
	vec2 scale = round(vec2(1.0/COLOR.r, 1.0/COLOR.g)) / 128.0;
	COLOR.rgb = lerpColor(colorTop, colorBottom, UV.y/scale.y);
}
