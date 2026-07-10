shader_type canvas_item;

/** the wave is somewhere inbetween square and sine
* higher epsilon means more like sin
* sin(x)/sqrt(sin(x)^2 + E) */
uniform float squineEpsilon = 0.1;
/** how fast the lines move left */
uniform float driftSpeed = 20.0;
/** how fast the waves move right */
uniform float waveSpeed = 15.0;
/** how wide the waves are */
uniform float waveScale = 10.0;

/** how fast hue cycles */
uniform float hueCycleSpeed = 0.25;
uniform float saturation = 0.9;
/** how bright the darker lines are */
uniform float darkValue = 0.6;
/** how bright the brighter lines are */
uniform float brightValue = 1.0;
uniform float alpha = 0.4;

// https://github.com/hughsk/glsl-hsv2rgb
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float squine(float a) {
	return sin(a) / sqrt(pow(sin(a),2)+squineEpsilon);
}

void fragment() {
	vec2 size = round(vec2(1.0/COLOR.r, 1.0/COLOR.g));
	vec2 position = floor(UV*size + vec2(TIME*driftSpeed, 0));
	bool active = false;
	float place = floor(position.x / 4.0);
	float sinOffset = -TIME*waveSpeed;
	float sinMult = waveScale/size.x;
	float height = squine((place + sinOffset)*sinMult);
	float prevHeight = -squine((place-1.0 + sinOffset)*sinMult);
	if (mod(place, 2.0) < 0.5) {
		height = -height;
		prevHeight = -prevHeight;
	}
	if ((mod(position.x, 4.0) < 0.5)
		&& (position.y < (max(height, prevHeight)+1.0) * size.y/2.0)
		&& (position.y > (min(height, prevHeight)+1.0) * size.y/2.0 - 1.0)
	) {
		active = true;
	} else {
		if (abs(position.y - floor((height+1.0) * size.y/2.0)) < 0.5) {
			active = true;
		}
	}
	if (active) {
		COLOR.rgb = hsv2rgb(vec3(fract(TIME*hueCycleSpeed), saturation, mix(darkValue,brightValue,mod(position.y,2))));
		COLOR.a = alpha;
	} else {
		COLOR.a = 0.0;
	}
}
