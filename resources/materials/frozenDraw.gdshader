shader_type canvas_item;
instance uniform vec2 size = vec2(32,32);
uniform sampler2D bottomLeft:source_color;
uniform sampler2D topLeftBig:source_color;
uniform sampler2D topLeftSmall:source_color;
uniform sampler2D bottomRightBig:source_color;
uniform sampler2D bottomRightSmall:source_color;
uniform vec4 colorFilled:source_color;
uniform vec4 colorBack:source_color;

void fragment() {
	if (size.x > 0.5 && size.y > 0.5) {
		float topLeftSize = 56.0;
		if (size.x < 62.0 || size.y < 62.0) topLeftSize = 24.0;
		float bottomRightSize = 46.0;
		if (size.x < 52.0 || size.y < 52.0) bottomRightSize = 23.0;
		
		vec2 position = floor(UV*size);
		vec2 unposition = size - position - vec2(1,1);
		if (position.x < 4.5 && unposition.y < 4.5) { // bottom left
			COLOR = texture(bottomLeft,vec2(position.x+0.5,4.5-unposition.y)/5.0);
		} else if (unposition.x < 4.5 && position.y < 4.5) { // bottom right
			COLOR = texture(bottomLeft,vec2(unposition.x+0.5,4.5-position.y)/5.0);
		} else if (position.x + position.y < topLeftSize+0.5) { // top left
			if (topLeftSize > 55.5) COLOR = texture(topLeftBig,vec2(position.x+0.5,position.y+0.5)/topLeftSize);
			else COLOR = texture(topLeftSmall,vec2(position.x+0.5,position.y+0.5)/topLeftSize);
		} else if (unposition.x + unposition.y < bottomRightSize+0.5) { // bottom right
			if (bottomRightSize > 45.5) COLOR = texture(bottomRightBig,vec2(bottomRightSize-unposition.x-0.5,bottomRightSize-unposition.y-0.5)/bottomRightSize);
			else COLOR = texture(bottomRightSmall,vec2(bottomRightSize-unposition.x-0.5,bottomRightSize-unposition.y-0.5)/bottomRightSize);
		} else if (position.x < 0.5 || position.x + 1.5 > size.x || position.y < 0.5 || position.y + 1.5 > size.y) {
			COLOR = colorFilled;
		} else {
			COLOR = colorBack;
		}
	}
}
