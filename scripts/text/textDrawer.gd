class_name TextDrawer
extends Node2D

var drawMain:RID
var setting:SETTING

enum SETTING {FKEYNUM, FKEYBULK}
enum TYPE {String, Number, Spacing}

var texts:Array[Array] = []
var textsChanged:bool = false
var textsIndex:int = 0

var mixedFractionsMode:bool = false

func _init(parent:Node2D, _setting:SETTING) -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain, get_canvas_item())
	setting = _setting
	parent.add_child(self)

func setMixedFractionsMode(to:bool) -> void:
	if mixedFractionsMode != to: textsChanged = true
	mixedFractionsMode = to

func addString(string:String, color:Color, outline:Color=Color.TRANSPARENT) -> void: addValue_([TYPE.String, string, color, outline])
func addNumber(number:PackedInt64Array, color:Color, outline:Color=Color.TRANSPARENT) -> void: addValue_([TYPE.Number, number, color, outline])
func addSpacing(spacing:float) -> void: addValue_([TYPE.Spacing, spacing])

func _draw() -> void:
	if textsIndex < len(texts):
		textsChanged = true
		texts = texts.slice(0, textsIndex)
	textsIndex = 0
	if !textsChanged: return
	textsChanged = false
	RenderingServer.canvas_item_clear(drawMain)
	var font:Font = getFont()
	var fontSize:int = getFontSize()
	var fractionFontSize:int = getFractionFontSize()
	var x:float = 0
	for text in texts:
		match text[0]:
			TYPE.String:
				x += drawText_(font, text[1], Vector2(x, 0), fontSize, text[2], text[3]).x
			TYPE.Number:
				var fractionVerticalOffset:float = getFractionVerticalOffset()
				var color:Color = text[2]
				var outline:Color = text[3]
				if M.isError(text[1]):
					x += drawText_(font, "ERROR", Vector2(x, 0), fontSize, color, outline).x
					continue
				var first:bool = true
				for part in [M.r(text[1]), M.i(text[1])]:
					if M.ex(part):
						if M.hasNegative(part):
							x += drawText_(font, "-", Vector2(x, 0), fontSize, color, outline).x
							part = M.negate(part)
						elif !first:
							x += drawText_(font, "+", Vector2(x, 0), fontSize, color, outline).x
						if M.isInteger(part) or (mixedFractionsMode and M.ex(M.trunc(part))):
							x += drawText_(font, M.str(M.trunc(part)), Vector2(x, 0), fontSize, color, outline).x
							if !M.isInteger(part): x += 2
						if !M.isInteger(part):
							var fraction:PackedInt64Array = M.remainder(part, M.ONE()) if mixedFractionsMode else part
							var numerator:String = M.str(M.numer(fraction))
							var denominator:String = M.str(M.denom(fraction))
							var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var width:float = max(numerSize.x, denomSize.x)
							var fractionLineRect:Rect2 = Rect2(Vector2(x,getFractionLineVerticalPosition()+fractionVerticalOffset), Vector2(width,2))
							if outline.a: RenderingServer.canvas_item_add_rect(drawMain, Rect2(fractionLineRect.position-Vector2.ONE,fractionLineRect.size+Vector2.ONE*2), outline)
							RenderingServer.canvas_item_add_rect(drawMain, fractionLineRect, color)
							drawText_(font, numerator, Vector2(x+(width-numerSize.x)/2, -numerSize.y/2-4+fractionVerticalOffset), fractionFontSize, color, outline)
							drawText_(font, denominator, Vector2(x+(width-denomSize.x)/2, denomSize.y/2+4+fractionVerticalOffset), fractionFontSize, color, outline)
							x += width
						first = false
				if first:
					x += drawText_(font, "0", Vector2(x, 0), fontSize, color, outline).x
			TYPE.Spacing:
				x += text[1]

func drawText_(font:Font, string:String, pos:Vector2, fontSize:int, color:Color, outline:Color) -> Vector2:
	if outline.a: TextDraw.outlined2(font, drawMain, string, color, outline, fontSize, pos)
	else: font.draw_string(drawMain, pos, string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
	return font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize)

func getFont() -> Font:
	match setting:
		SETTING.FKEYNUM: return Game.FKEYNUM
		SETTING.FKEYBULK, _: return KeyBulk.FKEYBULK

func getFontSize() -> int:
	match setting:
		SETTING.FKEYNUM: return 22
		SETTING.FKEYBULK, _: return 14

func getFractionFontSize() -> int:
	match setting:
		SETTING.FKEYNUM: return 14
		SETTING.FKEYBULK, _: return 10

func getFractionLineVerticalPosition() -> int:
	match setting:
		SETTING.FKEYNUM: return 2
		SETTING.FKEYBULK, _: return -2

func getFractionVerticalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return 2
		SETTING.FKEYBULK, _: return 3

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
