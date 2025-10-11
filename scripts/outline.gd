extends Node2D
class_name Outline

@onready var editor:Editor = get_node("/root/editor")

func _draw() -> void:
	material.set_shader_parameter("rCameraZoom", 1/editor.game.editorCamera.zoom.x)
	if editor.focusDialog.focused:
		drawOutline(editor.focusDialog.focused)
	if editor.objectHovered:
		drawOutline(editor.objectHovered,Color("#ffffff88"))

func drawOutline(object:Control,color:Color=Color.WHITE) -> void:
	if object is KeyBulk:
		draw_texture(object.outlineTex(),object.position,color)

func _process(_delta) -> void:
	queue_redraw()
