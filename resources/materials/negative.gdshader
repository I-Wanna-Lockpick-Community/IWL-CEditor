shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

vec3 invertColor(vec3 color, float t) {
	return color * (1.0-2.0*t) + vec3(t,t,t);
}

void fragment() {
	float t = COLOR.a;
	COLOR.a = 1.0;
	COLOR.rgb = invertColor(texture(SCREEN_TEXTURE, SCREEN_UV).rgb,t);
}
