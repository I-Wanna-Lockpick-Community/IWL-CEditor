extends PanelContainer
class_name SearchResult

var button:Button

func setResult(object:Variant) -> void:
	%icon.texture = object.SEARCH_ICON
	%name.text = object.SEARCH_NAME
	%keywords.text = "Keywords: " + ", ".join(object.SEARCH_KEYWORDS)
	button = %button
