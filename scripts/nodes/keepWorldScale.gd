extends Control
class_name KeepWorldScale

@onready var editor:Editor = get_node("/root/editor")

func _process(_delta):
	if editor.game.playState == Game.PLAY_STATE.PLAY: scale = editor.game.playCamera.zoom
	else: scale = editor.game.editorCamera.zoom
