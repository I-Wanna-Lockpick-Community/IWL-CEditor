class_name TextDrawer
extends Node2D

var drawMain:RID
var setting:SETTING

enum SETTING {FKEYNUM, FKEYBULK, FTALK}
enum TYPE {String, Number, Image, Spacing, SetPosition}

var texts:Array[Array] = []
var textsChanged:bool = false
var textsIndex:int = 0
var drawPosition:Vector2

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
func addImage(image:Texture2D, color:Color, offset:Vector2=Vector2.ZERO, width:float=image.get_size().x) -> void: addValue_([TYPE.Image, image, color, offset, width])
func addSpacing(spacing:float) -> void: addValue_([TYPE.Spacing, spacing])
func addSetPosition(pos:Vector2, rightToLeft:bool = false) -> void: addValue_([TYPE.SetPosition, pos, rightToLeft])

func evaluate() -> void:
	if textsIndex < len(texts):
		textsChanged = true
		texts = texts.slice(0, textsIndex)
	textsIndex = 0
	if !textsChanged: return
	textsChanged = false
	drawTexts()

func _draw() -> void:
	drawTexts()

func drawTexts() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var font:Font = getFont()
	var fontSize:int = getFontSize()
	var fractionFontSize:int = getFractionFontSize()
	var rtl:bool = false
	drawPosition = Vector2.ZERO
	for text in texts:
		match text[0]:
			TYPE.String:
				drawPosition += drawText_(font, text[1], drawPosition, fontSize, text[2], text[3], rtl)
			TYPE.Number:
				var fractionVerticalOffset:float = getFractionVerticalOffset()
				var color:Color = text[2]
				var outline:Color = text[3]
				if M.isError(text[1]):
					drawPosition += drawText_(font, "ERROR", drawPosition, fontSize, color, outline, rtl)
					continue
				var parts:Array[PackedInt64Array] = M.parts(text[1]).filter(func(x:PackedInt64Array) -> bool: return M.ex(x))
				if rtl: parts.reverse()
				if len(parts) == 0:
					drawPosition += drawText_(font, "0", drawPosition, fontSize, color, outline, rtl)
				else:
					for partIndex in len(parts):
						var part:PackedInt64Array = parts[partIndex]
						if !rtl:
							if M.hasNegative(part):
								drawPosition += drawText_(font, "-", drawPosition, fontSize, color, outline, rtl)
								part = M.negate(part)
							elif partIndex > 0:
								drawPosition += drawText_(font, "+", drawPosition, fontSize, color, outline, rtl)
						if M.isInteger(part) or (mixedFractionsMode and M.ex(M.trunc(part))):
							drawPosition += drawText_(font, M.str(M.trunc(part)), drawPosition, fontSize, color, outline, rtl)
							if !M.isInteger(part): drawPosition.x += 2
						if !M.isInteger(part):
							var fraction:PackedInt64Array = M.remainder(part, M.ONE()) if mixedFractionsMode else part
							var numerator:String = M.str(M.numer(fraction))
							var denominator:String = M.str(M.denom(fraction))
							var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var width:float = max(numerSize.x, denomSize.x)
							var fractionLineRect:Rect2 = Rect2(drawPosition+Vector2(0,getFractionLineVerticalPosition()+fractionVerticalOffset), Vector2(width,2))
							if rtl: fractionLineRect.position.x -= width
							if outline.a: RenderingServer.canvas_item_add_rect(drawMain, Rect2(fractionLineRect.position-Vector2.ONE,fractionLineRect.size+Vector2.ONE*2), outline)
							RenderingServer.canvas_item_add_rect(drawMain, fractionLineRect, color)
							var direction:float = -1 if rtl else 1
							drawText_(font, numerator, drawPosition+Vector2((width-numerSize.x)*direction/2, -numerSize.y/2-4+fractionVerticalOffset), fractionFontSize, color, outline, rtl)
							drawText_(font, denominator, drawPosition+Vector2((width-denomSize.x)*direction/2, denomSize.y/2+4+fractionVerticalOffset), fractionFontSize, color, outline, rtl)
							if rtl: drawPosition.x -= width
							else: drawPosition.x += width
						if rtl:
							if M.hasNegative(part):
								drawPosition += drawText_(font, "-", drawPosition, fontSize, color, outline, rtl)
								part = M.negate(part)
							elif partIndex < len(parts)-1:
								drawPosition += drawText_(font, "+", drawPosition, fontSize, color, outline, rtl)
			TYPE.Image:
				RenderingServer.canvas_item_add_texture_rect(drawMain, Rect2(drawPosition+text[3], text[1].get_size()), text[1], false, text[2])
				drawPosition.x += text[4]
			TYPE.Spacing:
				if rtl: drawPosition.x -= text[1]
				else: drawPosition.x += text[1]
			TYPE.SetPosition:
				drawPosition = text[1]
				rtl = text[2]

# returns offset
func drawText_(font:Font, string:String, pos:Vector2, fontSize:int, color:Color, outline:Color, rtl:bool) -> Vector2:
	var width:float = font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
	if rtl: pos.x -= width
	if outline.a: TextDraw.outlined2(font, drawMain, string, color, outline, fontSize, pos)
	else: font.draw_string(drawMain, pos, string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
	return Vector2(-width if rtl else width, 0)

func getFont() -> Font:
	match setting:
		SETTING.FKEYNUM: return Game.FKEYNUM
		SETTING.FKEYBULK: return KeyBulk.FKEYBULK
		SETTING.FTALK, _: return Game.FTALK

func getFontSize() -> int:
	match setting:
		SETTING.FKEYNUM: return 22
		SETTING.FKEYBULK: return 14
		SETTING.FTALK, _: return 12

func getFractionFontSize() -> int:
	match setting:
		SETTING.FKEYNUM: return 14
		SETTING.FKEYBULK: return 10
		SETTING.FTALK, _: return 8

func getFractionLineVerticalPosition() -> int:
	match setting:
		SETTING.FKEYNUM: return 2
		SETTING.FKEYBULK: return -2
		SETTING.FTALK, _: return -2

func getFractionVerticalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return 2
		SETTING.FKEYBULK: return 3
		SETTING.FTALK, _: return 3

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
