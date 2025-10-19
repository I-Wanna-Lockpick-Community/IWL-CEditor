extends GameObject
class_name Goal
const SCENE:PackedScene = preload("res://scenes/objects/goal.tscn")

const SEARCH_ICON:Texture2D = preload("res://assets/game/otherObjects/goal.png")
const SEARCH_NAME:String = "Goal"
const SEARCH_KEYWORDS:Array[String] = ["end", "win"]

static func outlineTex() -> Texture2D: return preload("res://assets/game/otherObjects/goalOutlineMask.png")

var drawMain:RID
func _init() -> void : size = Vector2(32,32)

func _ready() -> void:
	drawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	RenderingServer.canvas_item_add_texture_rect(drawMain,rect,SEARCH_ICON)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const EDITOR_PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
]
