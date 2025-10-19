extends HBoxContainer
class_name OtherObjects

@onready var editor:Editor = get_node("/root/editor")

var objects:Array[Variant] = [Goal, PlayerSpawn]
var firstResult:Variant

func _searchFocused() -> void:
	_updateSearch()

func _searchDefocused() -> void:
	%objectSearch.text = ""
	for result in %results.get_children():
		result.queue_free()

func _updateSearch() -> void:
	for result in %results.get_children():
		result.queue_free()
	
	firstResult = null

	var search:String = %objectSearch.text.to_lower()
	var resultCount:int = 0
	for object in objects:
		if search == "" or matchesSearch(object, search):
			var result = preload("res://scenes/searchResult.tscn").instantiate()
			result.setResult(object)
			result.button.connect(&"pressed", objectSelected.bind(object))
			%results.add_child(result)
			if !firstResult: firstResult = object
			resultCount += 1
			if resultCount == 8: return # dont show too many

func matchesSearch(object:Variant, search:String) -> bool:
	if object.SEARCH_NAME.to_lower().find(search) != -1: return true
	for keyword in object.SEARCH_KEYWORDS:
		if keyword.find(search) != -1: return true
	return false

func objectSelected(object:Variant) -> void:
	%other.icon = object.SEARCH_ICON

func _searchSubmitted():
	if firstResult: objectSelected(firstResult)
	editor.grab_focus()
