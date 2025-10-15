extends RefCounted
class_name C

var r:Q
var i:Q

func _init(_r:Variant,_i:Variant=0) -> void:
	r = Q.new(_r)
	i = Q.new(_i)

func _to_string() -> String:
	var rComponent:String
	var iComponent:String = ""
	if r.neq(0): rComponent = str(r)
	if i.neq(0):
		if i.gt(0) and r.neq(0): iComponent += "+"
		iComponent += str(i) + "i"
	if r.eq(0) and i.eq(0): return "0"
	return rComponent + iComponent

func copy() -> C: return C.new(r,i)

func eq(realOrComplex:Variant, imaginary:=Q.new(0)) -> bool: 
	if realOrComplex is C: return r.eq(realOrComplex.r) and i.eq(realOrComplex.i)
	else: return r.eq(realOrComplex) and i.eq(imaginary)

func sign() -> int: return r.sign() + i.sign()
