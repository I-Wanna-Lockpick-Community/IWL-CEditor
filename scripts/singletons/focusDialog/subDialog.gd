@abstract
extends Control
class_name SubDialog

@onready var main:FocusDialog = get_parent()

var interacted:NumberEdit:
	get(): return get_parent().interacted

var numberEdits:Array[NumberEdit]:
	get(): return get_parent().numberEdits

func interact(edit:NumberEdit, last:bool=false) -> void: main.interact(edit, last)

@abstract func focus(focused, new:bool, dontRedirect:bool) -> void
@abstract func receiveKey(event:InputEventKey) -> bool
