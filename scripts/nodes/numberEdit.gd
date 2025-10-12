extends PanelContainer
class_name NumberEdit

@onready var editor:Editor = get_node("/root/editor")
var nextEdit:NumberEdit

signal valueSet(value:int)

var newlyInteracted:bool = false

var value:int = 0
var bufferedNegative:bool = false # since -0 cant exist, activate it the next time the value isnt negative

func _gui_input(event:InputEvent) -> void:
	if Editor.isLeftClick(event): editor.focusDialog.interact(self)

func setValue(_value:int, manual:bool=false) -> void:
	value = _value
	if bufferedNegative and value != 0:
		bufferedNegative = false
	if value >= 1e8: value = 99999999
	if value <= -1e7: value = -9999999
	if bufferedNegative: %drawText.text = "-" + str(value)
	else: %drawText.text = str(value)
	if !manual: valueSet.emit(value)

func receiveKey(key:InputEventKey):
	var number:int = -1
	match key.keycode:
		KEY_TAB: editor.focusDialog.interact(nextEdit)
		KEY_EQUAL: if Input.is_key_pressed(KEY_SHIFT): editor.focusDialog.interact(nextEdit)
		KEY_0: number = 0
		KEY_1: number = 1
		KEY_2: number = 2
		KEY_3: number = 3
		KEY_4: number = 4
		KEY_5: number = 5
		KEY_6: number = 6
		KEY_7: number = 7
		KEY_8: number = 8
		KEY_9: number = 9
		KEY_MINUS:
			if value == 0: bufferedNegative = !bufferedNegative
			setValue(-value)
		KEY_BACKSPACE:
			newlyInteracted = false
			if Input.is_key_pressed(KEY_CTRL): setValue(0)
			else:
				if value > -10 and value < 0: bufferedNegative = true
				if value == 0: bufferedNegative = false
				@warning_ignore("integer_division") setValue(value/10)
		KEY_I: if get_parent() is ComplexNumberEdit: get_parent().rotate()
		_: return false
	if number != -1:
		if newlyInteracted: setValue(0,true)
		newlyInteracted = false
		if value < 0 || bufferedNegative: setValue(value*10-number)
		else: setValue(value*10+number)
	return true
