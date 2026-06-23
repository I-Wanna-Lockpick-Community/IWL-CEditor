shader_type canvas_item;
const vec4 COLOR_FILL = vec4(0.2823529412, 0.0509803922, 0.0509803922, 0.7058823529);
const vec4 COLOR_BACK = vec4(0.2823529412, 0.0509803922, 0.0509803922, 0.1960784314);
instance uniform vec2 size;

varying vec2 position;
varying vec2 minposition;

bool stripe(float _start, float width) {
	float x = mod(position.x, 16.0);
	float y = mod(position.y-4.0, 59.0)+4.0;
	float start = _start + floor(abs(6.0-abs(7.5-x))/2.0);
	if (minposition.x < 1.5) start++;
	float end = _start + width + abs(2.0-floor(abs(7.5-x)/2.0));
	return y > start && y < end;
}

void fragment() {
	vec2 croppedUV = mix(vec2(COLOR.r,COLOR.g),vec2(COLOR.b,COLOR.a),UV);
	if (croppedUV.x < 0.0 || croppedUV.y < 0.0 || croppedUV.x > 1.0 || croppedUV.y > 1.0) {
		COLOR.a = 0.0;
	} else {
		position = floor(croppedUV*size);
		vec2 unposition = size - position - vec2(1,1);
		minposition = vec2(min(position.x,unposition.x),min(position.y,unposition.y));

		if ((minposition.x < 0.5 || minposition.y < 0.5) // border
			|| (minposition.x + 2.0*minposition.y < 6.5) // corners
			|| stripe(4.5,11.0)
			|| stripe(24.5,5.0)
			|| stripe(37.5,9.0)
			|| stripe(54.5,5.0)) {
			COLOR = COLOR_FILL;
		} else {
			COLOR = COLOR_BACK;
		}
	}
}
