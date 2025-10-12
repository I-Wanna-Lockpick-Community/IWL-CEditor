extends RefCounted
class_name Number

const LABEL = preload("res://resources/numberLabel.tres")
const LABEL_NEGATIVE = preload("res://resources/numberLabelNegative.tres")

var r:int
var i:int

func _init(_r:int,_i:int):
	r = _r
	i = _i

func _to_string():
	var rComponent:String
	var iComponent:String = ""
	if r: rComponent = str(r)
	if i:
		if i > 0 and r: iComponent += "+"
		iComponent += str(i) + "i"
	if !r and !i: return "0"
	return rComponent + iComponent

func copy() -> Number: return Number.new(r,i)

func equals(realOrNumber:Variant, imaginary:int=0) -> bool: 
	if realOrNumber is Number: return r == realOrNumber.r and i == realOrNumber.i
	else: return r == realOrNumber and i == imaginary

func sign() -> int: return sign(r) + sign(i)
