shader_type canvas_item;
uniform float width = 1;
uniform vec4 rChannel : source_color;
uniform vec4 gChannel : source_color;
uniform vec4 bChannel : source_color;

// https://en.wikipedia.org/wiki/Alpha_compositing
vec4 over(vec4 atop, vec4 base) {
	float t = 1.0 - atop.a;
	vec4 result;
	result.a = atop.a + base.a * t;
	result.rgb = (atop.rgb*atop.a + base.rgb*base.a * t) / result.a;
	return result;
}

void fragment() {
	// for the three color channels, find the maximum value within the kernel.
	vec3 accumulator = COLOR.rgb;
	for (float x = -width; x <= width; x++) {
		for (float y = -width; y <= width; y++) {
			accumulator = max(accumulator, texture(TEXTURE, UV+SCREEN_PIXEL_SIZE*vec2(x,y)).rgb);
		}
	}
	// for the three color channels, if the accumulated value is no greater than that of the pixel itself, then we ignore it
	accumulator *= sign(accumulator - COLOR.rgb);
	// display the channels, with their respective colors
	vec4 r = vec4(rChannel.rgb, rChannel.a*accumulator.r);
	vec4 g = vec4(gChannel.rgb, gChannel.a*accumulator.g);
	vec4 b = vec4(bChannel.rgb, bChannel.a*accumulator.b);
	COLOR = over(over(r, g), b);
}
