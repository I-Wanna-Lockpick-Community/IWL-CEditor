class_name PencilmarkDialog
extends Control

@onready var main:FocusDialog = get_parent()

func _ready() -> void:
	%weirdButtons.visible = !Game.editor

func focus(focused:Pencilmark, _new:bool, _dontRedirect:bool) -> void:
	%pencilmarkTypeSelector.setSelect(focused.type)
	%pencilmarkColorSelector.setSelect(focused.color)

func receiveKey(_event:InputEventKey) -> bool:
	return false

func _pencilmarkTypeSelected(type:Pencilmark.TYPE) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"type",type))
	Changes.bufferSave()

func _pencilmarkColorSelected(color:C.olors) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"color",color))
	Changes.bufferSave()
