extends PanelContainer
class_name NumberEdit

signal valueSet(value:PackedInt64Array)

const FNUMBEREDIT:Font = preload("res://resources/fonts/fNumberEdit.tres")

enum CURSOR_MODE {NORMAL, NUMBER}

var cursorMode:CURSOR_MODE = CURSOR_MODE.NORMAL:
	set(to):
		cursorMode = to
		match cursorMode:
			CURSOR_MODE.NUMBER: %cursor.color = Color("#0083fd88")
			_: %cursor.color = Color("#00ffffaa")
var cursorStart:int = 0
var cursorEnd:int = 0

var cursorSelectedNumber:int = 0 # used in NUMBER mode

var text:String = ""
var textLen:int = 0

var numbers:int = 0
var numberStarts:Array[int] = []
var numberEnds:Array[int] = []
var numberValues:Array[int] = []
var numberSemiNegative:Array[bool] = [] # if a number's sign is currently inaccurate, from flipping a +/- without reparsing. saves a bit of performance
var texts:Array[String] = [""] # one at the start and one after each number. may be empty
var currentExpression:Array = []
var expressionError:ERROR = ERROR.NONE
var result:PackedInt64Array = M.ZERO
var isZeroI:bool = false
var baseForm:BASE_FORM = BASE_FORM.FACTORED

var shapedText:RID
@onready var ts = TextServerManager.get_primary_interface()
var mouseDragStart:int = -1 # the character a mouse drag started on; -1 for not currently dragging

enum TYPE {ALL, AXIAL, NONNEGATIVE_INTEGER}

enum ERROR {NONE, SYNTAX, NUMBER, ZERO}
const ERROR_COLOR:Color = Color("#ff0066")

enum BASE_FORM {FACTORED, DISTRIBUTED}

@export var type:TYPE = TYPE.ALL:
	set(value):
		type = value
		updateRestrictionDisplay()
@export var allowZeroI:bool = false:
	set(value):
		allowZeroI = value
		if !allowZeroI: isZeroI = false
		updateRestrictionDisplay()
@export var allowZero:bool = true:
	set(value):
		allowZero = value
		updateRestrictionDisplay()

func _ready() -> void:
	owner.numberEdits.append(self) # the scene root
	shapedText = ts.create_shaped_text()
	updateRestrictionDisplay()

func setValue(value:PackedInt64Array, manual:bool=true) -> void:
	match baseForm:
		BASE_FORM.FACTORED: text = M.str(value)
		BASE_FORM.DISTRIBUTED: text = M.strDistributeFraction(value)
	if text == "ERROR": text = "0/0"
	parseText(manual)
	buildText()

func setZeroI() -> void:
	text = "0i"
	parseText(true)
	buildText()

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ConvertNumberChange.new(self, from, &"result"))
	updateRestrictionDisplay()

func updateRestrictionDisplay() -> void:
	var explanation:String = "{ Number Edit ("
	match type:
		TYPE.ALL:
			if M.system & M.SYSTEM.FRACTIONS:
				match baseForm:
					BASE_FORM.FACTORED:
						%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/complexRational.png")
						%changeBaseForm.icon = preload("res://assets/ui/focusDialog/numberEdit/restrictions/complexRationalB.png")
					BASE_FORM.DISTRIBUTED:
						%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/complexRationalB.png")
						%changeBaseForm.icon = preload("res://assets/ui/focusDialog/numberEdit/restrictions/complexRational.png")
				explanation += "Complex rational"
			else:
				%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/complex.png")
				explanation += "Complex"
		TYPE.AXIAL:
			if M.system & M.SYSTEM.FRACTIONS:
				%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/axialRational.png")
				explanation += "Axial rational"
			else:
				%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/axial.png")
				explanation += "Axial"
		TYPE.NONNEGATIVE_INTEGER:
			if allowZero:
				%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/nonnegativeInteger.png")
				explanation += "Nonnegative integer"
			else:
				%type.texture = preload("res://assets/ui/focusDialog/numberEdit/restrictions/positiveInteger.png")
				explanation += "Positive integer"
	if !allowZero: explanation += " nonzero"
	explanation += " number) }"
	%restriction.get_meta(&"explanation").explanation = explanation
	%changeBaseForm.visible = M.system & M.SYSTEM.FRACTIONS and type == TYPE.ALL
	%nonzero.visible = !allowZero and type != TYPE.NONNEGATIVE_INTEGER
	%zeroi.visible = allowZeroI
	%sideCont.size = Vector2.ZERO

func interact(last:bool=false) -> void:
	theme_type_variation = &"NumberEditPanelContainerError" if expressionError else &"NumberEditPanelContainerSelected"
	if numbers: numberCaptureCursor(numbers-1 if last else 0)
	%cursor.visible = true
	%side.visible = true
	updateRestrictionDisplay()

func deinteract() -> void:
	setValue(result)
	theme_type_variation = &"NumberEditPanelContainer"
	baseForm = BASE_FORM.FACTORED
	%cursor.visible = false
	%side.visible = false

func parseText(manual:bool=false) -> void:
	textLen = len(text)
	# tokenize; extract numbers
	var i:int = 0
	var thisNumberStart:int = -1 # -1 for not currently parsing a number
	var previousNumberEnd:int = 0
	numberStarts.clear()
	numberEnds.clear()
	numberValues.clear()
	numberSemiNegative.clear()
	texts.clear()
	numbers = 0
	var isNumber:bool
	var front:Array[Vector2i] = []
	var tokens:Array[Vector2i] = []
	var layer:int = 0
	for symbol in text + " ":
		isNumber = "0123456789".contains(symbol) or (!isNumber and symbol == "-" and i + 1 != textLen and "0123456789".contains(text[i+1]))
		# end of text
		if previousNumberEnd != -1 and isNumber or i == textLen:
			texts.append(text.substr(previousNumberEnd, i-previousNumberEnd))
		if isNumber:
			# start of number
			if thisNumberStart == -1:
				numbers += 1
				numberStarts.append(i)
				numberSemiNegative.append(false)
				thisNumberStart = i
				previousNumberEnd = -1
		else:
			# end of number
			if thisNumberStart != -1:
				var value:int = text.substr(thisNumberStart,i-thisNumberStart).to_int()
				numberEnds.append(i)
				numberValues.append(value)
				thisNumberStart = -1
				previousNumberEnd = i
				tokens.append(Vector2i(TOKEN.NUMBER,numbers-1))
			match symbol:
				")":
					layer -= 1
					if layer < 0: # insert missing lbracket at start
						layer = 0
						front.append(Vector2i(TOKEN.LBRACKET, 0))
					tokens.append(Vector2i(TOKEN.RBRACKET, 0))
				"(":
					layer += 1
					tokens.append(Vector2i(TOKEN.LBRACKET, 0))
				"+": tokens.append(Vector2i(TOKEN.CROSS, 0))
				"-": tokens.append(Vector2i(TOKEN.DASH, 0))
				"x", "*": tokens.append(Vector2i(TOKEN.X, 0))
				"/": tokens.append(Vector2i(TOKEN.SLASH, 0))
				"i": tokens.append(Vector2i(TOKEN.I, 0))
				_:
					if symbol != " ": tokens.append(Vector2i(TOKEN.UNKNOWN, 0))
		i += 1
	# insert missing rbrackets at end
	while layer > 0:
		layer -= 1
		tokens.append(Vector2i(TOKEN.RBRACKET, 0))
	front.append_array(tokens)
	tokens = front
	# parse tokens into expression
	currentExpression = parseTokens(tokens, STEP.SUM)
	evaluate(manual)

func evaluate(manual:bool=false) -> void:
	expressionError = ERROR.NONE
	result = evaluateExpression(currentExpression)
	isZeroI = allowZeroI and text == "0i"
	if !allowZero and !isZeroI and M.nex(result) and expressionError != ERROR.SYNTAX: expressionError = ERROR.ZERO
	if !expressionError:
		if !manual:
			match type:
				TYPE.ALL: valueSet.emit(result)
				TYPE.AXIAL:
					if M.isAxial(result): valueSet.emit(result)
					else: expressionError = ERROR.NUMBER
				TYPE.NONNEGATIVE_INTEGER:
					if M.isReal(result) and M.isInteger(result) and M.gte(result, M.ZERO): valueSet.emit(result)
					else: expressionError = ERROR.NUMBER
	theme_type_variation = (&"NumberEditPanelContainerError" if expressionError else &"NumberEditPanelContainerSelected") if owner.interacted == self else &"NumberEditPanelContainer"
	%type.modulate = ERROR_COLOR if expressionError == ERROR.NUMBER else Color.WHITE
	%nonzero.modulate = ERROR_COLOR if expressionError == ERROR.ZERO else Color.WHITE

enum TOKEN {NUMBER, LBRACKET, RBRACKET, CROSS, DASH, X, SLASH, I, UNKNOWN}
enum STEP {VALUE, BRACKET, AXIS, PRODUCT, SUM} # symbol in the parsing expression grammar

# expands back to front
# i dont think im using this right lmao
# Sum     ← (Sum ('+' / '-'))? Product
# Product ← (Product ('*' / '/'))? Axis
# Axis    ← ('-' / '+')* Bracket? 'i'*
# Bracket ← ('(' Sum ')' / Value)+
# Value   ← [0-9]+

# tokens is Array[Vector2i(TOKEN, data)]
# data is the number index when the token is a TOKEN.NUMBER. otherwise unused
func parseTokens(tokens:Array[Vector2i], step:STEP) -> Array: # returns expression
	match step:
		STEP.SUM:
			if len(tokens) == 0:
				# empty bracket!
				return [EXPRESSION.CONSTANT, M.ZERO]
			var layer:int = 0
			for index in range(len(tokens)-1,-1,-1):
				var token:TOKEN = tokens[index].x as TOKEN
				match token:
					TOKEN.RBRACKET: layer += 1
					TOKEN.LBRACKET: layer -= 1
					TOKEN.CROSS, TOKEN.DASH:
						if layer == 0:
							if index == 0: break
							if index == len(tokens)-1:
								#print("sum error!")
								return [EXPRESSION.ERROR]
							# we only absorb the leftmost one, so that unary negation can absorb the rest
							# "1---3" -> minus("1", "--3")
							if tokens[index-1].x in [TOKEN.CROSS, TOKEN.DASH]: continue
							# sum!
							return [
								EXPRESSION.ADD if token == TOKEN.CROSS else EXPRESSION.SUB,
								parseTokens(tokens.slice(0,index), STEP.SUM),
								parseTokens(tokens.slice(index+1), STEP.PRODUCT)
							]
			return parseTokens(tokens, STEP.PRODUCT)
		STEP.PRODUCT:
			var layer:int = 0
			for index in range(len(tokens)-1,-1,-1):
				var token:TOKEN = tokens[index].x as TOKEN
				match token:
					TOKEN.RBRACKET: layer += 1
					TOKEN.LBRACKET: layer -= 1
					TOKEN.X, TOKEN.SLASH:
						if layer == 0:
							if index == 0 or index == len(tokens)-1:
								#print("product error!")
								return [EXPRESSION.ERROR]
							# product!
							return [
								EXPRESSION.TIMES if token == TOKEN.X else EXPRESSION.DIVIDE,
								parseTokens(tokens.slice(0,index), STEP.PRODUCT),
								parseTokens(tokens.slice(index+1), STEP.AXIS)
							]
			return parseTokens(tokens, STEP.AXIS)
		STEP.AXIS:
			var axis:PackedInt64Array = M.ONE
			while tokens[0].x in [TOKEN.CROSS, TOKEN.DASH]:
				if tokens.pop_front().x == TOKEN.DASH: axis = M.negate(axis)
				if len(tokens) == 0:
					#print("axis error!")
					return [EXPRESSION.ERROR]
			while tokens[-1].x == TOKEN.I:
				tokens.pop_back()
				axis = M.rotate(axis)
				if len(tokens) == 0:
					# multiple of i!
					return [EXPRESSION.CONSTANT, axis]
			# axis!
			if M.neq(axis, M.ONE):
				return [EXPRESSION.AXIS, axis, parseTokens(tokens, STEP.BRACKET)]
			else: return parseTokens(tokens, STEP.BRACKET)
		STEP.BRACKET:
			var layer:int = 0
			var rightBracket:int = 0
			for index in range(len(tokens)-1,-1,-1):
				var token:TOKEN = tokens[index].x as TOKEN
				match token:
					TOKEN.RBRACKET:
						layer += 1
						if !rightBracket:
							rightBracket = index
					TOKEN.LBRACKET:
						layer -= 1
						if layer == 0:
							# bracket!
							if rightBracket == len(tokens)-1:
								if index == 0: # "(sum)"
									return parseTokens(tokens.slice(index+1,rightBracket), STEP.SUM)
								return [ # "...(sum)"
									EXPRESSION.TIMES,
									parseTokens(tokens.slice(0,index), STEP.BRACKET),
									parseTokens(tokens.slice(index+1,rightBracket), STEP.SUM)
								]
							else:
								if index == 0:
									return [ # "(sum)value"
										EXPRESSION.TIMES,
										parseTokens(tokens.slice(index+1,rightBracket), STEP.SUM),
										parseTokens(tokens.slice(rightBracket+1), STEP.VALUE)
									]
								return [ # "...(sum)value"
									EXPRESSION.TIMES,
									parseTokens(tokens.slice(0,index), STEP.BRACKET),
									[
										EXPRESSION.TIMES,
										parseTokens(tokens.slice(index+1,rightBracket), STEP.SUM),
										parseTokens(tokens.slice(rightBracket+1), STEP.VALUE)
									]
								]
			return parseTokens(tokens, STEP.VALUE)
		STEP.VALUE, _:
			if len(tokens) > 1 or tokens[0].x != TOKEN.NUMBER:
				#print("value error!")
				return [EXPRESSION.ERROR]
			# value!
			return [EXPRESSION.NUMBER, tokens[0].y]

func selectAll() -> void:
	cursorMode = CURSOR_MODE.NORMAL
	cursorStart = 0
	cursorEnd = textLen
	placeCursor()

enum EXPRESSION {NUMBER, AXIS, ADD, SUB, TIMES, DIVIDE, ERROR, CONSTANT}
# number: [EXPRESSION.NUMBER, number index]
# constant: [EXPRESSION.CONSTANT, value]
# axis: [EXPRESSION.AXIS, axis, expression]
# operator: [EXPRESSION.operator, expression, expression]
# error: [EXPRESSION.error, information]

func evaluateExpression(expression:Array) -> PackedInt64Array:
	match expression[0]:
		EXPRESSION.NUMBER:
			if numberSemiNegative[expression[1]]: return M.negate(M.N(numberValues[expression[1]]))
			return M.N(numberValues[expression[1]])
		EXPRESSION.AXIS: return M.times(expression[1], evaluateExpression(expression[2]))
		EXPRESSION.ADD: return M.add(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.SUB: return M.sub(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.TIMES: return M.times(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.DIVIDE: return M.divide(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.CONSTANT: return expression[1]
		EXPRESSION.ERROR, _:
			expressionError = ERROR.SYNTAX
			return M.ZERO

func buildText() -> void:
	var formattedText:String = texts[0]
	for i in numbers:
		formattedText += "[color=ffffff]%s[/color]" % numberValues[i]
		formattedText += texts[i+1]
	%drawText.text = formattedText
	text = %drawText.get_parsed_text()
	ts.shaped_text_clear(shapedText)
	ts.shaped_text_add_string(shapedText, text, FNUMBEREDIT.get_rids(), 16)
	placeCursor()

func receiveKey(key:InputEventKey) -> bool:
	Game.editor.grab_focus()
	if Editor.eventIs(key, &"numberEvaluate"): setValue(result)
	else:
		match key.keycode:
			KEY_RIGHT:
				cursorMode = CURSOR_MODE.NORMAL
				if Input.is_key_pressed(KEY_SHIFT):
					if Input.is_key_pressed(KEY_CTRL): cursorEnd = nextPointOfInterest()
					else: cursorEnd = min(textLen, cursorEnd+1)
				else:
					if cursorEnd > cursorStart: cursorStart = cursorEnd
					elif cursorStart < textLen:
						if Input.is_key_pressed(KEY_CTRL): cursorStart = nextPointOfInterest()
						else: cursorStart += 1
						cursorEnd = cursorStart
						numberCaptureCursor(numberAtIndex(cursorStart))
				placeCursor()
			KEY_LEFT:
				cursorMode = CURSOR_MODE.NORMAL
				if Input.is_key_pressed(KEY_SHIFT):
					if Input.is_key_pressed(KEY_CTRL): cursorStart = previousPointOfInterest()
					else: cursorStart = max(0, cursorStart-1)
				else:
					if cursorEnd > cursorStart: cursorEnd = cursorStart
					elif cursorStart > 0:
						if Input.is_key_pressed(KEY_CTRL): cursorStart = previousPointOfInterest()
						else: cursorStart -= 1
						cursorEnd = cursorStart
						numberCaptureCursor(numberAtIndex(cursorStart))
				placeCursor()
			KEY_UP:
				match cursorMode:
					CURSOR_MODE.NORMAL:
						for number in numbers:
							if numberStarts[number] >= cursorStart && numberEnds[number] <= cursorEnd: changeNumber(number, 1)
					CURSOR_MODE.NUMBER:
						changeNumber(cursorSelectedNumber, 1)
						numberCaptureCursor(cursorSelectedNumber)
			KEY_DOWN:
				match cursorMode:
					CURSOR_MODE.NORMAL:
						for number in numbers:
							if numberStarts[number] >= cursorStart && numberEnds[number] <= cursorEnd: changeNumber(number, -1)
					CURSOR_MODE.NUMBER:
						changeNumber(cursorSelectedNumber, -1)
						numberCaptureCursor(cursorSelectedNumber)
			KEY_TAB:
				if Input.is_key_pressed(KEY_SHIFT):
					for number in range(numbers-1,-1,-1): if numberStarts[number] < cursorStart:
						numberCaptureCursor(number); return true
				else:
					for number in range(numbers): if numberEnds[number] > cursorEnd:
						numberCaptureCursor(number); return true
				return false
			KEY_A:
				if Input.is_key_pressed(KEY_CTRL):
					selectAll()
			KEY_BACKSPACE:
				if text == "": return true
				match cursorMode:
					CURSOR_MODE.NORMAL:
						if cursorEnd == cursorStart:
							var prevStart:int = cursorStart
							if cursorStart == 0: return false
							Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorStart", previousPointOfInterest() if Input.is_key_pressed(KEY_CTRL) else cursorStart - 1))
							Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
							Changes.addChange(Changes.NumberEditTextChange.new(self, text.erase(cursorStart, prevStart-cursorStart)))
							placeCursor()
						else:
							Changes.addChange(Changes.NumberEditTextChange.new(self, text.erase(cursorStart, cursorEnd - cursorStart)))
							Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
							placeCursor()
					CURSOR_MODE.NUMBER:
						if numberValues[cursorSelectedNumber] == 0 or Input.is_key_pressed(KEY_CTRL):
							cursorMode = CURSOR_MODE.NORMAL
							Changes.addChange(Changes.NumberEditTextChange.new(self, text.erase(cursorStart, cursorEnd - cursorStart)))
							Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
							placeCursor()
						else:
							setNumber(cursorSelectedNumber, 0)
							numberCaptureCursor(cursorSelectedNumber)
			_: return false
	return true

func receiveUnhandledKey(key:InputEventKey) -> bool:
	if key.keycode >= 32 and key.keycode < 128:
		if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_META): return false
		match cursorMode:
			CURSOR_MODE.NORMAL:
				var character:String = char(key.unicode)
				if cursorStart == 0 and cursorEnd == textLen:
					if Editor.eventIs(key, &"numberNegate"):
						setValue(M.times(result,M.nONE), false)
						selectAll()
						return true
					elif Editor.eventIs(key, &"numberTimesI"):
						setValue(M.times(result,M.I), false)
						selectAll()
						return true
				if cursorEnd > cursorStart:
					Changes.addChange(Changes.NumberEditTextChange.new(self, text.erase(cursorStart, cursorEnd - cursorStart), false))
				elif "0123456789".contains(character):
					var endNumber:int = numberEnds.find(cursorStart)
					if endNumber != -1:
						setNumber(endNumber, numberValues[endNumber]*10+character.to_int())
						Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorStart", numberEnds[endNumber]))
						Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
						placeCursor()
						return true
					var startNumber:int = numberStarts.find(cursorStart)
					if startNumber != -1:
						setNumber(startNumber, character.to_int()*(10**len(str(numberValues[startNumber]))) + numberValues[startNumber])
						Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorStart", cursorStart+1))
						Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
						placeCursor()
						return true
				Changes.addChange(Changes.NumberEditTextChange.new(self, text.insert(cursorStart, character)))
				Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorStart", cursorStart+1))
				Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
				placeCursor()
			CURSOR_MODE.NUMBER:
				var character:String = char(key.unicode)
				if Editor.eventIs(key, &"numberNegate"):
					setNumber(cursorSelectedNumber, -numberValues[cursorSelectedNumber])
					numberCaptureCursor(cursorSelectedNumber)
				elif Editor.eventIs(key, &"numberTimesI"):
					var textAfter:String = texts[cursorSelectedNumber+1]
					if textAfter and textAfter[0] == "i":
						Changes.addChange(Changes.NumberEditNumberChange.new(self, cursorSelectedNumber+1, &"texts", textAfter.substr(1)))
						setNumber(cursorSelectedNumber, -numberValues[cursorSelectedNumber])
						numberCaptureCursor(cursorSelectedNumber)
					else:
						Changes.addChange(Changes.NumberEditNumberChange.new(self, cursorSelectedNumber+1, &"texts", "i" + textAfter))
						buildText()
					parseText()
				elif "0123456789".contains(character):
					setNumber(cursorSelectedNumber, (-1 if numberValues[cursorSelectedNumber] < 0 else 1)*character.to_int())
					Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorStart", numberEnds[cursorSelectedNumber]))
					Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", cursorStart))
					cursorMode = CURSOR_MODE.NORMAL
					placeCursor()
				else: return false
	else: return false
	return true

func _gui_input(event:InputEvent) -> void:
	if event is not InputEventMouse: return
	var mouseX:float = event.position.x - %drawText.position.x
	var mouseIndex:int = ts.shaped_text_hit_test_position(shapedText, mouseX)
	if event is InputEventMouseMotion or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Editor.isLeftClick(event):
			if owner.interacted != self: owner.interact(self)
			mouseDragStart = mouseIndex
		if mouseDragStart != -1:
			var mouseDragEnd:int = mouseIndex
			if mouseDragEnd > mouseDragStart:
				cursorStart = mouseDragStart
				cursorEnd = mouseDragEnd
			else:
				cursorStart = mouseDragEnd
				cursorEnd = mouseDragStart
			cursorMode = CURSOR_MODE.NORMAL
			placeCursor()
	var numberAtMouse:int = numberAtIndex(mouseIndex, true)
	var tooFar:bool = mouseX > ts.shaped_text_get_width(shapedText)
	if Editor.isLeftUnclick(event):
			mouseDragStart = -1
			if cursorStart == cursorEnd and !tooFar: numberCaptureCursor(numberAtMouse)
	mouse_default_cursor_shape = Control.CURSOR_VSPLIT if mouseDragStart == -1 and numberAtMouse != -1 and !tooFar else Control.CURSOR_IBEAM
	if numberAtMouse != -1 and event is InputEventMouseButton and event.pressed and !tooFar:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP: changeNumber(numberAtMouse, 1)
			MOUSE_BUTTON_WHEEL_DOWN: changeNumber(numberAtMouse, -1)
			_: return
		get_viewport().set_input_as_handled()
		numberCaptureCursor(numberAtMouse)
		placeCursor()
		if self not in Explainer.explainedControls: Explainer._explain(self) # idk why it breaks explain

# not sure how powerful i want these to be
## for ctrl+right
func nextPointOfInterest() -> int:
	return textLen
	#var pointOfInterest:int = textLen
	#for number in numbers:
	#	if numberEnds[number] > cursorEnd: pointOfInterest = min(numberEnds[number], pointOfInterest)
	#	if numberStarts[number] > cursorEnd: pointOfInterest = min(numberStarts[number], pointOfInterest)
	#return pointOfInterest

## for ctrl+left
func previousPointOfInterest() -> int:
	return 0
	#var pointOfInterest:int = 0
	#for number in numbers:
	#	if numberEnds[number] < cursorStart: pointOfInterest = max(numberEnds[number], pointOfInterest)
	#	if numberStarts[number] < cursorStart: pointOfInterest = max(numberStarts[number], pointOfInterest)
	#return pointOfInterest

func changeNumber(number:int, by:int) -> void:
	if numberSemiNegative[number]: setNumber(number, numberValues[number] - by)
	else: setNumber(number, numberValues[number] + by)

func setNumber(number:int, to:int) -> void:
	var prevLen:int = numberEnds[number] - numberStarts[number]
	Changes.addChange(Changes.NumberEditNumberChange.new(self, number, &"numberValues", numberCheckSign(number, to)))
	var lenChange:int = len(str(numberValues[number])) - prevLen
	numberEnds[number] += lenChange
	for shiftedNumber in range(number+1, numbers):
		Changes.addChange(Changes.NumberEditNumberChange.new(self, shiftedNumber, &"numberStarts", numberStarts[shiftedNumber] + lenChange))
		Changes.addChange(Changes.NumberEditNumberChange.new(self, shiftedNumber, &"numberEnds", numberEnds[shiftedNumber] + lenChange))
	Changes.addChange(Changes.GlobalPropertyChange.new(self, &"textLen", textLen + lenChange))
	buildText()
	evaluate()

func numberCheckSign(number:int, to:int) -> int:
	var numberText:String = texts[number] # the text before the number
	if len(numberText) == 0: return to
	if numberText[-1] == "-":
		if to <= 0:
			numberText[-1] = "+"
			Changes.addChange(Changes.NumberEditNumberChange.new(self, number, &"texts", numberText))
			Changes.addChange(Changes.NumberEditNumberChange.new(self, number, &"numberSemiNegative", !numberSemiNegative[number]))
			return -to
	elif to < 0 and numberText[-1] == "+":
		numberText[-1] = "-"
		Changes.addChange(Changes.NumberEditNumberChange.new(self, number, &"texts", numberText))
		Changes.addChange(Changes.NumberEditNumberChange.new(self, number, &"numberSemiNegative", !numberSemiNegative[number]))
		return -to
	return to

func numberCaptureCursor(number:int) -> void:
	if number == -1: return
	Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorStart", numberStarts[number]))
	Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorEnd", numberEnds[number]))
	Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorSelectedNumber", number))
	Changes.addChange(Changes.GlobalPropertyChange.new(self, &"cursorMode", CURSOR_MODE.NUMBER))
	placeCursor()

## returns the index of the number at the index, or -1 if not found
func numberAtIndex(index:int, strict:bool=false) -> int:
	if strict:
		for number in numbers: if index > numberStarts[number] and index <= numberEnds[number]: return number
	else:
		for number in numbers: if index >= numberStarts[number] and index <= numberEnds[number]: return number
	return -1

const CURSOR_MARGIN:int = 15

func placeCursor() -> void:
	cursorStart = clamp(cursorStart, 0, textLen)
	cursorEnd = clamp(cursorEnd, 0, textLen)
	%cursor.position.x = FNUMBEREDIT.get_string_size(text.substr(0,cursorStart)).x - 1
	%cursor.size.x = FNUMBEREDIT.get_string_size(text.substr(0,cursorEnd)).x - %cursor.position.x + 1
	var cursorEndPos:float = %cursor.position.x + %cursor.size.x
	if cursorEndPos + %drawText.position.x + CURSOR_MARGIN > size.x:
		%drawText.position.x = size.x - cursorEndPos - CURSOR_MARGIN
	if %cursor.position.x + %drawText.position.x < CURSOR_MARGIN:
		%drawText.position.x = min(0, -%cursor.position.x + CURSOR_MARGIN)

func _baseFormChanged():
	match baseForm:
		BASE_FORM.FACTORED: baseForm = BASE_FORM.DISTRIBUTED
		BASE_FORM.DISTRIBUTED: baseForm = BASE_FORM.FACTORED
	updateRestrictionDisplay()
	setValue(result)
	if cursorMode == CURSOR_MODE.NUMBER: numberCaptureCursor(cursorSelectedNumber)
