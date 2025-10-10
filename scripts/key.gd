extends Node2D
class_name Key

func _draw() -> void:
	draw_texture(preload('res://assets/level/objects/key/sprKey_0.png'),position)
	draw_texture(preload('res://assets/level/objects/key/sprKey_1.png'),position,Color8(214,207,201))
