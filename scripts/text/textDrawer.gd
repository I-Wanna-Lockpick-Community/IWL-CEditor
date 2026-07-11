class_name TextDrawer
extends Node2D

var drawMain:RID
var drawUpsideDown:RID
var setting:SETTING

enum SETTING {FKEYNUM, FKEYBULK, FTALK, FMINIID}
enum TYPE {String, Number, Image, Custom, Spacing, VerticalContext, HorizontalContext, Newline}
enum VERTICAL_ALIGN {NONE, CENTER}
enum HORIZONTAL_ALIGN {LEFT, RIGHT, CENTER}
enum OUTLINE_TYPE {THIN, MEDIUM, THICK}

const VERTICAL_CONTEXT_SETTERS:Array[TYPE] = [TYPE.VerticalContext]
const HORIZONTAL_CONTEXT_SETTERS:Array[TYPE] = [TYPE.VerticalContext, TYPE.HorizontalContext, TYPE.Newline]

var texts:Array[Array] = []
var textsChanged:bool = false
var textsIndex:int = 0

var mixedFractions:bool = false
var outlineType:OUTLINE_TYPE = OUTLINE_TYPE.THICK
var dropShadowOffset:Vector2 = Vector2.ZERO
var dropShadowColor:Color = Color.TRANSPARENT

const DEBUG:bool = false

func _init(parent:Node2D, _setting:SETTING) -> void:
	drawMain = RenderingServer.canvas_item_create()
	drawUpsideDown = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain, get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawUpsideDown, get_canvas_item())
	RenderingServer.canvas_item_set_transform(drawUpsideDown,Transform2D(PI,Vector2.ZERO))
	setting = _setting
	parent.add_child(self)

func setMixedFractions(to:bool) -> void:
	if mixedFractions != to: textsChanged = true
	mixedFractions = to

func setOutlineType(to:OUTLINE_TYPE) -> void:
	if outlineType != to: textsChanged = true
	outlineType = to

func setNoDropShadow() -> void:
	if dropShadowColor != Color.TRANSPARENT: textsChanged = true
	dropShadowColor = Color.TRANSPARENT

func setDropShadow(offset:Vector2, color:Color) -> void:
	if dropShadowOffset != offset: textsChanged = true
	if dropShadowColor != color: textsChanged = true
	dropShadowOffset = offset
	dropShadowColor = color

func addString(string:String, color:Color, outline:Color=Color.TRANSPARENT) -> void: addValue_([TYPE.String, string, color, outline])
func addNumber(number:PackedInt64Array, color:Color, outline:Color=Color.TRANSPARENT) -> void: addValue_([TYPE.Number, number, color, outline])
func addImage(image:Texture2D, upsideDown:bool=false, color:Color=Color.WHITE, effectiveSize:Vector2=image.get_size(), offset:Vector2=Vector2.ZERO) -> void: addValue_([TYPE.Image, image, upsideDown, color, effectiveSize, offset])
## ascent is the amount of pixels it extends above the baseline
## descent is the amount of pixels it extends below the baseline
## you should draw to the right, up to the width you specified
## these values are for centering stuff so if you have a more specific centering situation youre allowed to lie
## for proper caching, the function should be a definite function instead of a lambda.
## the function is called with (drawMain:RID, drawPosition:Vector2, params:Array)
func addCustom(function:Callable, params:Array, width:float, ascent:float=0, descent:float=0) -> void: addValue_([TYPE.Custom, function, params, width, Vector2(ascent,descent)])
func addSpacing(spacing:float) -> void: addValue_([TYPE.Spacing, spacing])
func addVerticalContext(pos:Vector2, align:VERTICAL_ALIGN = VERTICAL_ALIGN.NONE) -> void: addValue_([TYPE.VerticalContext, pos, align])
## horizontal contexts are contained within vertical contexts
func addHorizontalContext(offset:Vector2, align:HORIZONTAL_ALIGN = HORIZONTAL_ALIGN.LEFT) -> void: addValue_([TYPE.HorizontalContext, offset, align])
func addNewline(gap:float, align:HORIZONTAL_ALIGN = HORIZONTAL_ALIGN.LEFT) -> void: addValue_([TYPE.Newline, gap, align])

func getNumberWidth(number:PackedInt64Array) -> float: return getWidth([TYPE.Number, number])

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
	var textVerticalOffset:float = getTextVerticalOffset()
	var fractionTextVerticalOffset:float = getFractionTextVerticalOffset()
	var halfFontSize:int = round(fontSize/2.0)
	var vAlign:VERTICAL_ALIGN = VERTICAL_ALIGN.NONE
	var hAlign:HORIZONTAL_ALIGN = HORIZONTAL_ALIGN.LEFT
	var drawVStart:Vector2 = Vector2.ZERO
	var drawHStart:Vector2 = Vector2.ZERO
	var drawPosition:Vector2 = Vector2.ZERO

	# preprocessed context information, indexed by index of context start
	# all height ranges are expressed as Vector2(-position of top, position of bottom), relative to the anchor
	var contextHeightRanges:Dictionary[int, Vector2] = {}
	var contextWidths:Dictionary[int, float] = {}
	var hContextAnchors:Dictionary[int, Vector2] = {}
	var vContextSubcontextLists:Dictionary[int, Array] = {}
	
	var contextHeightRange:Vector2 = Vector2.ZERO
	var contextWidth:float = 0
	var vContextStart:int = -1
	var prevContextHeightRange:Vector2 = Vector2.ZERO
	var contextStart:int = -1
	var vContextSubcontextList:Array = []
	var hContextPos:Vector2 = Vector2.ZERO
	for textIndex in len(texts)+1: # extra dummy vertical context at end to finish tracking the last one 
		var text:Array = (texts[textIndex] if textIndex < len(texts) else [TYPE.VerticalContext])
		if text[0] in HORIZONTAL_CONTEXT_SETTERS:
			if contextStart != -1:
				contextHeightRanges[contextStart] = contextHeightRange
				contextWidths[contextStart] = contextWidth
				var context:Array = texts[contextStart]
				match context[0]:
					TYPE.VerticalContext:
						hContextPos = Vector2.ZERO
					TYPE.HorizontalContext:
						hContextPos = context[1]
					TYPE.Newline:
						hContextPos += Vector2(0,prevContextHeightRange.y+contextHeightRange.x+context[1])
				hContextAnchors[contextStart] = hContextPos
			if text[0] in VERTICAL_CONTEXT_SETTERS:
				if vContextStart != -1: vContextSubcontextLists[vContextStart] = vContextSubcontextList
				vContextStart = textIndex
				hContextPos = Vector2.ZERO
			else:
				vContextSubcontextList.append(textIndex)
			contextStart = textIndex
			prevContextHeightRange = contextHeightRange
			contextHeightRange = Vector2.ZERO
			contextWidth = 0
		else:
			contextHeightRange = contextHeightRange.max(getHeightRange(text))
			contextWidth += getWidth(text)

	for textIndex in len(texts):
		var text:Array = texts[textIndex]
		match text[0]:
			TYPE.String: # [TYPE.String, string, color, outline]
				drawPosition += drawText_(font, text[1], drawPosition, fontSize, textVerticalOffset, text[2], text[3])
			TYPE.Number: # [TYPE.Number, number, color, outline]
				var fractionTextHorizontalOffset:float = getFractionTextHorizontalOffset()
				var fractionVerticalOffset:float = getFractionVerticalOffset()
				var fractionVerticalDistance:float = getFractionVerticalDistance()
				var color:Color = text[2]
				var outline:Color = text[3]
				if M.isError(text[1]):
					drawPosition += drawText_(font, "ERROR", drawPosition, fontSize, textVerticalOffset, color, outline)
					continue
				var parts:Array[PackedInt64Array] = M.parts(text[1]).filter(func(x:PackedInt64Array) -> bool: return M.ex(x))
				if len(parts) == 0:
					drawPosition += drawText_(font, "0", drawPosition, fontSize, textVerticalOffset, color, outline)
				else:
					for partIndex in len(parts):
						var part:PackedInt64Array = parts[partIndex]
						if M.hasNegative(part):
							drawPosition += drawText_(font, "-", drawPosition, fontSize, textVerticalOffset, color, outline)
							part = M.negate(part)
						elif partIndex > 0:
							drawPosition += drawText_(font, "+", drawPosition, fontSize, textVerticalOffset, color, outline)
						if M.isInteger(part) or (mixedFractions and M.ex(M.trunc(part))):
							drawPosition += drawText_(font, M.str(M.abs(M.trunc(part))), drawPosition, fontSize, textVerticalOffset, color, outline)
							if !M.isInteger(part): drawPosition.x += 2
						if !M.isInteger(part):
							var fraction:PackedInt64Array = M.abs(M.remainder(part, M.ONE()) if mixedFractions else part)
							var numerator:String = M.str(M.numer(fraction))
							var denominator:String = M.str(M.denom(fraction))
							var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
							var width:float = max(numerSize.x, denomSize.x)
							var fractionLineRect:Rect2 = Rect2(drawPosition+Vector2(0,-1-halfFontSize+fractionVerticalOffset), Vector2(width,2))
							if outline.a: RenderingServer.canvas_item_add_rect(drawMain, Rect2(fractionLineRect.position-Vector2.ONE,fractionLineRect.size+Vector2.ONE*2), outline)
							RenderingServer.canvas_item_add_rect(drawMain, fractionLineRect, color)
							debugCircle(drawPosition+Vector2(0,-halfFontSize+fractionVerticalOffset), Color.BLACK)
							drawText_(font, numerator, drawPosition+Vector2(fractionTextHorizontalOffset+(width-numerSize.x)/2, -halfFontSize-fractionVerticalDistance+fractionVerticalOffset), fractionFontSize, fractionTextVerticalOffset, color, outline)
							drawText_(font, denominator, drawPosition+Vector2(fractionTextHorizontalOffset+(width-denomSize.x)/2, -halfFontSize+fractionFontSize+fractionVerticalDistance+fractionVerticalOffset), fractionFontSize, fractionTextVerticalOffset, color, outline)
							drawPosition.x += width+2
						if M.isImag(part): drawPosition += drawText_(font, "i", drawPosition, fontSize, textVerticalOffset, color, outline)
			TYPE.Image: # [TYPE.Image, image, upsideDown, color, effectiveSize, offset]
				var imageSize:Vector2 = text[1].get_size()
				var imageRect:Rect2 = Rect2(drawPosition+text[5]+round((Vector2(text[4].x,-text[4].y)-imageSize)/2), imageSize)
				if text[2]: imageRect.position = -imageRect.position-imageSize
				RenderingServer.canvas_item_add_texture_rect(drawUpsideDown if text[2] else drawMain, imageRect, text[1], false, text[3])
				drawPosition.x += text[4].x
			TYPE.Custom: # [TYPE.Custom, function, params, width, heightRange]
				text[1].call(drawMain, drawPosition, text[2])
				drawPosition.x += text[3]
			TYPE.Spacing: # [TYPE.Spacing, spacing]
				drawPosition.x += text[1]
			TYPE.VerticalContext: # [TYPE.VerticalContext, pos, align]
				vAlign = text[2]
				hAlign = HORIZONTAL_ALIGN.LEFT
				drawVStart = text[1]
				debugCircle(drawVStart, Color.RED)
				if vAlign != VERTICAL_ALIGN.NONE:
					var heightRange:Vector2 = Vector2.ZERO
					for contextIndex in vContextSubcontextLists[textIndex]:
						var offset:float = hContextAnchors[contextIndex].y
						heightRange = heightRange.max(contextHeightRanges[contextIndex]+Vector2(-offset, offset))
					match vAlign:
						VERTICAL_ALIGN.CENTER: drawVStart.y -= round((heightRange.y-heightRange.x)/2)
			TYPE.HorizontalContext: # [TYPE.HorizontalContext, offset, align]
				hAlign = text[2]
			TYPE.Newline: # [TYPE.Newline, gap, align]
				hAlign = text[2]
		if text[0] in HORIZONTAL_CONTEXT_SETTERS:
			drawHStart = hContextAnchors[textIndex]
			if hAlign != HORIZONTAL_ALIGN.LEFT: drawHStart.x += getHorizontalAlignOffset(hAlign, contextWidths[textIndex])
			drawPosition = drawVStart + drawHStart
			var hrange:Vector2 = contextHeightRanges[textIndex]
			if text[0] not in VERTICAL_CONTEXT_SETTERS:
				debugCircle(drawPosition-Vector2(0,hrange.x), Color.GREEN)
				debugCircle(drawPosition+Vector2(0,hrange.y), Color.BLUE)
				debugCircle(drawPosition, Color.AQUA)

func getHorizontalAlignOffset(align:HORIZONTAL_ALIGN, width:float) -> float:
	match align:
		HORIZONTAL_ALIGN.CENTER: return -round(width/2)
		HORIZONTAL_ALIGN.RIGHT: return -width
	assert(false)
	return 0

func debugCircle(pos:Vector2, color:Color) -> void:
	if DEBUG: RenderingServer.canvas_item_add_circle(drawMain, pos, 2, color)

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
						if !M.isInteger(part): width += 2
					if !M.isInteger(part):
						var fraction:PackedInt64Array = M.remainder(part, M.ONE()) if mixedFractions else part
						var numerator:String = M.str(M.numer(fraction))
						var denominator:String = M.str(M.denom(fraction))
						var numerSize:Vector2 = font.get_string_size(numerator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
						var denomSize:Vector2 = font.get_string_size(denominator, HORIZONTAL_ALIGNMENT_LEFT, -1, fractionFontSize)
						width += max(numerSize.x, denomSize.x) + 2
			return width
		TYPE.Image: return text[4].x
		TYPE.Custom: return text[3]
		TYPE.Spacing: return text[1]
	assert(false)
	return 0

func getHeightRange(text:Array) -> Vector2:
	var fontSize:int = getFontSize()
	var fractionFontSize:int = getFractionFontSize()
	var halfFontSize:int = round(fontSize/2.0)
	match text[0]:
		TYPE.String: return Vector2(fontSize, 0)
		TYPE.Number:
			var result:Vector2 = Vector2(fontSize, 0)
			if !M.isInteger(text[1]):
				var fractionHeight:float = fractionFontSize+getFractionVerticalDistance()
				result = result.max(Vector2(fractionHeight+halfFontSize, fractionHeight-halfFontSize))
			return result
		TYPE.Image: return Vector2(text[4].y-text[5].y, text[5].y)
		TYPE.Custom: return text[4]
		TYPE.Spacing: return Vector2.ZERO
	assert(false)
	return Vector2.ZERO

# returns offset
func drawText_(font:Font, string:String, pos:Vector2, fontSize:int, verticalOffset:float, color:Color, outline:Color) -> Vector2:
	debugCircle(pos, Color.ORANGE)
	pos.y += verticalOffset
	var width:float = font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
	if dropShadowColor.a:
		font.draw_string(drawMain, pos+dropShadowOffset, string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, dropShadowColor)
	if outline.a:
		match outlineType:
			OUTLINE_TYPE.THICK: TextDraw.outlined2(font, drawMain, string, color, outline, fontSize, pos)
			OUTLINE_TYPE.MEDIUM: TextDraw.outlined(font, drawMain, string, color, outline, fontSize, pos)
			OUTLINE_TYPE.THIN: TextDraw.outlinedHalf(font, drawMain, string, color, outline, fontSize, pos)
	else: font.draw_string(drawMain, pos, string, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, color)
	return Vector2(width, 0)

func getFont() -> Font:
	match setting:
		SETTING.FKEYNUM: return Game.FKEYNUM
		SETTING.FKEYBULK: return KeyBulk.FKEYBULK
		SETTING.FTALK: return Game.FTALK
		SETTING.FMINIID, _: return Game.FMINIID

func getFontSize() -> int:
	match setting:
		SETTING.FKEYNUM: return 22
		SETTING.FKEYBULK: return 14
		SETTING.FTALK: return 12
		SETTING.FMINIID, _: return 12

func getFractionFontSize() -> int:
	match setting:
		SETTING.FKEYNUM: return 14
		SETTING.FKEYBULK: return 10
		SETTING.FTALK: return 12
		SETTING.FMINIID, _: return 12

func getTextVerticalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return -15
		SETTING.FKEYBULK: return -5
		SETTING.FTALK: return 1
		SETTING.FMINIID, _: return 1

func getFractionTextVerticalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return -10
		SETTING.FKEYBULK: return -4
		SETTING.FTALK: return 1
		SETTING.FMINIID, _: return 1

func getFractionVerticalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return 0
		SETTING.FKEYBULK: return 3
		SETTING.FTALK: return 0
		SETTING.FMINIID, _: return 0

func getFractionVerticalDistance() -> float:
	match setting:
		SETTING.FKEYNUM: return 4
		SETTING.FKEYBULK: return 4
		SETTING.FTALK: return 3
		SETTING.FMINIID, _: return 3

func getFractionTextHorizontalOffset() -> float:
	match setting:
		SETTING.FKEYNUM: return 0
		SETTING.FKEYBULK: return 0
		SETTING.FTALK: return 1
		SETTING.FMINIID, _: return 1

func _notification(what:int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			RenderingServer.free_rid(drawMain)
			RenderingServer.free_rid(drawUpsideDown)

func addValue_(value:Array) -> void:
	if textsIndex >= len(texts):
		texts.append(value)
		textsChanged = true
	elif texts[textsIndex] != value:
		texts[textsIndex] = value
		textsChanged = true
	textsIndex += 1
