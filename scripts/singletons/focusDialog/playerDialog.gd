extends Control
class_name PlayerDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var main = get_parent()

func focus(focused:PlayerSpawn, _new:bool) -> void:
	if editor.game.levelStart == focused: %levelStart.button_pressed = true
	else: %savestate.button_pressed = true

func _setLevelStart() -> void:
	if main.focused is not PlayerSpawn: return
	if editor.game.levelStart:
		editor.game.levelStart.queue_redraw()
	changes.addChange(Changes.GlobalObjectChange.new(editor.game,editor.game,&"levelStart",main.focused))
	main.focused.queue_redraw()

func _setSavestate() -> void:
	if main.focused is not PlayerSpawn: return
	if editor.game.levelStart == main.focused:
		changes.addChange(Changes.GlobalObjectChange.new(editor.game,editor.game,&"levelStart",null))
		main.focused.queue_redraw()

func _playTest() -> void:
	editor.game.playTest(main.focused)
