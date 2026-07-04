extends Control
class_name followWorld

@export var offset:Vector2
var worldOffset:Vector2

func _process(_delta) -> void:
	if Game.playState == Game.PLAY_STATE.EDIT:
		scale = Vector2.ONE * Game.editor.editorCamera.zoom / Game.uiScale
		position = -offset - (Game.editor.editorCamera.get_screen_center_position() - worldOffset) * scale + Game.editor.gameCont.size/2
	else:
		scale = Vector2.ONE * Game.camera.zoom / Game.uiScale
		position = -offset - (Game.camera.get_screen_center_position() - worldOffset) * scale + Game.editor.gameCont.size/2
