class_name TextDrawer
extends Node2D

var drawMain:RID
var font:Font
var fontSize:int
var smallFontSize:int # for fractions

enum TYPE {String, Number, NumberMixedMode, NumberImproperMode, Spacing}

var texts:Array[Array] = []
var textsChanged:bool = false
var textsIndex:int = 0

func _init(parent:Node2D, _font:Font, _fontSize:int, _smallFontSize:int) -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain, get_canvas_item())
	font = _font
	fontSize = _fontSize
	smallFontSize = _smallFontSize
	parent.add_child(self)

func addString(string:String, color:Color) -> void: addValue_([TYPE.String, string, color])
func addNumber(number:PackedInt64Array, color:Color) -> void: addValue_([TYPE.Number, number, color])
func addNumberMixedMode(number:PackedInt64Array, color:Color) -> void: addValue_([TYPE.NumberMixedMode, number, color])
func addNumberImproperMode(number:PackedInt64Array, color:Color) -> void: addValue_([TYPE.NumberImproperMode, number, color])
func addSpacing(spacing:float) -> void: addValue_([TYPE.Spacing, spacing])

func evaluate() -> void:
	textsIndex = 0
	if !textsChanged: return
	textsChanged = false
	RenderingServer.canvas_item_clear(drawMain)
	var x:float = 0
	for text in texts:
		match text[0]:
			TYPE.String:
				var color:Color = text[2]
				font.draw_string(drawMain, Vector2(x, 0), text[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
				x += font.get_string_size(text[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
			TYPE.Number, TYPE.NumberMixedMode, TYPE.NumberImproperMode:
				var number:PackedInt64Array = text[1]
				var color:Color = text[2]
				var mixedMode:bool = text[0] == TYPE.NumberMixedMode or (text[0] != TYPE.NumberImproperMode and Game.mixedFractionsMode)
				if !M.isInteger(number):
					const FRACTION_VERTICAL_OFFSET:float = 2
					if mixedMode:
						var wholePart:PackedInt64Array = M.trunc(number)
						if M.ex(wholePart):
							number = M.sub(number, wholePart)
							var string:String = M.str(wholePart)
							font.draw_string(drawMain, Vector2(x, 0), string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
							x += font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x + 2
					var numerator:String = M.str(M.numer(number))
					var denominator:String = M.str(M.denom(number))
					var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, smallFontSize)
					var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, smallFontSize)
					var width:float = max(numerSize.x, denomSize.x)
					RenderingServer.canvas_item_add_rect(drawMain, Rect2(Vector2(x,2+FRACTION_VERTICAL_OFFSET), Vector2(width,2)), color)
					font.draw_string(drawMain, Vector2(x+(width-numerSize.x)/2, -numerSize.y/2-4+FRACTION_VERTICAL_OFFSET), numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, smallFontSize, color)
					font.draw_string(drawMain, Vector2(x+(width-denomSize.x)/2, denomSize.y/2+4+FRACTION_VERTICAL_OFFSET), denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, smallFontSize, color)
					x += width
				else:
					var string:String = M.str(number)
					font.draw_string(drawMain, Vector2(x, 0), string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
					x += font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
			TYPE.Spacing:
				x += text[1]

func _notification(what:int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			RenderingServer.free_rid(drawMain)

func addValue_(value:Array) -> void:
	if textsIndex >= len(texts):
		texts.append(value)
		textsChanged = true
	elif texts[textsIndex] != value:
		texts[textsIndex] = value
		textsChanged = true
	textsIndex += 1

func _draw() -> void:
	evaluate()
