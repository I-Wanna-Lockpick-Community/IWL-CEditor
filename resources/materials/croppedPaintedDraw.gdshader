shader_type canvas_item;
render_mode blend_add;
const vec3 COLOR_TOP = vec3(0.72156864, 0.21568628, 0);
const vec3 COLOR_BOTTOM = vec3(0.72156864, 0.46666667, 0);
instance uniform vec2 size;
uniform sampler2D paintedBase;

void fragment() {
	vec2 croppedUV = mix(vec2(COLOR.r,COLOR.g),vec2(COLOR.b,COLOR.a),UV);
	if (croppedUV.x < 0.0 || croppedUV.y < 0.0 || croppedUV.x > 1.0 || croppedUV.y > 1.0) {
		COLOR.a = 0.0;
	} else {
		COLOR.rgb = mix(COLOR_TOP, COLOR_BOTTOM, croppedUV.y*128.0/size.y);
		COLOR.a = texture(paintedBase, fract(croppedUV*size/128.0)).a;
	}
}
