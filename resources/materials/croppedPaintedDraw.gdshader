shader_type canvas_item;
render_mode blend_add;
const vec3 COLOR_TOP = vec3(0.72156864, 0.21568628, 0);
const vec3 COLOR_BOTTOM = vec3(0.72156864, 0.46666667, 0);
instance uniform vec2 size;

void fragment() {
	vec2 croppedUV = mix(vec2(COLOR.r,COLOR.g),vec2(COLOR.b,COLOR.a),UV);
	COLOR.rgb = mix(COLOR_TOP, COLOR_BOTTOM, croppedUV.y*128.0/size.y);
	COLOR.a = texture(TEXTURE, croppedUV).a;
}
