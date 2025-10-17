extends HBoxContainer
class_name ComplexNumberEdit

@onready var editor:Editor = get_node("/root/editor")
@onready var realEdit:NumberEdit = %realEdit
@onready var imaginaryEdit:NumberEdit = %imaginaryEdit

signal valueSet(value:C)

var value:C

func setValue(_value:C,manual:bool=false) -> void:
	value = _value
	realEdit.setValue(value.r, true)
	imaginaryEdit.setValue(value.i, true)

	realEdit.nextEdit = imaginaryEdit
	realEdit.purpose = NumberEdit.PURPOSE.REAL
	imaginaryEdit.nextEdit = realEdit
	imaginaryEdit.purpose = NumberEdit.PURPOSE.IMAGINARY

	if !manual: valueSet.emit(value)

func _realSet(r:int) -> void:
	setValue(C.new(r,value.i))

func _imaginarySet(i:int) -> void:
	setValue(C.new(value.r,i))

func rotate() -> void:
	setValue(C.new(value.i.times(-1),value.r))
