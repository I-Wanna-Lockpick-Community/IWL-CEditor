extends MarginContainer
class_name TopBar

@onready var editor:Editor = get_node("/root/editor")

func updatePlayButton() -> void:
	%play.disabled = !editor.game.levelStart

func _playStateChanged() -> void:
	%modes.visible = editor.game.playState != Game.PLAY_STATE.PLAY

	%play.visible = editor.game.playState != Game.PLAY_STATE.PLAY
	%pause.visible = editor.game.playState == Game.PLAY_STATE.PLAY
	%stop.visible = editor.game.playState != Game.PLAY_STATE.EDIT

func _play() -> void: editor.game.playTest(editor.game.levelStart)
func _pause() -> void: editor.game.pauseTest()
func _stop() -> void: editor.game.stopTest()
