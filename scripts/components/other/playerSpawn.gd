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

@export_group("SavedArrays")
@export var key:Array[PackedInt64Array] = []
@export var star:Array[bool]
@export var curse:Array[bool]
@export var glisten:Array[PackedInt64Array] = []
@export_group("SavedProperties")
@export var undoStack:Array[Array] = []
@export var saveBuffered:bool = false

var drawMain:RID

func _init() -> void:
	size = Vector2(32,32)
	for color in Colors.COLORS:
		# if color == C.olors.STONE:
		key.append(M.ZERO())
		star.append(false)
		curse.append(color == C.olors.BROWN)
		glisten.append(M.ZERO())

func resetColors() -> void:
	for color in Colors.COLORS:
		resetColor(color)

func resetColor(color:C.olors) -> void:
	Changes.addChange(Changes.ArrayElementChange.new(self,&"key",color,M.ZERO()))
	Changes.addChange(Changes.ArrayElementChange.new(self,&"star",color,false))
	Changes.addChange(Changes.ArrayElementChange.new(self,&"curse",color,false))
	Changes.addChange(Changes.ArrayElementChange.new(self,&"glisten",color,M.ZERO()))

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
