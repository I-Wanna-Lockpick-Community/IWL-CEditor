class_name PencilmarkColorSelector
extends Selector

func _ready() -> void:
	columns = 9
	options = range(Pencilmark.COLORS)
	defaultValue = Pencilmark.COLOR.WHITE
	buttonType = PencilmarkColorSelectorButton
	super()
	for button in buttons:
		Explainer.addControl(button,QuicksetExplanation.new("[%s+$q]Set "+Pencilmark.COLOR_NAMES[button.value].to_lower()+" color", [&"quicksetPencilmarkColor"], PencilmarkColorQuicksetSetting.matches, button.value))

class PencilmarkColorSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:Pencilmark.COLOR, _selector:PencilmarkColorSelector):
		custom_minimum_size = Vector2(20,20)
		z_index = 1
		super(_value, _selector)

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())

	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		RenderingServer.canvas_item_add_rect(drawMain,rect,Pencilmark.getColor(value))
