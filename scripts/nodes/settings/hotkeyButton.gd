extends Button
class_name HotkeyButton

@export var defaultHotkey:StringName
@export var pressedHotkey:StringName
@export var hotkeyParent:Control
var hotkeyOpacity:float = 1.0

var drawHotkey:RID

func _pressed() -> void:
	Game.editor.grab_focus()

func _ready() -> void:
	if !hotkeyParent: hotkeyParent = self
	drawHotkey = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawHotkey, hotkeyParent.get_canvas_item())
	connect("toggled", queue_redraw.unbind(1))
	add_to_group(&"hotkeyButton")

func _process(_delta) -> void:
	queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawHotkey)
	if disabled or Game.editor.settingsOpen: return
	var strWidth:int = int(Game.ROBOTO_MONO.get_string_size(getCurrentHotkey(),HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
	var offset:Vector2 = global_position - hotkeyParent.global_position
	Game.ROBOTO_MONO.draw_string(drawHotkey, offset+Vector2((size.x-strWidth)/2,size.y+9),getCurrentHotkey(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(Color.WHITE,hotkeyOpacity))

func getCurrentHotkey() -> String:
	if button_pressed:
		if pressedHotkey:
			return Explainer.hotkeyMap(pressedHotkey, "")
		else: return ""
	if defaultHotkey: return Explainer.hotkeyMap(defaultHotkey, "")
	else: return ""
