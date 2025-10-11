extends Node2D
class_name GlitchDrawer

func _ready() -> void:
	material = preload("res://resources/glitchDrawMaterial.tres")

class DrawRect extends GlitchDrawer:
	var rect:Rect2

	func _ready() -> void:
		super()
		set_instance_shader_parameter("scaled",false)

	func draw(_rect:Rect2) -> void:
		rect = _rect
		queue_redraw()
	
	func _draw() -> void:
		draw_rect(rect, Color.WHITE)

class DrawTexture extends GlitchDrawer:
	var texture:Texture2D
	var offset:Vector2i

	func draw(_texture:Texture2D,_offset:Vector2i) -> void:
		texture = _texture
		offset = _offset
		queue_redraw()
	
	func _draw() -> void:
		if texture:
			draw_texture(texture,offset)
