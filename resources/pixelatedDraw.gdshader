shader_type canvas_item;
varying flat vec4 modulate;
global uniform float RCAMERA_ZOOM = 1; // reciprocal of camera zoom
void vertex() {
	modulate = COLOR;
}
void fragment() {
	COLOR.rgba = texture(TEXTURE,UV-SCREEN_UV+floor(SCREEN_UV*RCAMERA_ZOOM/SCREEN_PIXEL_SIZE)*SCREEN_PIXEL_SIZE/RCAMERA_ZOOM) * modulate.rgba;
}
