extends QuicksetSetting
class_name ColorQuicksetSetting

var spacers:Array[Control]

const ICON:Texture2D = preload("res://assets/ui/settings/iconPlaceholder.png")

const DEFAULT_MATCHES:Array[String] = [
	"Q", "W", "E", "R", "T", "A", "S", "D", "F", "G", "Z", "X", "V", "B", "QW", "EQ", "QR", "DQ", "FQ", "EW", "RW", "AW", "ER", "ET"
]

static var matches:Array[String] = []

func _ready() -> void:
	columns = 8
	options = range(Game.COLORS)
	buttonType = ColorQuickSettingButton
	super()

func changedMods() -> void:
	var colors:Array[Game.COLOR] = Mods.colors()
	for button in buttons: button.visible = false
	for color in colors: buttons[color].visible = true
	for button in buttons: button.check()
	if len(colors) < 15: columns = 7
	else: columns = 8
	
	for spacer in spacers: spacer.queue_free()
	spacers.clear()
	@warning_ignore("integer_division")
	for i in (columns - 1 - (len(colors)-1) % columns)/2:
		var spacer:Control = Control.new()
		spacers.append(spacer)
		add_child(spacer)
		move_child(spacer,0)

class ColorQuickSettingButton extends QuicksetSettingButton:
	var drawMain:RID

	func _init(_value:Game.COLOR, _quicksetSetting:QuicksetSetting):
		custom_minimum_size = Vector2(72,24)
		super(_value, _quicksetSetting)
		icon = ICON
	
	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		if value == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_set_material(drawMain,Game.GLITCH_MATERIAL.get_rid())
		RenderingServer.canvas_item_set_z_index(drawMain,1)
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		await get_tree().process_frame
		if value in Game.ANIMATED_COLORS: Game.connect(&"goldIndexChanged",queue_redraw)
		await get_tree().process_frame
		queue_redraw()
		super()

	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(Vector2(2,2), Vector2(20,20))
		if value in Game.TEXTURED_COLORS: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,Game.COLOR_TEXTURES.current([value]))
		elif value == Game.COLOR.NONE: RenderingServer.canvas_item_add_texture_rect(drawMain,rect,ColorSelector.NONE_COLOR)
		else: RenderingServer.canvas_item_add_rect(drawMain,rect,Game.mainTone[value])
