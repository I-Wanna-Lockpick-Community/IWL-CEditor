extends Control
class_name oKey

@onready var editor:Editor = get_node("/root/editor")
@onready var game:Game = get_node("/root/editor").game
@onready var area:Area2D = %Area2D

var id:int
var color:Game.COLOR = Game.COLOR.WHITE

func _draw() -> void:
	draw_texture(preload('res://assets/game/objects/key/frame.png'),Vector2.ZERO)
	draw_texture(preload('res://assets/game/objects/key/fill.png'),Vector2.ZERO,game.mainTone[color])
	

func _process(_delta):
	queue_redraw()

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and editor.mode in [Editor.Mode.SELECT, Editor.Mode.KEY]:
				editor.focusDialog.focus(self)
				get_viewport().set_input_as_handled()
