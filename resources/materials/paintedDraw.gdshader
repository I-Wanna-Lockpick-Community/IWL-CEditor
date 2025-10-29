shader_type canvas_item;
instance uniform vec2 scale = vec2(1,1);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform vec3 colorTop:source_color;
uniform vec3 colorBottom:source_color;

vec3 lerpColor(vec3 color1, vec3 color2, float t) {
	return color1 * (1.0-t) + color2 * t;
}

void fragment() {
	if (scale.x > 0.125 && scale.y > 0.125) {
		if (COLOR.a > 0.0) {
			COLOR.rgb = texture(SCREEN_TEXTURE, SCREEN_UV).rgb + lerpColor(colorTop, colorBottom, UV.y/scale.y)*COLOR.a;
			COLOR.a = 1.0;
		}
	} else {
		COLOR.rgb = texture(SCREEN_TEXTURE, SCREEN_UV).rgb + COLOR.rgb*COLOR.a;
		COLOR.a = 1.0;
	}
}
