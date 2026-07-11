extends HBoxContainer
class_name OtherObjects

@onready var objectSearch:LineEdit = %objectSearch

var selected:GDScript = PlayerSpawn
var objects:Array[GDScript] = [Goal, KeyCounter, PlayerSpawn, FloatingTile, RemoteLock]
var firstResult:GDScript

func _ready() -> void:
	await item_rect_changed
	%results.size.x = size.x
	%results.position = position + %clip.position + Vector2(0, size.y)

func _searchFocused() -> void:
	Game.editor.focusDialog.defocus()
	Game.editor.modes.setView(Editor.VIEW.NORMAL)
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
		if !Mods.objectAvailable(object): continue
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
		if keyword.to_lower().find(search) != -1: return true
	return false

func objectSelected(object:GDScript, quiet:bool=false) -> void:
	%other.icon = object.SEARCH_ICON
	selected = object
	if !quiet: Game.editor.modes.setMode(Editor.MODE.OTHER)

func _searchSubmitted() -> void:
	if firstResult: objectSelected(firstResult)
	Game.editor.grab_focus()

func clearResults() -> void:
	for result in %results.get_children():
		result.queue_free()
