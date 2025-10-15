shader_type canvas_item;
varying flat vec4 modulate;
varying vec2 vert;
instance uniform vec2 size = vec2(32,32);
void vertex() {
	vert = VERTEX;
	modulate = COLOR;
}
void fragment() {
	COLOR = texture(TEXTURE,floor(vert)/size) * modulate.rgba; // size is mathematically equivalent to VERTEX/UV but that doesnt work at small floats so
}
