extends RefCounted
class_name C

var r:Q
var i:Q

func _init(_r:Variant,_i:Variant=0) -> void:
	if _r is C:
		r = _r.r
		i = _r.i
	else:
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

func eq(realOrComplex:Variant, imaginary:Variant=Q.new(0)) -> bool: 
	if realOrComplex is C: return r.eq(realOrComplex.r) and i.eq(realOrComplex.i)
	else: return r.eq(realOrComplex) and i.eq(imaginary)
func neq(realOrComplex:Variant, imaginary:=Q.new(0)) -> bool: return !eq(realOrComplex, imaginary)

func sign() -> int: return r.sign() + i.sign()
func axis() -> C: return C.new(r.sign(), i.sign())

func isNonzeroReal() -> bool: return r.neq(0) and i.eq(0)
func isNonzeroImag() -> bool: return r.eq(0) and i.neq(0)

func abs() -> Q: return r.abs().plus(i.abs()) # not true but we only really use it for axial numbers so its fine

func plus(number) -> C: return C.new(r.plus(C.new(number).r), i.plus(C.new(number).i))
func minus(number) -> C: return C.new(r.minus(C.new(number).r), i.minus(C.new(number).i))
func times(number) -> C:
	var _n:C=C.new(number)
	return C.new(r.times(_n.r).minus(i.times(_n.i)),i.times(_n.r).plus(r.times(_n.i)))

func divint(number:int) -> C: return C.new(r.divint(number),i.divint(number))
