shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
global uniform float RCAMERA_ZOOM = 1; // reciprocal of camera zoom
uniform float width : hint_range(0, 10) = 1.0;
varying flat vec4 modulate;
void vertex() {
	modulate = COLOR;
	VERTEX += sign(UV * 2.0 - 1.0)*width*RCAMERA_ZOOM;
}

bool isOnOutline(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	if (uv == clamp(uv, vec2(0.0), vec2(1.0)) && texture(texture, uv).a > 0.0) {
		return false;
	}
	for (float x = -width; x <= width; x++) {
		x = min(x,width);
		for (float y = -width; y <= width; y++) {
			y = min(y,width);
			vec2 xy = uv + vec2(x,y) * texture_pixel_size*RCAMERA_ZOOM;
			if (xy == clamp(xy, vec2(0.0), vec2(1.0)) && texture(texture, xy).a > 0.0) {
				return true;
			}
		}
	}
	return false;
}

void fragment() {
	vec2 uv = UV/(vec2(1.0,1.0) - 2.0*width*RCAMERA_ZOOM*TEXTURE_PIXEL_SIZE) - width*RCAMERA_ZOOM*TEXTURE_PIXEL_SIZE;
	if (isOnOutline(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		COLOR.a = modulate.a;
		COLOR.rgb = color.rgb * modulate.rgb;
	} else {
		COLOR.a = 0.0;
	}
}
