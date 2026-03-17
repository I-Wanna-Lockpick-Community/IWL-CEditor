extends Resource
class_name ControlExplanation

## "%s"s are replaced with hotkeys
@export_multiline var explanation:String
@export var hotkeys:Array[StringName]

func _init(_explanation:String="", _hotkeys:Array[StringName]=[]) -> void:
	explanation = _explanation
	hotkeys = _hotkeys

func _to_string() -> String:
	return explanation % hotkeys.map(Explainer.hotkeyMap)
