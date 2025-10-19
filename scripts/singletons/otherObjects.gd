extends HBoxContainer
class_name OtherObjects

@onready var editor:Editor = get_node("/root/editor")
@onready var objectSearch:LineEdit = %objectSearch

var selected:GDScript = PlayerSpawn
var objects:Array[GDScript] = [Goal, PlayerSpawn]
var firstResult:GDScript

func _searchFocused() -> void:
	await get_tree().process_frame
	objectSearch.text = ""
	_updateSearch()

func _searchDefocused() -> void:
	objectSearch.text = ""
	clearResults()

func _updateSearch() -> void:
	clearResults()
	firstResult = null

	var search:String = objectSearch.text.to_lower()
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

func matchesSearch(object:GDScript, search:String) -> bool:
	if object.SEARCH_NAME.to_lower().find(search) != -1: return true
	for keyword in object.SEARCH_KEYWORDS:
		if keyword.find(search) != -1: return true
	return false

func objectSelected(object:GDScript) -> void:
	%other.icon = object.SEARCH_ICON
	selected = object
	editor.modes.setMode(Editor.MODE.OTHER)

func _searchSubmitted():
	if firstResult: objectSelected(firstResult)
	editor.grab_focus()

func clearResults():
	for result in %results.get_children():
		result.queue_free()
