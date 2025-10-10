extends Button
class_name HotkeyButton

const fTalk:FontVariation = preload("res://resources/ui/fonts/fTalkSmall.tres")

@export var hotkey:Key

func _draw():
	draw_string(fTalk,Vector2(0,size.y+12),OS.get_keycode_string(hotkey).left(3),HORIZONTAL_ALIGNMENT_CENTER,size.x,12)
