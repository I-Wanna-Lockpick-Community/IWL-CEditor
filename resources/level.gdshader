shader_type canvas_item;

uniform vec4 GRID_COLOR:source_color;
uniform vec3 OUTOFBOUNDS_COLOR:source_color;

uniform vec2 levelSize = vec2(800,608);

uniform vec2 screenPosition; // where the top left corner of the screen is, in worldspace
uniform vec2 mousePosition = vec2(0,0); // where the mouse is, in worldspace
global uniform float RCAMERA_ZOOM = 1; // reciprocal of camera zoom
uniform vec2 tileSize = vec2(32,32);

vec3 lerpColor(vec3 color1, vec3 color2, float t) {
	return color1 * (1.0-t) + color2 * t;
}

float lengthSquared(vec2 vector) {
	return vector.x*vector.x + vector.y*vector.y;
}

void fragment() {
	vec2 XY = FRAGCOORD.xy*RCAMERA_ZOOM + screenPosition;
	if (XY.x < 0.0 || XY.y < 0.0 || XY.x > levelSize.x || XY.y > levelSize.y) {
		// draw level bounds
		COLOR.rgb = lerpColor(COLOR.rgb, OUTOFBOUNDS_COLOR, 0.5);
	}
	if (mod(XY.x,tileSize.x) < RCAMERA_ZOOM || mod(XY.y,tileSize.y) < RCAMERA_ZOOM) {
		// draw grid
		float gridAlpha = 0.35;
		if (mod(XY.x,32) < RCAMERA_ZOOM || mod(XY.y,32) < RCAMERA_ZOOM) {
			gridAlpha = 1.0;
		}
		COLOR.rgb = lerpColor(COLOR.rgb,GRID_COLOR.rgb,GRID_COLOR.a*gridAlpha*(1.0-min(lengthSquared(mousePosition-XY)/1e4,1.0)));
	}
}
