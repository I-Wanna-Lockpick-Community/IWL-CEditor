extends PanelContainer
class_name NumberEdit

enum PURPOSE {SINGLE, REAL, IMAGINARY, AXIAL}

@onready var editor:Editor = get_node("/root/editor")
var nextEdit:NumberEdit

signal valueSet(value:Q)

var newlyInteracted:bool = false

var value:Q = Q.new(0)
var bufferedNegative:bool = false # since -0 cant exist, activate it when the number is set
var purpose:PURPOSE = PURPOSE.SINGLE

func _gui_input(event:InputEvent) -> void:
	if Editor.isLeftClick(event): editor.focusDialog.interact(self)

func setValue(_value:Q, manual:bool=false) -> void:
	value = _value
	if bufferedNegative and value.n != 0:
		bufferedNegative = false
	if value.n >= 1e8: value.n = 99999999
	if value.n <= -1e7: value.n = -9999999
	if bufferedNegative: %drawText.text = "-0"
	else: %drawText.text = str(value.n)
	if !manual: valueSet.emit(value.n)

func increment() -> void: setValue(value.plus(1))
func decrement() -> void: setValue(value.minus(1))

func deNew():
	newlyInteracted = false
	theme_type_variation = &"NumberEditPanelContainerSelected"

func receiveKey(key:InputEventKey):
	var number:int = -1
	match key.keycode:
		KEY_TAB: editor.focusDialog.tabbed(self)
		KEY_EQUAL: if purpose != PURPOSE.SINGLE and Input.is_key_pressed(KEY_SHIFT):
			editor.focusDialog.interact((get_parent().imaginaryEdit if purpose == PURPOSE.REAL else get_parent().realEdit))
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
			theme_type_variation = &"NumberEditPanelContainerSelected"
			if Input.is_key_pressed(KEY_CTRL) or newlyInteracted: setValue(Q.new(0))
			else:
				if value.n > -10 and value.n < 0: bufferedNegative = true
				if value.n == 0: bufferedNegative = false
				@warning_ignore("integer_division") setValue(Q.new(value.n/10))
			deNew()
		KEY_I: if get_parent() is ComplexNumberEdit: get_parent().rotate()
		KEY_UP: increment(); deNew()
		KEY_DOWN: decrement(); deNew()
		KEY_LEFT, KEY_RIGHT: deNew()
		_: return false
	if number != -1:
		if newlyInteracted:
			if value.lt(0): bufferedNegative = true
			setValue(Q.new(0),true)
		deNew()
		if value.n < 0 || bufferedNegative: setValue(Q.new(value.n*10-number))
		else: setValue(Q.new(value.n*10+number))
	return true
