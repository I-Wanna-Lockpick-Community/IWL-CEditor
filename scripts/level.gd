extends Node2D
class_name Level

@onready var editor:Editor = get_node("/root/editor")
@onready var tiles:TileMapLayer = %tiles

func _draw() -> void:
	var sizeTiles:Vector2i = ceil(editor.levelViewportCont.size / 32)
	for x in sizeTiles.x:
		draw_line(
			Vector2(32*x,0),
			Vector2(32*x,editor.levelViewportCont.size.y),
			Color.GRAY)
	for y in sizeTiles.y:
		draw_line(
			Vector2(0,32*y),
			Vector2(editor.levelViewportCont.size.x,32*y),
			Color.GRAY)
