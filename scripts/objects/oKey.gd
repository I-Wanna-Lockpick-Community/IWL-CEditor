extends Control
class_name oKey

@onready var editor:Editor = get_node("/root/editor")

func _draw() -> void:
	draw_texture(preload('res://assets/level/objects/key/frame.png'),Vector2.ZERO)
	draw_texture(preload('res://assets/level/objects/key/fill.png'),Vector2.ZERO,Color8(214,207,201))
	

func _process(_delta):
	queue_redraw()

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and editor.mode in [Editor.Mode.SELECT, Editor.Mode.KEY]:
				editor.focus(self)
				get_viewport().set_input_as_handled()
