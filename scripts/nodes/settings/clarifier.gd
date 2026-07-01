extends TextureRect
class_name Clarifier

func _init(text:String) -> void:
	texture = preload("res://assets/ui/settings/clarifier.png")
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tooltip_text = text
