extends GameObject
class_name PlayerSpawn
const SCENE:PackedScene = preload("res://scenes/objects/playerSpawn.tscn")

const SEARCH_ICON:Texture2D = LEVELSTART_ICON
const SEARCH_NAME:String = "Player Spawn"
const SEARCH_KEYWORDS:Array[String] = ["start", "lily", "kid"]

func outlineTex() -> Texture2D:
	if editor.game.levelStart == self: return LEVELSTART_ICON
	return SAVESTATE_ICON

const LEVELSTART_ICON:Texture2D = preload("res://assets/game/otherObjects/playerSpawn.png")
const SAVESTATE_ICON:Texture2D = preload("res://assets/game/otherObjects/playerSpawnSavestate.png")

var drawMain:RID
func _init() -> void : size = Vector2(32,32)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	if editor.game.levelStart == self: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,SEARCH_ICON)
	else: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,SAVESTATE_ICON)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
]
