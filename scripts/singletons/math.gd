extends Node

enum SYSTEM {COMPLEX, FRACTIONS}
var system:SYSTEM = SYSTEM.COMPLEX

# COMPLEX: [a,b], represents a + bi

# FRACTIONS: [a,b,d], represents (a + bi)/d
# d cannot be 0 or negative

func convert(n:PackedInt64Array, from:SYSTEM) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX:
			match from:
				SYSTEM.FRACTIONS, _: return [n[0], n[1]]
		SYSTEM.FRACTIONS, _:
			match from:
				SYSTEM.COMPLEX, _: return [n[0], n[1], 1]

var ZERO:PackedInt64Array:
	get():
		match system:
			SYSTEM.COMPLEX: return [0,0]
			SYSTEM.FRACTIONS, _: return [0,0,1]

var ONE:PackedInt64Array:
	get():
		match system:
			SYSTEM.COMPLEX: return [1,0]
			SYSTEM.FRACTIONS, _: return [1,0,1]

var nONE:PackedInt64Array:
	get():
		match system:
			SYSTEM.COMPLEX: return [-1,0]
			SYSTEM.FRACTIONS, _: return [-1,0,1]

var I:PackedInt64Array:
	get():
		match system:
			SYSTEM.COMPLEX: return [0,1]
			SYSTEM.FRACTIONS, _: return [0,1,1]

var nI:PackedInt64Array:
	get():
		match system:
			SYSTEM.COMPLEX: return [0,-1]
			SYSTEM.FRACTIONS, _: return [0,-1,1]

var ERROR:PackedInt64Array:
	get():
		match system:
			SYSTEM.COMPLEX: assert(false); return [0,0] # complex system does not have an error state
			SYSTEM.FRACTIONS, _: return [0,0,0]

# initialisers

## New number
func N(n:int) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n, 0]
		SYSTEM.FRACTIONS, _: return [n,0,1]

## New imaginary number
func Ni(n:int) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [0, n]
		SYSTEM.FRACTIONS, _: return [0,n,1]

## New complex number
func Nc(a:int,b:int) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a, b]
		SYSTEM.FRACTIONS, _: return [a,b,1]

## New fractional number
func Nf(n:int,d:int) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: assert(false); return ZERO
		SYSTEM.FRACTIONS, _: return [n,0,d]

## New fractional imaginary number
func Nfi(n:int,d:int) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: assert(false); return ZERO
		SYSTEM.FRACTIONS, _: return [0,n,d]

## New fractional complex number
func Nfc(a:int,b:int,d:int) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: assert(false); return ZERO
		SYSTEM.FRACTIONS, _: return [a,b,d]

## New Complex number from Numbers (a,b -> r(a) + r(b)i)
func Ncn(a:PackedInt64Array,b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a[0], b[0]]
		SYSTEM.FRACTIONS, _: return simplify([a[0]*b[2], b[0]*a[2], a[2]*b[2]])

## New Fractional number from Numbers (a,b -> numer(a) / rnumer(b))
func Nfn(a:PackedInt64Array,b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: assert(false); return ZERO
		SYSTEM.FRACTIONS, _: return simplify([a[0],a[1],b[0]])

func allAxes() -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [1,1]
		SYSTEM.FRACTIONS, _: return [1,1,1]

# operators

## (a,b -> a + b)
func add(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a[0]+b[0], a[1]+b[1]]
		SYSTEM.FRACTIONS, _: return simplify([a[0]*b[2] + b[0]*a[2], a[1]*b[2] + b[1]*a[2], a[2]*b[2]])

## (a,b -> a - b)
func sub(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a[0]-b[0], a[1]-b[1]]
		SYSTEM.FRACTIONS, _: return simplify([a[0]*b[2] - b[0]*a[2], a[1]*b[2] - b[1]*a[2], a[2]*b[2]])

## (a,b -> a * b)
func times(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a[0]*b[0]-a[1]*b[1], a[0]*b[1]+a[1]*b[0]]
		SYSTEM.FRACTIONS, _: return simplify([a[0]*b[0]-a[1]*b[1], a[0]*b[1]+a[1]*b[0], a[2]*b[2]])

## (a,b -> r(a) * r(b) + (ir(a) * ir(b))i)
func across(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a[0]*b[0], a[1]*b[1]]
		SYSTEM.FRACTIONS, _: return simplify([a[0]*b[0], a[1]*b[1], a[2]*b[2]])

## (a,b -> a / b)
## truncates if fractions are unrepresentable
func divide(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX:
			if nex(b): return ZERO
			@warning_ignore("integer_division")
			return [(a[0]*b[0]+a[1]*b[1])/(b[0]*b[0]+b[1]*b[1]), (a[1]*b[0]-a[0]*b[1])/(b[0]*b[0]+b[1]*b[1])]
		SYSTEM.FRACTIONS, _: return simplify([(a[0]*b[0]+a[1]*b[1])*b[2], (a[1]*b[0]-a[0]*b[1])*b[2], (b[0]*b[0]+b[1]*b[1])*a[2]])

## (a,b -> floor(a / b))
func floorDivide(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [intDiv(a[0]*b[0]+a[1]*b[1],b[0]*b[0]+b[1]*b[1]), intDiv(a[1]*b[0]-a[0]*b[1],b[0]*b[0]+b[1]*b[1])]
		SYSTEM.FRACTIONS, _: return M.floor(divide(a,b))

## (a,b -> a % b)
## has the sign of a (-5 % 3 = -2)
func remainder(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	if nex(b): return ZERO
	return sub(a,times(trunc(divide(a,b)),b))

## (a,b -> (a % b + b) % b)
## has the sign of b (remainder(-5, 3) = 1)
## also known as posmod
func modulo(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	if nex(b): return ZERO
	return sub(a,times(floorDivide(a,b),b))

## (a,b -> a p% b)
## Only subtracts real multiples of b 
func partialRemainder(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	if nex(b): return ZERO
	return sub(a,times(r(trunc(divide(a,b))),b))

## a "along" the axes of b
## (a,b -> (r(a) * sign(r(b))) + (ir(a) * sign(ir(b)))i)
func along(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array: 
	return across(a, axis(b))
## a "along" the axes of b, ignoring signs
## (a,b -> (r(a) * exists(r(b))) + (ir(a) * exists(ir(b)))i)
func alongbs(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array: return across(a, axibs(b))

## (a -> -a)
func negate(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [-n[0], -n[1]]
		SYSTEM.FRACTIONS, _: return [-n[0], -n[1], n[2]]

## (a -> ai)
func rotate(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [-n[1], n[0]]
		SYSTEM.FRACTIONS, _: return [-n[1], n[0], n[2]]

## componentwise max
func max(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [max(a[0], b[0]), max(a[1], b[1])]
		SYSTEM.FRACTIONS, _: return simplify([max(a[0]*b[2], b[0]*a[2]), max(a[1]*b[2], b[1]*a[2]), a[2]*b[2]])

## componentwise orelse
func orelse(a:PackedInt64Array, b:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [a[0] if a[0] else b[0], a[1] if a[1] else b[1]]
		SYSTEM.FRACTIONS, _: return simplify([a[0]*b[2] if a[0] else b[0]*a[2], a[1]*b[2] if a[1] else b[1]*a[2], a[2]*b[2]])

# reducers

## (n -> n)
func simplify(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return n
		SYSTEM.FRACTIONS, _:
			if n[2] == 0: return ERROR # propagate error state
			var divisor:int = gcd(gcd(n[0], n[1]), n[2])
			@warning_ignore("integer_division") return [n[0]/divisor, n[1]/divisor, n[2]/divisor]

## (n -> r(n))
func r(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n[0], 0]
		SYSTEM.FRACTIONS, _: return [n[0], 0, n[2]]

## (n -> i(n))
func i(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [0, n[1]]
		SYSTEM.FRACTIONS, _: return [0, n[1], n[2]]

## (n -> ir(n))
func ir(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n[1], 0]
		SYSTEM.FRACTIONS, _: return [n[1], 0, n[2]]

## (n -> r(n)*denom(n))
func rnumer(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n[0], 0]
		SYSTEM.FRACTIONS, _: return [n[0], 0, 1]

## (n -> i(n)*denom(n))
func inumer(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [0, n[1]]
		SYSTEM.FRACTIONS, _: return [0, n[1], 1]

## (n -> ir(n)*denom(n))
func irnumer(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n[1], 0]
		SYSTEM.FRACTIONS, _: return [n[1], 0, 1]

## (n -> r(n)*denom(n))
func numer(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n[0], n[1]]
		SYSTEM.FRACTIONS, _: return [n[0], n[1], 1]

## (n -> denom(n))
func denom(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return ONE
		SYSTEM.FRACTIONS, _: return [n[2], 0, 1]

## (n -> sign(r(n)) + sign(ir(n)))
func sign(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [sign(n[0])+sign(n[1]), 0]
		SYSTEM.FRACTIONS, _: return [sign(n[0])+sign(n[1]), 0, 1]

## (n -> abs(r(n)) + abs(ir(n)))
func abs(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [abs(n[0])+abs(n[1]), 0]
		SYSTEM.FRACTIONS, _: return [abs(n[0])+abs(n[1]), 0, n[2]]

## (n -> r(n) + ir(n))
func reduce(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [n[0]+n[1], 0]
		SYSTEM.FRACTIONS, _: return [n[0]+n[1], 0, n[2]]

## the axes present in the number
## (n -> sign(r(n)) + sign(ir(n))i)
func axis(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [sign(n[0]), sign(n[1])]
		SYSTEM.FRACTIONS, _: return [sign(n[0]), sign(n[1]), 1]

## the axes present in the number, but 0+0i counts as positive real
## (n -> 1 if n == 0 else axis(n))
func saxis(n:PackedInt64Array) -> PackedInt64Array: return ONE if n == ZERO else axis(n)

## componentwise abs
## (n -> abs(r(n)) + abs(ir(n))i)
func cabs(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return [abs(n[0]), abs(n[1])]
		SYSTEM.FRACTIONS, _: return [abs(n[0]), abs(n[1]), n[2]]

## the axes present in the number, ignoring sign
func axibs(n:PackedInt64Array) -> PackedInt64Array: return cabs(axis(n))
## the axes present in the number, or 1 if zero, ignoring sign
func saxibs(n:PackedInt64Array) -> PackedInt64Array: return cabs(saxis(n))

## truncates number
func trunc(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return n
		@warning_ignore("integer_division") SYSTEM.FRACTIONS, _: return [n[0]/n[2], n[1]/n[2], 1]

## floors number
func floor(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return n
		SYSTEM.FRACTIONS, _: return [intDiv(n[0],n[2]), intDiv(n[1],n[2]), 1]

## ceils number maybe 
func ceil(n:PackedInt64Array) -> PackedInt64Array:
	match system:
		SYSTEM.COMPLEX: return n
		SYSTEM.FRACTIONS, _: 
			var real:int = intDiv(n[0],n[2])
			var imag:int = intDiv(n[1],n[2])
			if M.neq([n[0],0,1], [real,0,1]): real += 1
			if M.neq([n[0],0,1], [imag,0,1]): imag += 1
			return [intDiv(n[0],n[2]), intDiv(n[1],n[2]), 1]

## (a,b -> a == b)
func eq(a:PackedInt64Array, b:PackedInt64Array) -> bool: return a == b

## (a,b -> a != b)
func neq(a:PackedInt64Array, b:PackedInt64Array) -> bool: return a != b

## (a,b -> r(a) > r(b))
func gt(a:PackedInt64Array, b:PackedInt64Array) -> bool:
	match system:
		SYSTEM.COMPLEX: return a[0] > b[0]
		SYSTEM.FRACTIONS, _: return a[0]*b[2] > b[0]*a[2]

## (a,b -> r(a) >= r(b))
func gte(a:PackedInt64Array, b:PackedInt64Array) -> bool: return !lt(a, b)

## (a,b -> r(a) < r(b))
func lt(a:PackedInt64Array, b:PackedInt64Array) -> bool:
	match system:
		SYSTEM.COMPLEX: return a[0] < b[0]
		SYSTEM.FRACTIONS, _: return a[0]*b[2] < b[0]*a[2]

## (a,b -> r(a) <= r(b))
func lte(a:PackedInt64Array, b:PackedInt64Array) -> bool: return !gt(a, b)

## (a,b -> ir(a) > ir(b))
func igt(a:PackedInt64Array, b:PackedInt64Array) -> bool:
	match system:
		SYSTEM.COMPLEX: return a[1] > b[1]
		SYSTEM.FRACTIONS, _: return a[1]*b[2] > b[1]*a[2]

## (a,b -> ir(a) >= ir(b))
func igte(a:PackedInt64Array, b:PackedInt64Array) -> bool: return !ilt(a, b)

## (a,b -> ir(a) < ir(b))
func ilt(a:PackedInt64Array, b:PackedInt64Array) -> bool:
	match system:
		SYSTEM.COMPLEX: return a[1] < b[1]
		SYSTEM.FRACTIONS, _: return a[1]*b[2] < b[1]*a[2]

## (a,b -> ir(a) <= ir(b))
func ilte(a:PackedInt64Array, b:PackedInt64Array) -> bool: return !igt(a, b)

## (a,b -> gt(a,b) && igt(a,b))
func cgt(a:PackedInt64Array, b:PackedInt64Array) -> bool: return gt(a,b) && igt(a,b)
## (a,b -> gte(a,b) && igte(a,b))
func cgte(a:PackedInt64Array, b:PackedInt64Array) -> bool: return gte(a,b) && igte(a,b)
## (a,b -> lt(a,b) && ilt(a,b))
func clt(a:PackedInt64Array, b:PackedInt64Array) -> bool: return lt(a,b) && ilt(a,b)
## (a,b -> lte(a,b) && ilte(a,b))
func clte(a:PackedInt64Array, b:PackedInt64Array) -> bool: return lte(a,b) && ilte(a,b)

## (a,b -> floor(a / b) == a / b)
func divisibleBy(a:PackedInt64Array, b:PackedInt64Array) -> bool: return nex(remainder(a,b))

## (a,b -> exists(r(a)) implies exists(r(b)) and exists(ir(a)) implies exists(ir(b)))
func implies(a:PackedInt64Array, b:PackedInt64Array) -> bool:
	return (a[0] == 0 || b[0] != 0) && (a[1] == 0 || b[1] != 0)

## signed implies
## (a,b -> exists(r(a)) implies sign(r(a)) == sign(r(b)) and exists(ir(a)) implies sign(ir(a)) == sign(ir(b)))
func simplies(a:PackedInt64Array, b:PackedInt64Array) -> bool:
	return (a[0] == 0 || sign(a[0]) == sign(b[0])) && (a[1] == 0 || sign(a[1]) == sign(b[1]))

# deciders

## "exists"
func ex(n:PackedInt64Array) -> bool:
	return neq(n, ZERO)

func nex(n:PackedInt64Array) -> bool:
	return eq(n, ZERO)

func isNonzeroReal(n:PackedInt64Array) -> bool:
	return n[0] and !n[1]

func isNonzeroImag(n:PackedInt64Array) -> bool:
	return !n[0] and n[1]

func isNonzeroAxial(n:PackedInt64Array) -> bool:
	return bool(n[0]) != bool(n[1])

func isReal(n:PackedInt64Array) -> bool:
	return !n[1]

func isImag(n:PackedInt64Array) -> bool:
	return !n[0]

func isAxial(n:PackedInt64Array) -> bool:
	return !(n[0] && n[1])

func isComplex(n:PackedInt64Array) -> bool:
	return n[0] and n[1]

func positive(n:PackedInt64Array) -> bool:
	return n[0] > 0

func negative(n:PackedInt64Array) -> bool:
	return n[0] < 0

func nonPositive(n:PackedInt64Array) -> bool:
	return n[0] <= 0

func nonNegative(n:PackedInt64Array) -> bool:
	return n[0] >= 0

func hasPositive(n:PackedInt64Array) -> bool:
	return n[0] > 0 or n[1] > 0

func hasNegative(n:PackedInt64Array) -> bool:
	return n[0] < 0 or n[1] < 0

func hasNonPositive(n:PackedInt64Array) -> bool:
	return n[0] <= 0 or n[1] <= 0

func hasNonNegative(n:PackedInt64Array) -> bool:
	return n[0] >= 0 or n[1] >= 0

func isInteger(n:PackedInt64Array) -> bool:
	match system:
		SYSTEM.COMPLEX: return true
		SYSTEM.FRACTIONS, _: return n[2] == 1

func isError(n:PackedInt64Array) -> bool:
	match system:
		SYSTEM.COMPLEX: return false
		SYSTEM.FRACTIONS, _: return n[2] == 0

# util

func toIpow(n:PackedInt64Array) -> int:
	if eq(n, ONE): return 0
	elif eq(n, I): return 1
	elif eq(n, nONE): return 2
	elif eq(n, nI): return 3
	else: assert(false); return 0

## only needs to work for real integers
func toInt(n:PackedInt64Array) -> int:
	return n[0]

func str(n:PackedInt64Array) -> String: return strWithInf(n,ZERO)

func strDistributeFraction(n:PackedInt64Array) -> String: return strWithInfDistributeFraction(n,ZERO)

func strWithInf(n:PackedInt64Array,infAxes:PackedInt64Array) -> String:
	var rComponent:String
	var iComponent:String = ""
	var rnum:int = toInt(rnumer(n))
	var inum:int = toInt(irnumer(n))
	if ex(r(infAxes)): rComponent = "-~" if rnum < 0 else "~"
	elif rnum: rComponent = str(rnum)
	if inum:
		if inum > 0 and rnum: iComponent += "+"
		if ex(i(infAxes)): iComponent += "-~i" if inum < 0 else "~i"
		else: iComponent += str(inum) + "i"
	if system & SYSTEM.FRACTIONS:
		var den:int = toInt(denom(n))
		if den == 0: return "ERROR"
		if den != 1:
			if isComplex(n):
				rComponent = "(" + rComponent
				iComponent += ")"
			iComponent += "/" + str(den)
	if !rnum and !inum: return "0"
	return rComponent + iComponent

func strWithInfDistributeFraction(n:PackedInt64Array,infAxes:PackedInt64Array) -> String:
	if !(system & SYSTEM.FRACTIONS): return strWithInf(n, infAxes)
	if nex(denom(n)): return "ERROR"
	var rComponent:String
	var iComponent:String = ""
	var rnum:int = toInt(rnumer(n))
	var inum:int = toInt(irnumer(n))
	if !rnum and !inum: return "0"
	if ex(r(infAxes)): rComponent = "-~" if rnum < 0 else "~"
	elif rnum:
		var rpart:PackedInt64Array = simplify(r(n))
		var rdenom:int = toInt(denom(rpart))
		rComponent = str(toInt(numer(rpart)))
		if rdenom != 1: rComponent += "/" + str(rdenom)
	if inum:
		if inum > 0 and rnum: iComponent += "+"
		if ex(i(infAxes)): iComponent += "-~i" if inum < 0 else "~i"
		else:
			var ipart:PackedInt64Array = simplify(ir(n))
			var idenom:int = toInt(denom(ipart))
			iComponent += str(toInt(numer(ipart))) + "i"
			if idenom != 1: iComponent += "/" + str(idenom)
	return rComponent + iComponent

## greatest (positive) common divisor
## https://en.wikipedia.org/wiki/Euclidean_algorithm
func gcd(a:int, b:int) -> int:
	a = abs(a)
	b = abs(b)
	if a == 0: return b
	if b == 0: return a
	while b != 0:
		var temp:int = b
		b = a % b
		a = temp
	return a

## in both axes, keeps the magnitude of a greater than or equal to the magnitude of b, in the direction of b. if b doesnt exist in that axis, it will be unaffected
func keepAbove(a:PackedInt64Array,b:PackedInt64Array) -> PackedInt64Array:
	return along(M.max(along(a,orelse(b,a)), cabs(b)), orelse(b,a))

## (a,b -> floor(a/b))
func intDiv(a:int, b:int) -> int:
	@warning_ignore("integer_division")
	if a*b < 0 and a % b != 0: return a/b-1
	@warning_ignore("integer_division")
	return a/b
