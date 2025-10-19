extends Button
class_name HotkeyButton

const fTalk:FontVariation = preload("res://resources/fonts/fControls.tres")

@export var defaultHotkey:String
@export var pressedHotkey:String

func _ready() -> void:
	connect("toggled", queue_redraw.unbind(1))

func _draw() -> void:
	if disabled: return
	var strWidth:int = int(fTalk.get_string_size(getCurrentHotkey(),HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
	draw_string(fTalk,Vector2((size.x-strWidth)/2,size.y+12),getCurrentHotkey(),HORIZONTAL_ALIGNMENT_LEFT,-1,12)

func getCurrentHotkey() -> String:
	if button_pressed:
		if pressedHotkey: return pressedHotkey
		else: return ""
	if defaultHotkey: return defaultHotkey
	else: return ""
