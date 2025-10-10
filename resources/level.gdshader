shader_type canvas_item;

uniform vec3 GRID_COLOR:source_color;
uniform vec3 OUTOFBOUNDS_COLOR:source_color;

uniform vec2 levelSize = vec2(800,608);

uniform vec2 screenPosition; // where the top left corner of the screen is, in worldspace
uniform vec2 mousePosition = vec2(0,0); // where the mouse is, in worldspace
uniform vec2 cameraZoom = vec2(1,1);

vec3 lerpColor(vec3 color1, vec3 color2, float t) {
	return color1 * (1.0-t) + color2 * t;
}

float lengthSquared(vec2 vector) {
	return vector.x*vector.x + vector.y*vector.y;
}

void fragment() {
	vec2 XY = FRAGCOORD.xy/cameraZoom + screenPosition;
	if (XY.x < 0.0 || XY.y < 0.0 || XY.x > 800.0 || XY.y > 608.0) {
		// draw level bounds
		COLOR.rgb = OUTOFBOUNDS_COLOR;
	} else if (int(XY.x) % 32 == 0 || int(XY.y) % 32 == 0) {
		// draw grid
		COLOR.rgb = lerpColor(GRID_COLOR,COLOR.rgb,min(lengthSquared(mousePosition-XY)/1e4,1.0));
	}
}
