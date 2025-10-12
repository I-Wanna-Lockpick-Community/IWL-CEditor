extends Control
class_name KeepWorldScale

@onready var editor:Editor = get_node("/root/editor")

func _process(_delta):
	scale = editor.game.editorCamera.zoom
