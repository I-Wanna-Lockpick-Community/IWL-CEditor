shader_type canvas_item;

const vec2 direction_r = vec2(1, 0);
const vec2 direction_g = vec2(-0.5, 0.86603);
const vec2 direction_b = vec2(0.5, -0.86603);
const float scale = 20.2;
uniform float alpha: hint_range(0.0, 1.0) = 1.0;
uniform sampler2D noise: repeat_enable;
global uniform vec2 NOISE_OFFSET;
instance uniform bool scaled = true;

void fragment() {
	// image texture
	vec4 base = texture(TEXTURE, UV);

	vec2 uv = UV;
	if (scaled) {
		uv = floor(uv/TEXTURE_PIXEL_SIZE)*TEXTURE_PIXEL_SIZE;
	}
	// noise texture
	vec3 blend = vec3(
		texture(noise, uv * scale + (direction_r * NOISE_OFFSET)).r,
		texture(noise, uv * scale + (direction_g * NOISE_OFFSET)).g,
		texture(noise, uv * scale + (direction_b * NOISE_OFFSET)).b
	);

	COLOR = vec4(blend*base.rgb, alpha*base.a);
}