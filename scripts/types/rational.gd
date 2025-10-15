extends RefCounted
class_name Q

var n:int

func _init(_n) -> void:
	if _n is Q: n = _n.n
	else: n = _n

func _to_string() -> String:
	return str(n)

func copy() -> Q: return Q.new(n)

func neq(number) -> bool: return n != Q.new(number).n
func eq(number) -> bool: return n == Q.new(number).n
func gt(number) -> bool: return n > Q.new(number).n
func lt(number) -> bool: return n < Q.new(number).n

func sign() -> int: return sign(n)

func plus(number) -> Q: return Q.new(n+Q.new(number).n)
func minus(number) -> Q: return Q.new(n-Q.new(number).n)
func times(number) -> Q: return Q.new(n*Q.new(number).n)
