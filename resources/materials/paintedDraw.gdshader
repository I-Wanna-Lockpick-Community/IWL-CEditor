shader_type canvas_item;
render_mode blend_add;
const vec3 COLOR_TOP = vec3(0.72156864, 0.21568628, 0);
const vec3 COLOR_BOTTOM = vec3(0.72156864, 0.46666667, 0);

void fragment() {
	vec2 scale = round(vec2(1.0/COLOR.r, 1.0/COLOR.g)) / 128.0;
	COLOR.rgb = mix(COLOR_TOP, COLOR_BOTTOM, UV.y/scale.y);
}
