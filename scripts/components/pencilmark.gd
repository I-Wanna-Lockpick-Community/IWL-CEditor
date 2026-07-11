class_name Pencilmark
extends GameNote
const SCENE:PackedScene = preload("res://scenes/objects/pencilmark.tscn")

const ORIGIN:Texture2D = preload("res://assets/game/pencilmark/origin.png")
const ORIGIN_FOCUSED:Texture2D = preload("res://assets/game/pencilmark/originFocused.png")
static var SYMBOL_TEXTURE:IndexTextureLoader = IndexTextureLoader.new("res://assets/game/pencilmark/symbols/.png", SYMBOLS)
const SYMBOL_SIZE:Vector2 = Vector2(24,24)

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

@export_group("SavedProperties")
@export var type:TYPE = TYPE.SYMBOL
@export var color:C.olors = C.olors.WHITE
@export var symbol:SYMBOL = SYMBOL.CHECK
@export var number:PackedInt64Array = M.ZERO()
@export var text:String = ""

var originOpacity:float = 0.75

var drawMain:RID

func _init() -> void: size = Vector2(18,18)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _process(delta:float) -> void:
	if Game.mouseMoveTimer < 2.0/3: originOpacity = min(originOpacity + delta*1.8, 0.75)
	else: originOpacity = max(originOpacity - delta*1.8, 0)
	queue_redraw()

func _freed() -> void:
	RenderingServer.free_rid(drawMain)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"number"))

func isHovered() -> bool: return Game.editor.objectHovered == self if Game.editor else false
func isFocused() -> bool: return Game.editor.focusDialog.focused == self if Game.editor else false

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(-getOffset(), size)
	var center:Vector2 = size/2-getOffset()
	RenderingServer.canvas_item_add_texture_rect(drawMain, rect, ORIGIN_FOCUSED if isHovered() or isFocused() else ORIGIN, false, Color(Color.WHITE, 0.75 if isFocused() else originOpacity))
	match type:
		TYPE.SYMBOL:
			for offset in [Vector2(0,-1), Vector2(0,1), Vector2(1,0), Vector2(-1,0)]:
				RenderingServer.canvas_item_add_texture_rect(drawMain, Rect2(center-SYMBOL_SIZE/2+offset, SYMBOL_SIZE), SYMBOL_TEXTURE.current([symbol]), false, Color.BLACK)
			RenderingServer.canvas_item_add_texture_rect(drawMain, Rect2(center-SYMBOL_SIZE/2, SYMBOL_SIZE), SYMBOL_TEXTURE.current([symbol]), false, Colors.getMainTone(color))
