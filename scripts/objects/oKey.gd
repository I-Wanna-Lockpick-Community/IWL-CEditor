extends Node2D
class_name oKey

func _init(_position:Vector2):
	position = _position

func _draw() -> void:
	draw_texture(preload('res://assets/level/objects/key/sprKey_0.png'),Vector2.ZERO)
	draw_texture(preload('res://assets/level/objects/key/sprKey_1.png'),Vector2.ZERO,Color8(214,207,201))
