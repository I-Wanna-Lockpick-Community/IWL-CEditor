class_name TextDrawer
extends Node2D

var drawMain:RID
var drawUpsideDown:RID
var setting:SETTING

enum SETTING {FKEYNUM, FKEYBULK, FTALK}
enum TYPE {String, Number, Image, Spacing, SetPosition}
enum TEXT_ALIGN {LEFT, RIGHT, CENTER}

var texts:Array[Array] = []
var textsChanged:bool = false
var textsIndex:int = 0
var drawPosition:Vector2

var mixedFractions:bool = false

func _init(parent:Node2D, _setting:SETTING) -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawUpsideDown = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain, get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawUpsideDown, get_canvas_item())
	RenderingServer.canvas_item_set_transform(drawUpsideDown,Transform2D(PI,Vector2.ZERO))
	setting = _setting
	parent.add_child(self)

func setmixedFractions(to:bool) -> void:
	if mixedFractions != to: textsChanged = true
	mixedFractions = to

func addString(string:String, color:Color, outline:Color=Color.TRANSPARENT) -> Array: return addValue_([TYPE.String, string, color, outline])
func addNumber(number:PackedInt64Array, color:Color, outline:Color=Color.TRANSPARENT) -> Array: return addValue_([TYPE.Number, number, color, outline])
func addImage(image:Texture2D, upsideDown:bool=false, color:Color=Color.WHITE, effectiveWidth:float=image.get_size().x, offset:Vector2=Vector2.ZERO) -> Array: return addValue_([TYPE.Image, image, upsideDown, color, effectiveWidth, offset])
func addSpacing(spacing:float) -> Array: return addValue_([TYPE.Spacing, spacing])
func addSetPosition(pos:Vector2, align:TEXT_ALIGN = TEXT_ALIGN.LEFT) -> Array: return addValue_([TYPE.SetPosition, pos, align])

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
	RenderingServer.canvas_item_clear(drawUpsideDown)
	var font:Font = getFont()
	var fontSize:int = getFontSize()
	var fractionFontSize:int = getFractionFontSize()
	var align:TEXT_ALIGN = TEXT_ALIGN.LEFT
	drawPosition = Vector2.ZERO
	for textIndex in len(texts):
		var text:Array = texts[textIndex]
		match text[0]:
			TYPE.String: # [TYPE.String, string, color, outline]
				drawPosition += drawText_(font, text[1], drawPosition, fontSize, text[2], text[3])
			TYPE.Number: # [TYPE.Number, number, color, outline]
				var fractionTextHorizontalOffset:float = getFractionTextHorizontalOffset()
				var fractionVerticalOffset:float = getFractionVerticalOffset()
				var fractionVerticalDistance:float = getFractionVerticalDistance()
				var color:Color = text[2]
				var outline:Color = text[3]
				if M.isError(text[1]):
					drawPosition += drawText_(font, "ERROR", drawPosition, fontSize, color, outline)
					continue
				var parts:Array[PackedInt64Array] = M.parts(text[1]).filter(func(x:PackedInt64Array) -> bool: return M.ex(x))
				if len(parts) == 0:
					drawPosition += drawText_(font, "0", drawPosition, fontSize, color, outline)
				else:
					for partIndex in len(parts):
						var part:PackedInt64Array = parts[partIndex]
						if M.hasNegative(part):
							drawPosition += drawText_(font, "-", drawPosition, fontSize, color, outline)
							part = M.negate(part)
						elif partIndex > 0:
							drawPosition += drawText_(font, "+", drawPosition, fontSize, color, outline)
						if M.isInteger(part) or (mixedFractions and M.ex(M.trunc(part))):
							drawPosition += drawText_(font, M.str(M.abs(M.trunc(part))), drawPosition, fontSize, color, outline)
							if !M.isInteger(part): drawPosition.x += 2
						if !M.isInteger(part):
							var fraction:PackedInt64Array = M.abs(M.remainder(part, M.ONE()) if mixedFractions else part)
							var numerator:String = M.str(M.numer(fraction))
							var denominator:String = M.str(M.denom(fraction))
							var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var width:float = max(numerSize.x, denomSize.x)
							var fractionLineRect:Rect2 = Rect2(drawPosition+Vector2(0,getFractionLineVerticalPosition()+fractionVerticalOffset), Vector2(width,2))
							if outline.a: RenderingServer.canvas_item_add_rect(drawMain, Rect2(fractionLineRect.position-Vector2.ONE,fractionLineRect.size+Vector2.ONE*2), outline)
							RenderingServer.canvas_item_add_rect(drawMain, fractionLineRect, color)
							drawText_(font, numerator, drawPosition+Vector2(fractionTextHorizontalOffset+(width-numerSize.x)/2, -numerSize.y/2-fractionVerticalDistance+fractionVerticalOffset), fractionFontSize, color, outline)
							drawText_(font, denominator, drawPosition+Vector2(fractionTextHorizontalOffset+(width-denomSize.x)/2, denomSize.y/2+fractionVerticalDistance+fractionVerticalOffset), fractionFontSize, color, outline)
							drawPosition.x += width+2
						if M.isImag(part): drawPosition += drawText_(font, "i", drawPosition, fontSize, color, outline)
			TYPE.Image: # [TYPE.Image, image, upsideDown, color, effectiveWidth, offset]
				var imageSize:Vector2 = text[1].get_size()
				var imageRect:Rect2 = Rect2(drawPosition+text[5]+round((Vector2(text[4],0)-imageSize)/2), imageSize)
				if text[2]: imageRect.position = -imageRect.position-imageSize
				RenderingServer.canvas_item_add_texture_rect(drawUpsideDown if text[2] else drawMain, imageRect, text[1], false, text[3])
				drawPosition.x += text[4]
			TYPE.Spacing: # [TYPE.Spacing, spacing]
				drawPosition.x += text[1]
			TYPE.SetPosition: # [TYPE.SetPosition, pos, align]
				align = text[2]
				drawPosition = text[1]
				if align != TEXT_ALIGN.LEFT:
					var index:int = textIndex+1
					var width:float = 0
					while index < len(texts) and texts[index][0] != TYPE.SetPosition:
						width += getWidth(texts[index])
						index += 1
					drawPosition.x -= round(width/2) if align == TEXT_ALIGN.CENTER else width

func debugCircle(pos:Vector2, color:Color) -> void:
	RenderingServer.canvas_item_add_circle(drawMain, pos, 2, color)

func getWidth(text:Array) -> float:
	var font:Font = getFont()
	var fontSize:int = getFontSize()
	var fractionFontSize:int = getFractionFontSize()
	match text[0]:
		TYPE.String: return font.get_string_size(text[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
		TYPE.Number:
			var width:float = 0
			if M.isError(text[1]):
				width += font.get_string_size("ERROR", HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
				return width
			var parts:Array[PackedInt64Array] = M.parts(text[1]).filter(func(x:PackedInt64Array) -> bool: return M.ex(x))
			if len(parts) == 0:
				width += font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
			else:
				for partIndex in len(parts):
					var part:PackedInt64Array = parts[partIndex]
					if M.hasNegative(part):
						width += font.get_string_size("-", HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
						part = M.negate(part)
					elif partIndex > 0:
						width += font.get_string_size("+", HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
					if M.isInteger(part) or (mixedFractions and M.ex(M.trunc(part))):
						width += font.get_string_size(M.str(M.trunc(part)), HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
						if !M.isInteger(part): drawPosition.x += 2
					if !M.isInteger(part):
						var fraction:PackedInt64Array = M.remainder(part, M.ONE()) if mixedFractions else part
						var numerator:String = M.str(M.numer(fraction))
						var denominator:String = M.str(M.denom(fraction))
						var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
						var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
						width += max(numerSize.x, denomSize.x) + 2
			return width
		TYPE.Image: return text[4]
		TYPE.Spacing: return text[1]
	assert(false)
	return 0

# returns offset
func drawText_(font:Font, string:String, pos:Vector2, fontSize:int, color:Color, outline:Color) -> Vector2:
	var width:float = font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
	if outline.a: TextDraw.outlined2(font, drawMain, string, color, outline, fontSize, pos)
	else: font.draw_string(drawMain, pos, string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
	return Vector2(width, 0)

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
		SETTING.FTALK, _: return 12

func getFractionLineVerticalPosition() -> int:
	match setting:
		SETTING.FKEYNUM: return 2
		SETTING.FKEYBULK: return -2
		SETTING.FTALK, _: return -8

func getFractionVerticalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return 2
		SETTING.FKEYBULK: return 3
		SETTING.FTALK, _: return 0

func getFractionVerticalDistance() -> float:
	match setting:
		SETTING.FKEYNUM: return 4
		SETTING.FKEYBULK: return 4
		SETTING.FTALK, _: return 1

func getFractionTextHorizontalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return 0
		SETTING.FKEYBULK: return 0
		SETTING.FTALK, _: return 1

func _notification(what:int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			RenderingServer.free_rid(drawMain)
			RenderingServer.free_rid(drawUpsideDown)

func addValue_(value:Array) -> Array:
	if textsIndex >= len(texts):
		texts.append(value)
		textsChanged = true
	elif texts[textsIndex] != value:
		texts[textsIndex] = value
		textsChanged = true
	textsIndex += 1
	return value
