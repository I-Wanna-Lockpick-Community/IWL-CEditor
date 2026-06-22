shader_type canvas_item;
const vec4 COLOR_FILL = vec4(1, 1, 1, 0.7058824);
const vec4 COLOR_BACK = vec4(0.8554, 0.91, 0.91, 0.39215687);

bool stripe(float start, float width, vec2 positer, vec2 size) {
    float thispos = positer.x + positer.y;
    float end = start+width;
    return max(size.x,size.y) > end && thispos > start && thispos < end;
}

void fragment() {
	float topLeftSize = 56.0;
	vec2 size = round(vec2(1.0/COLOR.r, 1.0/COLOR.g));
	if (size.x < 50.0 || size.y < 50.0) topLeftSize = 24.0;
	float bottomRightSize = 46.0;
	if (size.x < 40.0 || size.y < 40.0) bottomRightSize = 23.0;
	
	vec2 position = floor(UV*size);
	vec2 unposition = size - position - vec2(1,1);
	vec2 minposition = vec2(min(position.x,unposition.x),min(position.y,unposition.y));

	if ((minposition.x < 0.5 || minposition.y < 0.5) // border
		|| (minposition.x+minposition.y < 4.5) // corners
		|| ((minposition.x < 1.5 || minposition.y < 1.5) && minposition.x < 4.5 && minposition.y < 4.5) // corners
		|| stripe(14.5,10.0,position,size)
		|| stripe(42.5,14.0,position,size)
		|| stripe(10.5,3.0,unposition,size)
		|| stripe(19.5,5.0,unposition,size)
		|| stripe(41.5,5.0,unposition,size)) {
		COLOR = COLOR_FILL;
	} else {
		COLOR = COLOR_BACK;
	}
}
