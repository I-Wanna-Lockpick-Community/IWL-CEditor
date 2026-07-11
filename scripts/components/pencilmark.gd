class_name Pencilmark
extends GameNote
const SCENE:PackedScene = preload("res://scenes/objects/pencilmark.tscn")

const ORIGIN:Texture2D = preload("res://assets/game/pencilmark/origin.png")
const ORIGIN_FOCUSED:Texture2D = preload("res://assets/game/pencilmark/originFocused.png")
static var SYMBOL_TEXTURE:IndexTextureLoader = IndexTextureLoader.new("res://assets/game/pencilmark/symbols/.png", SYMBOLS)
const SYMBOL_SIZE:Vector2 = Vector2(24,24)
const STAR:Texture2D = preload("res://assets/game/keyCounter/star.png")

func outlineTex() -> Texture2D:
	return Game.EMPTY if isHovered() or isFocused() else preload("res://assets/game/pencilmark/outlineMask.png")

func getOffset() -> Vector2: return Vector2(-7,-7)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]

enum TYPE {SYMBOL, NUMBER, TEXT}
const TYPES:int = 3
enum SYMBOL {CHECK, CROSS, CIRCLE, SQUARE, BANG, INTERRO}
const SYMBOLS:int = 6
enum COLOR {C_WHITE, C_ORANGE, C_PURPLE, C_PINK, C_CYAN, C_BLACK, C_RED, C_GREEN, C_BLUE, C_BROWN, RED, GREEN, BLUE, CYAN, MAGENTA, YELLOW, WHITE, BLACK}
const COLOR_NAMES = ["Matched white", "Matched orange", "Matched purple", "Matched pink", "Matched cyan", "Matched black", "Matched red", "Matched green", "Matched blue", "Matched brown", "Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "White", "Black"]
const COLORS:int = 18

@export_group("SavedProperties")
@export var type:TYPE = TYPE.SYMBOL
@export var color:COLOR = COLOR.WHITE
@export var symbol:SYMBOL = SYMBOL.CHECK
@export var number:PackedInt64Array = M.ZERO()
@export var text:String = ""

var originOpacity:float = 0.75

var drawStar:RID
var drawMain:RID
var textDrawer:TextDrawer

func _init() -> void:
	size = Vector2(18,18)

func _ready() -> void:
	active = Game.editor or !fromEditor
	drawStar = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawStar,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	textDrawer = TextDrawer.new(self, TextDrawer.SETTING.FMINIID)
	textDrawer.position = size/2-getOffset()

func start() -> void:
	active = Game.editor or !fromEditor

func _process(delta:float) -> void:
	if Game.mouseMoveTimer < 2.0/3: originOpacity = min(originOpacity + delta*1.8, 0.75) # 1/25*3/4 per frame, 60fps
	else: originOpacity = max(originOpacity - delta*1.8, 0)
	queue_redraw()

func _freed() -> void:
	RenderingServer.free_rid(drawStar)
	RenderingServer.free_rid(drawMain)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"number"))

func isHovered() -> bool: return (Game.editor.objectHovered if Game.editor else Game.playGame.hoveredNote) == self
func isFocused() -> bool: return (Game.editor.focusDialog.focused if Game.editor else Game.playGame.playGameDialog.focused) == self

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawStar)
	RenderingServer.canvas_item_clear(drawMain)
	if !active and !Game.editor:
		textDrawer.evaluate()
		return
	var rect:Rect2 = Rect2(-getOffset(), size)
	var center:Vector2 = size/2-getOffset()
	var drawColor:Color = getColor(color)
	RenderingServer.canvas_item_set_transform(drawStar,Transform2D(Game.pencilmarkStarAngle,center))
	if type != TYPE.TEXT:
		RenderingServer.canvas_item_add_texture_rect(drawStar,Rect2(Vector2(-25.6,-25.6),Vector2(51.2,51.2)),STAR,false,Color(drawColor,0.75))
	RenderingServer.canvas_item_add_texture_rect(drawMain, rect, ORIGIN_FOCUSED if isHovered() or isFocused() else ORIGIN, false, Color(Color.WHITE, 0.75 if isFocused() else originOpacity))
	textDrawer.setOutlineType(TextDrawer.OUTLINE_TYPE.THIN)
	textDrawer.addVerticalContext(Vector2(0,1), TextDrawer.VERTICAL_ALIGN.CENTER)
	textDrawer.addHorizontalContext(Vector2.ZERO, TextDrawer.HORIZONTAL_ALIGN.CENTER)
	textDrawer.addSpacing(2)
	match type:
		TYPE.SYMBOL:
			for offset in [Vector2(0,-1), Vector2(0,1), Vector2(1,0), Vector2(-1,0)]:
				RenderingServer.canvas_item_add_texture_rect(drawMain, Rect2(center-SYMBOL_SIZE/2+offset, SYMBOL_SIZE), SYMBOL_TEXTURE.current([symbol]), false, Color.BLACK)
			RenderingServer.canvas_item_add_texture_rect(drawMain, Rect2(center-SYMBOL_SIZE/2, SYMBOL_SIZE), SYMBOL_TEXTURE.current([symbol]), false, drawColor)
		TYPE.NUMBER:
			textDrawer.setNoDropShadow()
			textDrawer.addNumber(number, drawColor, Color.BLACK)
		TYPE.TEXT:
			textDrawer.setDropShadow(Vector2(2,2), Color(Color.BLACK, 0.35))
			var lines:PackedStringArray = text.split("\n")
			for line in len(lines):
				textDrawer.addString(lines[line], drawColor, Color.BLACK)
				if line != len(lines)-1: textDrawer.addNewline(4, TextDrawer.HORIZONTAL_ALIGN.CENTER)
	textDrawer.evaluate()

func propertyChangedInit(property:StringName) -> void:
	if property == &"type":
		if type != TYPE.SYMBOL and symbol != SYMBOL.CHECK: Changes.addChange(Changes.PropertyChange.new(self,&"symbol",SYMBOL.CHECK))
		if type != TYPE.NUMBER and M.ex(number): Changes.addChange(Changes.PropertyChange.new(self,&"number",M.ZERO()))
		if type != TYPE.TEXT and text: Changes.addChange(Changes.PropertyChange.new(self,&"text",""))

static func getColor(c:COLOR) -> Color:
	match c:
		COLOR.C_WHITE: 	return Colors.getMainTone(C.olors.WHITE)
		COLOR.C_ORANGE: return Colors.getMainTone(C.olors.ORANGE)
		COLOR.C_PURPLE: return Colors.getMainTone(C.olors.PURPLE)
		COLOR.C_PINK: 	return Colors.getMainTone(C.olors.PINK)
		COLOR.C_CYAN: 	return Colors.getMainTone(C.olors.CYAN)
		COLOR.C_BLACK: 	return Colors.getMainTone(C.olors.BLACK)
		COLOR.C_RED: 	return Colors.getMainTone(C.olors.RED)
		COLOR.C_GREEN: 	return Colors.getMainTone(C.olors.GREEN)
		COLOR.C_BLUE: 	return Colors.getMainTone(C.olors.BLUE)
		COLOR.C_BROWN: 	return Colors.getMainTone(C.olors.BROWN)
		COLOR.RED: 		return Color.RED
		COLOR.GREEN: 	return Color.GREEN
		COLOR.BLUE: 	return Color.BLUE
		COLOR.CYAN: 	return Color.CYAN
		COLOR.MAGENTA: 	return Color.MAGENTA
		COLOR.YELLOW: 	return Color.YELLOW
		COLOR.WHITE: 	return Color.WHITE
		COLOR.BLACK: 	return Color.BLACK
	assert(false)
	return Color.WHITE
