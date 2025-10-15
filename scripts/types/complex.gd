extends RefCounted
class_name Complex

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

func copy() -> Complex: return Complex.new(r,i)

func equals(realOrComplex:Variant, imaginary:int=0) -> bool: 
	if realOrComplex is Complex: return r == realOrComplex.r and i == realOrComplex.i
	else: return r == realOrComplex and i == imaginary

func sign() -> int: return sign(r) + sign(i)
