extends Button
class_name HotkeyButton

const fTalk:FontVariation = preload("res://resources/fonts/fControls.tres")

@export var defaultHotkey:Key
@export var pressedHotkey:Key

func _ready() -> void:
	connect("toggled", queue_redraw.unbind(1))

func _draw() -> void:
	draw_string(fTalk,Vector2(0,size.y+12),getCurrentHotkey(),HORIZONTAL_ALIGNMENT_CENTER,size.x,12)

func getCurrentHotkey() -> String:
	if button_pressed:
		if pressedHotkey: return keyToString(pressedHotkey)
		else: return ""
	if defaultHotkey: return keyToString(defaultHotkey)
	else: return ""

func keyToString(key:Key) -> String:
	match key:
		KEY_CTRL: return "Ctrl"
		KEY_ESCAPE: return "Esc"
		_: return OS.get_keycode_string(key)
