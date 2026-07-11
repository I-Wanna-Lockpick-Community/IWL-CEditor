extends MarginContainer
class_name TopBar

@onready var play:Button = %play

func _updateButtons() -> void:
	%fileMenu.visible = Game.playState != Game.PLAY_STATE.PLAY and !Game.editor.settingsOpen
	%modes.visible = Game.playState != Game.PLAY_STATE.PLAY and !Game.editor.settingsOpen

	%savestate.visible = Game.playState != Game.PLAY_STATE.EDIT and !Game.editor.settingsOpen
	play.visible = Game.playState != Game.PLAY_STATE.PLAY and !Game.editor.settingsOpen
	%pause.visible = Game.playState == Game.PLAY_STATE.PLAY and !Game.editor.settingsOpen
	%stop.visible = Game.playState != Game.PLAY_STATE.EDIT and !Game.editor.settingsOpen
	%settingTabs.visible = Game.editor.settingsOpen

	play.disabled = !(Game.playState == Game.PLAY_STATE.PAUSED || Game.levelStart)

func _play() -> void: Game.playTest(Game.levelStart)
func _pause() -> void: Game.pauseTest()
func _stop() -> void: Game.stopTest()
func _savestate() -> void: Game.savestate()
