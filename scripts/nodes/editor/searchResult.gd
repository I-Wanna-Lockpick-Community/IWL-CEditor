extends PanelContainer
class_name SearchResult

var button:Button

func setResult(object:GDScript) -> void:
	%icon.texture = object.SEARCH_ICON
	%name.text = object.SEARCH_NAME
	%keywords.text = ", ".join(object.SEARCH_KEYWORDS)
	button = %button
