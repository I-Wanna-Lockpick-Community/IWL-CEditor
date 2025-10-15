extends HBoxContainer
class_name ComplexNumberEdit

@onready var editor:Editor = get_node("/root/editor")
@onready var realEdit:NumberEdit = %realEdit
@onready var imaginaryEdit:NumberEdit = %imaginaryEdit

signal valueSet(value:Complex)

var value:Complex

func setValue(_value:Complex,manual:bool=false) -> void:
	value = _value
	realEdit.setValue(value.r, true)
	imaginaryEdit.setValue(value.i, true)

	realEdit.nextEdit = imaginaryEdit
	imaginaryEdit.nextEdit = realEdit

	if !manual: valueSet.emit(value)

func _realSet(r:int) -> void:
	setValue(Complex.new(r,value.i))

func _imaginarySet(i:int) -> void:
	setValue(Complex.new(value.r,i))

func rotate() -> void:
	setValue(Complex.new(-value.i,value.r))
