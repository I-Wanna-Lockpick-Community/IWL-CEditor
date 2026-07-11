extends QuicksetSetting
class_name PencilmarkColorQuicksetSetting

const ICON:Texture2D = preload("res://assets/ui/settings/iconPlaceholder.png")

const OPTIONS:Array[Pencilmark.COLOR] = [
	Pencilmark.COLOR.C_WHITE, Pencilmark.COLOR.C_ORANGE, Pencilmark.COLOR.C_PURPLE, Pencilmark.COLOR.C_PINK, Pencilmark.COLOR.C_CYAN, Pencilmark.COLOR.C_BLACK, Pencilmark.COLOR.C_RED, Pencilmark.COLOR.C_GREEN, Pencilmark.COLOR.C_BLUE,
	Pencilmark.COLOR.C_BROWN, Pencilmark.COLOR.RED, Pencilmark.COLOR.GREEN, Pencilmark.COLOR.BLUE, Pencilmark.COLOR.CYAN, Pencilmark.COLOR.MAGENTA, Pencilmark.COLOR.YELLOW, Pencilmark.COLOR.WHITE, Pencilmark.COLOR.BLACK
]

const DEFAULT_MATCHES:Array[String] = [
	"1", "2", "3", "4", "Q", "W", "E", "R", "T",
	"A", "S", "D", "F", "G", "Z", "X", "V", "B",
]

static var matches:Array[String] = []

func _ready() -> void:
	columns = 9
	options = OPTIONS
	buttonType = PencilmarkColorQuickSettingButton
	super()

class PencilmarkColorQuickSettingButton extends QuicksetSettingButton:
	var drawMain:RID
	
	func _init(_value:C.olors, _quicksetSetting:QuicksetSetting):
		custom_minimum_size = Vector2(72,24)
		super(_value, _quicksetSetting)
		icon = ICON

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_z_index(drawMain,1)
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		super()
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(Vector2(2,2), Vector2(20,20))
		RenderingServer.canvas_item_add_rect(drawMain,rect,Pencilmark.getColor(value))
