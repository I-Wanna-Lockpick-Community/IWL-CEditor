extends Node2D
class_name FocusOutline

@onready var editor:Editor = get_node("/root/editor")

func _draw():
	if editor.focusDialog.focused:
		material.set_shader_parameter("rCameraZoom", 1/editor.level.editorCamera.zoom.x)
		if editor.focusDialog.focused is oKey:
			draw_texture(preload('res://assets/level/objects/key/outlineMask.png'),editor.focusDialog.focused.position)

func _process(_delta):
	queue_redraw()
