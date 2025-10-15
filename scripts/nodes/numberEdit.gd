extends PanelContainer
class_name NumberEdit

@onready var editor:Editor = get_node("/root/editor")
var nextEdit:NumberEdit

signal valueSet(value:Q)

var newlyInteracted:bool = false

var value:Q = Q.new(0)
var bufferedNegative:bool = false # since -0 cant exist, activate it the next time the value isnt negative

func _gui_input(event:InputEvent) -> void:
	if Editor.isLeftClick(event): editor.focusDialog.interact(self)

func setValue(_value:Q, manual:bool=false) -> void:
	value = _value
	if bufferedNegative and value.n != 0:
		bufferedNegative = false
	if value.n >= 1e8: value.n = 99999999
	if value.n <= -1e7: value.n = -9999999
	if bufferedNegative: %drawText.text = "-" + str(value.n)
	else: %drawText.text = str(value.n)
	if !manual: valueSet.emit(value.n)

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
			if value.n == 0: bufferedNegative = !bufferedNegative
			setValue(value.times(-1))
		KEY_BACKSPACE:
			newlyInteracted = false
			if Input.is_key_pressed(KEY_CTRL): setValue(Q.new(0))
			else:
				if value.n > -10 and value.n < 0: bufferedNegative = true
				if value.n == 0: bufferedNegative = false
				@warning_ignore("integer_division") setValue(Q.new(value.n/10))
		KEY_I: if get_parent() is ComplexNumberEdit: get_parent().rotate()
		_: return false
	if number != -1:
		if newlyInteracted: setValue(Q.new(0),true)
		newlyInteracted = false
		if value.n < 0 || bufferedNegative: setValue(Q.new(value.n*10-number))
		else: setValue(Q.new(value.n*10+number))
	return true
