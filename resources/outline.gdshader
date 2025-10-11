shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float rCameraZoom = 1.0; // reciprocal of camera zoom
uniform float width : hint_range(0, 10) = 1.0;

void vertex() {
	VERTEX += sign(UV * 2.0 - 1.0)*rCameraZoom*width;
}

bool isWithinOutline(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float x = -width; x <= width; x++) {
		x = min(x,width);
		for (float y = -width; y <= width; y++) {
			y = min(y,width);
			vec2 xy = uv + vec2(x,y) * texture_pixel_size*rCameraZoom;
			if (xy == clamp(xy, vec2(0.0), vec2(1.0)) && texture(texture, xy).a > 0.0) {
				return true;
			}
		}
	}
	return false;
}

void fragment() {
	vec2 uv = UV/(vec2(1.0,1.0) - 2.0*width*rCameraZoom*TEXTURE_PIXEL_SIZE) - width*rCameraZoom*TEXTURE_PIXEL_SIZE;
	if (isWithinOutline(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		COLOR.a = 1.0;
		COLOR.rgb = color.rgb;
	} else {
		COLOR.a = 0.0;
	}
}
