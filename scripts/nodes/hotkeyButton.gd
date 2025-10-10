extends Button
class_name HotkeyButton

const fTalk:FontVariation = preload("res://resources/ui/fonts/fTalkSmall.tres")

@export var defaultHotkey:Key
@export var pressedHotkey:Key

func _ready() -> void:
	connect("toggled", queue_redraw.unbind(1))

func _draw() -> void:
	draw_string(fTalk,Vector2(0,size.y+12),OS.get_keycode_string(getCurrentHotkey()).left(3),HORIZONTAL_ALIGNMENT_CENTER,size.x,12)

func getCurrentHotkey() -> Key:
	if button_pressed and pressedHotkey: return pressedHotkey
	return defaultHotkey
