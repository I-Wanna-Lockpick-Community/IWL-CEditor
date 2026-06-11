extends GameObject
class_name PlayerSpawn
const SCENE:PackedScene = preload("res://scenes/objects/playerSpawn.tscn")

const SEARCH_ICON:Texture2D = LEVELSTART_ICON
const SEARCH_NAME:String = "Player Spawn"
const SEARCH_KEYWORDS:Array[String] = ["objPlayerStart", "start", "lily", "kid"]

func outlineTex() -> Texture2D:
	if Game.levelStart == self: return LEVELSTART_ICON
	return SAVESTATE_ICON

const LEVELSTART_ICON:Texture2D = preload("res://assets/game/playerSpawn/levelStart.png")
const SAVESTATE_ICON:Texture2D = preload("res://assets/game/playerSpawn/savestate.png")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"undoStack", # undostack is a "property" and not an "array" because we wont ever interact with the elements; its basically just a selfcontained piece of Data
	&"saveBuffered"
]
static var ARRAYS:Dictionary[StringName,Variant] = {
	&"key":TYPE_PACKED_INT64_ARRAY,
	&"star":TYPE_BOOL,
	&"curse":TYPE_BOOL,
	&"glisten":TYPE_PACKED_INT64_ARRAY
}

var key:Array[PackedInt64Array] = []
var star:Array[bool]
var curse:Array[bool]
var glisten:Array[PackedInt64Array] = []
var undoStack:Array[RefCounted] = []
var saveBuffered:bool = false

var drawMain:RID

func _init() -> void:
	size = Vector2(32,32)
	for color in Colors.COLORS:
		# if color == C.olors.STONE:
		key.append(M.ZERO)
		star.append(false)
		curse.append(color == C.olors.BROWN)
		glisten.append(M.ZERO)

func resetColors() -> void:
	for color in Colors.COLORS:
		resetColor(color)

func resetColor(color:C.olors) -> void:
	Changes.addChange(Changes.ArrayElementChange.new(self,&"key",color,M.ZERO))
	Changes.addChange(Changes.ArrayElementChange.new(self,&"star",color,false))
	Changes.addChange(Changes.ArrayElementChange.new(self,&"curse",color,false))
	Changes.addChange(Changes.ArrayElementChange.new(self,&"glisten",color,M.ZERO))

var forceDrawStart:bool = false

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _freed() -> void:
	RenderingServer.free_rid(drawMain)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberArrayChange.new(self, from, &"key"))

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	if Game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	if forceDrawStart or Game.levelStart == self: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,SEARCH_ICON)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,SAVESTATE_ICON)
