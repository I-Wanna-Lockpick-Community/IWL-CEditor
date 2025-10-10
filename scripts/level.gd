extends Node2D
class_name Level

@onready var editor:Editor = get_node("/root/editor")
@onready var tiles:TileMapLayer = %tiles
@onready var editorCamera:Camera2D = %editorCamera

var levelBounds:Rect2i = Rect2i(0,0,800,608):
	set(value):
		levelBounds = value
		editor.levelViewportCont.material.set_shader_material("levelSize",levelBounds.size)
