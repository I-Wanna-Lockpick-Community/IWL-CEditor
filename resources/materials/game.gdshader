shader_type canvas_item;

uniform vec4 GRID_COLOR : source_color = vec4(0.54901963, 0.54901963, 0.54901963, 0.54509807);
const vec3 OUTOFBOUNDS_COLOR = vec3(0.20990813, 0.20990813, 0.2099081);

global uniform vec2 LEVEL_POS;
global uniform vec2 LEVEL_SIZE;
global uniform vec2 SCREEN_SIZE;

uniform vec2 screenPosition; // where the top left corner of the screen is, in worldspace
global uniform vec2 VIEWPORT_POS; // where the top left corner of the game viewport is, in world space
uniform vec2 mousePosition = vec2(0,0); // where the mouse is, in worldspace
global uniform float RCAMERA_ZOOM = 1; // reciprocal of camera zoom
uniform vec2 tileSize = vec2(32,32);

float lengthSquared(vec2 vector) {
	return vector.x*vector.x + vector.y*vector.y;
}

void fragment() {
	// pixelate
	vec2 worldScreenSize = SCREEN_SIZE*RCAMERA_ZOOM;
	COLOR.rgb = texture(TEXTURE, (floor(UV*worldScreenSize + fract(VIEWPORT_POS)) - fract(VIEWPORT_POS) + vec2(0.5,0.5))/worldScreenSize).rgb;

	vec2 XY = FRAGCOORD.xy*RCAMERA_ZOOM + screenPosition - LEVEL_POS;
	if (XY.x < 0.0 || XY.y < 0.0 || XY.x > LEVEL_SIZE.x || XY.y > LEVEL_SIZE.y) {
		// draw level bounds
		COLOR.rgb = mix(COLOR.rgb, OUTOFBOUNDS_COLOR, 0.5);
	}
	// draw grid
	float gridAlpha = 0.0;
	if ((tileSize.x <= 8.0 && mod(XY.x,8.0) < RCAMERA_ZOOM) || (tileSize.y <= 8.0 && mod(XY.y,8.0) < RCAMERA_ZOOM)) gridAlpha = 0.3;
	if ((tileSize.x <= 16.0 && mod(XY.x,16.0) < RCAMERA_ZOOM) || (tileSize.y <= 16.0 && mod(XY.y,16.0) < RCAMERA_ZOOM)) gridAlpha = 0.35;
	if ((tileSize.x <= 32.0 && mod(XY.x,32.0) < RCAMERA_ZOOM) || (tileSize.y <= 32.0 && mod(XY.y,32.0) < RCAMERA_ZOOM)) gridAlpha = 1.0;
	if ((tileSize.x > 799.5 && mod(XY.x,800.0) < RCAMERA_ZOOM) || (tileSize.y > 607.5 && mod(XY.y,608.0) < RCAMERA_ZOOM)) gridAlpha = 0.8;
	if (tileSize.x > 799.5 && tileSize.y > 607.5) COLOR.rgb = mix(COLOR.rgb,GRID_COLOR.rgb,GRID_COLOR.a*gridAlpha);
	else COLOR.rgb = mix(COLOR.rgb,GRID_COLOR.rgb,GRID_COLOR.a*gridAlpha*(1.0-min(lengthSquared(mousePosition-XY)/1e4,1.0)));
}
