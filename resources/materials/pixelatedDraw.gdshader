shader_type canvas_item;
varying flat vec4 modulate;
instance uniform vec2 size = vec2(32,32);
void vertex() {
	modulate = COLOR;
}
void fragment() {
	COLOR = texture(TEXTURE,floor(UV*size)/size) * modulate.rgba; // size is mathematically equivalent to VERTEX/UV but that doesnt work at small floats so
}
